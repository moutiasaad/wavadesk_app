import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/contact_notes_controller.dart';
import '../../application/customer_profile_controller.dart';
import '../../domain/contact_note.dart';

/// ملاحظة جديدة / تعديل (Profile spec §7.3). Keyboard-aware sheet with a
/// note-styled field, `@` mentions and "تثبيت الملاحظة".
Future<void> showAddNoteSheet(BuildContext context, WidgetRef ref, {required String contactId, ContactNote? editing}) {
  final l = context.l10n;
  return AppBottomSheet.show<void>(
    context,
    title: editing == null ? l.note_new : l.note_edit_title,
    builder: (ctx) => _NoteEditor(contactId: contactId, editing: editing),
  );
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({required this.contactId, this.editing});

  final String contactId;
  final ContactNote? editing;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final _text = TextEditingController(text: widget.editing?.text ?? '');
  final _focus = FocusNode();
  late bool _pinned = widget.editing?.pinned ?? false;
  bool _saving = false;

  /// Text after the last "@" while typing a mention, else null.
  String? _mentionQuery;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    final t = _text.text;
    final caret = _text.selection.baseOffset < 0 ? t.length : _text.selection.baseOffset;
    final before = t.substring(0, caret.clamp(0, t.length));
    final at = before.lastIndexOf('@');
    String? q;
    if (at >= 0 && (at == 0 || RegExp(r'\s').hasMatch(before[at - 1]))) {
      final frag = before.substring(at + 1);
      if (!frag.contains(RegExp(r'\s'))) q = frag;
    }
    setState(() => _mentionQuery = q);
  }

  void _insertMention(Agent a) {
    final first = a.name.split(' ').first;
    final t = _text.text;
    final caret = _text.selection.baseOffset < 0 ? t.length : _text.selection.baseOffset;
    final at = t.substring(0, caret).lastIndexOf('@');
    final next = '${t.substring(0, at)}@$first ${t.substring(caret)}';
    final pos = at + first.length + 2;
    _text.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: pos));
  }

  List<String> _mentions(List<Agent> colleagues) {
    final me = ref.read(currentAgentProvider);
    return [
      for (final a in [me, ...colleagues])
        if (_text.text.contains('@${a.name.split(' ').first}')) a.name.split(' ').first,
    ];
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final notes = ref.read(contactNotesProvider(widget.contactId));
    final l = context.l10n;
    try {
      final editing = widget.editing;
      if (editing == null) {
        await notes.add(text, mentions: _mentions(ref.read(colleaguesProvider)), pinned: _pinned);
      } else {
        if (text != editing.text) await notes.edit(editing.id, text);
        if (_pinned != editing.pinned) await notes.setPinned(editing.id, _pinned);
      }
      HapticFeedback.lightImpact();
      if (!mounted) return;
      Navigator.of(context).pop();
      AppSnackbar.show(context, message: editing == null ? l.note_saved : l.note_updated, kind: SnackKind.success);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(context, message: l.note_failed, kind: SnackKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final contact = ref.watch(customerProfileControllerProvider(widget.contactId)).contact;
    final canPin = contact?.permissions.canPinNotes ?? false;
    final colleagues = ref.watch(colleaguesProvider);
    final q = _mentionQuery?.toLowerCase();
    final matches = q == null ? const <Agent>[] : [for (final a in colleagues) if (a.name.toLowerCase().contains(q)) a];
    final length = _text.text.length;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mention panel above the field.
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            child: matches.isEmpty
                ? const SizedBox(width: double.infinity)
                : Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: c.border),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      children: [
                        for (final a in matches)
                          InkWell(
                            onTap: () => _insertMention(a),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  AppAvatar(
                                    name: a.name,
                                    id: a.id,
                                    presence: a.presence,
                                    size: AppAvatarSize.sm,
                                    ringColor: c.surface,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(a.name, style: t.listTitle.copyWith(fontSize: 14))),
                                  Text(a.presence.label(l), style: t.caption.copyWith(color: c.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          CustomPaint(
            painter: _DashedBorderPainter(color: c.noteBorder, radius: AppRadius.lg),
            child: Container(
              decoration: BoxDecoration(color: c.noteBackground, borderRadius: BorderRadius.circular(AppRadius.lg)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
              child: TextField(
                controller: _text,
                focusNode: _focus,
                minLines: 4,
                maxLines: 10,
                maxLength: ContactNotesActions.maxLength,
                style: t.bodyLarge.copyWith(color: c.noteForeground),
                cursorColor: c.primary,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  counterText: '',
                  hintText: l.note_placeholder,
                  hintStyle: t.bodyLarge.copyWith(color: c.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),
          if (length >= ContactNotesActions.counterFrom)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '$length / ${ContactNotesActions.maxLength}',
                  textAlign: TextAlign.end,
                  textDirection: TextDirection.ltr,
                  style: t.caption.copyWith(
                    color: length >= ContactNotesActions.maxLength ? c.textError : c.textSecondary,
                  ),
                ),
              ),
            ),
          if (canPin) ...[
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              checked: _pinned,
              label: l.note_pin,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                onTap: () => setState(() => _pinned = !_pinned),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      AppCheckbox(value: _pinned),
                      const SizedBox(width: 10),
                      Text(l.note_pin, style: t.bodyMedium),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l.note_save,
            size: AppButtonSize.large,
            expand: true,
            loading: _saving,
            onPressed: _text.text.trim().isEmpty ? null : _save,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: l.note_cancel,
            variant: AppButtonVariant.text,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// 1dp dashed rounded border (note style).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}
