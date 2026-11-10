import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/contact_tags_controller.dart';
import '../../application/customer_profile_controller.dart';
import '../../domain/contact.dart';

/// الوسوم (Profile spec §7.2): search / create, selected tags with ✕,
/// suggestions as checkbox rows, batch apply on "تم".
Future<void> showTagEditorSheet(BuildContext context, WidgetRef ref, {required String contactId, String? conversationId}) {
  final before = ref.read(customerProfileControllerProvider(contactId)).contact?.tags ?? const <ContactTag>[];
  return AppBottomSheet.showExpanded<void>(
    context,
    title: context.l10n.tags_title,
    initialSize: 0.6,
    builder: (ctx, controller) => _TagEditor(
      contactId: contactId,
      conversationId: conversationId,
      before: before,
      controller: controller,
    ),
  );
}

class _TagEditor extends ConsumerStatefulWidget {
  const _TagEditor({required this.contactId, required this.conversationId, required this.before, required this.controller});

  final String contactId;
  final String? conversationId;
  final List<ContactTag> before;
  final ScrollController controller;

  @override
  ConsumerState<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<_TagEditor> {
  late final List<ContactTag> _selected = [...widget.before];
  List<ContactTag> _suggestions = const [];
  String _query = '';
  bool _saving = false;
  Timer? _debounce;

  ContactTagsActions get _actions => ref.read(contactTagsProvider(widget.contactId));

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final results = await _actions.search(q);
    if (mounted) setState(() => _suggestions = results);
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(q));
  }

  bool _isSelected(ContactTag t) => _selected.any((s) => s.name == t.name);

  void _toggle(ContactTag t) => setState(() {
        _isSelected(t) ? _selected.removeWhere((s) => s.name == t.name) : _selected.add(t);
      });

  void _create() {
    final name = _query.trim();
    if (name.isEmpty || _selected.any((s) => s.name == name)) return;
    setState(() => _selected.add(ContactTagsActions.create(name)));
  }

  Future<void> _done() async {
    setState(() => _saving = true);
    try {
      await _actions.apply(before: widget.before, after: _selected, conversationId: widget.conversationId);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(context, message: context.l10n.tags_failed, kind: SnackKind.error);
      }
    }
  }

  static Color? _hex(String? hex) {
    if (hex == null) return null;
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return v == null ? null : Color(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final q = _query.trim();
    final exact = q.isNotEmpty &&
        (_suggestions.any((s) => s.name.toLowerCase() == q.toLowerCase()) ||
            _selected.any((s) => s.name.toLowerCase() == q.toLowerCase()));

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: [
              AppSearchField(hint: l.tags_search, showCancel: false, onChanged: _onQuery, onSubmitted: (_) => _create()),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in _selected)
                      Semantics(
                        button: true,
                        label: '${l.tags_remove} ${tag.name}',
                        excludeSemantics: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          onTap: () => _toggle(tag),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 32),
                            padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: c.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: c.primaryContainerBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tag.name, style: t.chipLabel.copyWith(color: c.onPrimaryContainer)),
                                const SizedBox(width: AppSpacing.xs),
                                AppIcon(AppIcons.close, size: AppIconSize.sm, color: c.onPrimaryContainer),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (q.isNotEmpty && !exact)
                SheetActionRow(
                  icon: AppIcons.add,
                  label: l.tags_create(q),
                  onTap: _create,
                ),
              for (final tag in _suggestions)
                Semantics(
                  checked: _isSelected(tag),
                  label: tag.name,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => _toggle(tag),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          AppCheckbox(value: _isSelected(tag)),
                          const SizedBox(width: AppSpacing.md),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: _hex(tag.color) ?? c.borderStrong, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(tag.name, style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          // The sheet frame already adds the bottom safe area.
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          child: AppButton(
            label: l.tags_done,
            size: AppButtonSize.large,
            expand: true,
            loading: _saving,
            onPressed: _done,
          ),
        ),
      ],
    );
  }
}
