import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/contact_notes_controller.dart';
import '../../domain/contact.dart';
import '../../domain/contact_note.dart';
import '../sheets/add_note_sheet.dart';
import 'profile_hero.dart';
import 'profile_note_card.dart';

/// Team notes (§5.5): pinned first, newest first; 2 shown then "عرض كل
/// الملاحظات ({n})" inline; long-press own (or admin any) → pin / edit /
/// delete. New notes slide in.
class ProfileNotesSection extends ConsumerStatefulWidget {
  const ProfileNotesSection({super.key, required this.contact, this.offline = false, this.hideWhenEmpty = false});

  final Contact contact;
  final bool offline;

  /// Over the chat (sheet): no empty placeholder (the ملاحظة action adds one).
  final bool hideWhenEmpty;

  @override
  ConsumerState<ProfileNotesSection> createState() => _ProfileNotesSectionState();
}

class _ProfileNotesSectionState extends ConsumerState<ProfileNotesSection> {
  bool _expanded = false;
  late Set<String> _known = {for (final n in widget.contact.notes) n.id};
  Set<String> _fresh = {};

  @override
  void didUpdateWidget(ProfileNotesSection old) {
    super.didUpdateWidget(old);
    final ids = {for (final n in widget.contact.notes) n.id};
    final added = ids.difference(_known);
    _known = ids;
    if (added.isNotEmpty && !AppMotion.reduced(context)) _fresh = added;
  }

  void _add() => showAddNoteSheet(context, ref, contactId: widget.contact.id);

  bool _canManage(ContactNote n) {
    final me = ref.read(currentAgentProvider);
    return n.authorId == me.id || me.isAdmin;
  }

  Map<String, VoidCallback> _actions(ContactNote n) {
    final l = context.l10n;
    final notes = ref.read(contactNotesProvider(widget.contact.id));
    if (widget.offline || !_canManage(n)) return const {};
    return {
      if (widget.contact.permissions.canPinNotes)
        n.pinned ? l.profile_unpin : l.profile_pin: () => notes.setPinned(n.id, !n.pinned),
      l.profile_edit: () => showAddNoteSheet(context, ref, contactId: widget.contact.id, editing: n),
      l.profile_delete: () => _delete(n),
    };
  }

  Future<void> _delete(ContactNote n) async {
    final l = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l.profile_delete_note_title,
      body: l.profile_delete_note_body,
      confirmLabel: l.profile_delete,
      icon: AppIcons.delete,
    );
    if (ok) await ref.read(contactNotesProvider(widget.contact.id)).delete(n.id);
  }

  void _menu(ContactNote n) {
    final actions = _actions(n);
    if (actions.isEmpty) return;
    HapticFeedback.mediumImpact();
    final l = context.l10n;
    AppBottomSheet.show<void>(
      context,
      showClose: false,
      builder: (ctx) => Column(
        children: [
          for (final e in actions.entries)
            SheetActionRow(
              icon: e.key == l.profile_delete
                  ? AppIcons.delete
                  : e.key == l.profile_edit
                  ? AppIcons.edit
                  : (n.pinned ? AppIcons.pinOff : AppIcons.pin),
              label: e.key,
              destructive: e.key == l.profile_delete,
              onTap: () {
                Navigator.pop(ctx);
                e.value();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final notes = ContactNote.sorted(widget.contact.notes);
    final shown = _expanded ? notes : notes.take(2).toList();
    if (notes.isEmpty && widget.hideWhenEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionTitle(
          title: l.profile_notes,
          actionLabel: '+ ${l.profile_add}',
          onAction: widget.offline ? null : _add,
        ),
        if (notes.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(l.profile_no_notes, style: t.bodySmall.copyWith(color: c.textTertiary)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: c.primary,
                  textStyle: t.buttonSmall,
                  minimumSize: const Size(48, 40),
                ),
                onPressed: widget.offline ? null : _add,
                child: Text(l.profile_first_note),
              ),
            ],
          )
        else
          AnimatedSize(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            alignment: AlignmentDirectional.topStart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final n in shown)
                  Padding(
                    key: ValueKey(n.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SlideIn(
                      animate: _fresh.contains(n.id),
                      child: ProfileNoteCard(
                        note: n,
                        onLongPress: () => _menu(n),
                        actions: {for (final e in _actions(n).entries) CustomSemanticsAction(label: e.key): e.value},
                      ),
                    ),
                  ),
                if (notes.length > 2 && !_expanded)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: c.primary,
                        textStyle: t.buttonSmall,
                        minimumSize: const Size(48, 40),
                      ),
                      onPressed: () => setState(() => _expanded = true),
                      child: Text(l.profile_all_notes(notes.length)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Slide down 8dp + fade, 200ms (§13 new note insert).
class _SlideIn extends StatefulWidget {
  const _SlideIn({required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    value: widget.animate ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final v = Curves.easeOutCubic.transform(_c.value);
      return Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, -8 * (1 - v)), child: child),
      );
    },
  );
}
