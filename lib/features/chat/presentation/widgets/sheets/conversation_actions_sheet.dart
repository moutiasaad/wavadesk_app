import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/data/data.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/chat_controller.dart';
import '../../../domain/conversation_detail.dart';
import '../../../domain/system_event_formatter.dart';
import '../../../domain/assignee.dart';
import '../../sheets/assign/assign_sheet.dart';
import 'snooze_picker_sheet.dart';

/// Conversation actions (⋮) — Chat spec §6. Resolve is pinned first; the
/// caller pops the chat and shows the Undo snackbar via [onResolved].
Future<void> showConversationActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String conversationId,
  required void Function(Future<void> Function() undo) onResolved,
  VoidCallback? onOpenAssign,

  /// Shown when notes are allowed but the composer isn't (claim / colleague /
  /// AI states): "إضافة ملاحظة داخلية" (Claim spec §5.3).
  VoidCallback? onAddNote,

  /// "بحث في المحادثة" (Search spec §11).
  VoidCallback? onSearch,
}) async {
  final detail = ref.read(chatDetailProvider(conversationId));
  if (detail == null) return;
  final l = context.l10n;
  final c = context.colors;
  final actions = ref.read(chatActionsProvider(conversationId));
  final canResolve = detail.isOpen && detail.permissions.canResolve;
  final aiPaused = detail.conversation.aiPaused;

  final picked = await AppBottomSheet.show<_Action>(
    context,
    showClose: false,
    builder: (ctx) => Column(
      children: [
        if (canResolve) _ResolveRow(onTap: () => Navigator.pop(ctx, _Action.resolve)),
        SheetActionRow(
          icon: AppIcons.assign,
          label: detail.assignee == null ? l.actions_assign : l.actions_change_owner,
          onTap: () => Navigator.pop(ctx, _Action.assign),
        ),
        if (detail.isMine)
          SheetActionRow(
            icon: AppIcons.unassign,
            label: l.actions_unassign,
            onTap: () => Navigator.pop(ctx, _Action.unassign),
          ),
        if (detail.isOpen)
          SheetActionRow(
            icon: AppIcons.snooze,
            label: l.actions_snooze,
            onTap: () => Navigator.pop(ctx, _Action.snooze),
          ),
        SheetActionRow(
          icon: AppIcons.priority,
          label: l.actions_priority,
          trailing: Text(
            detail.conversation.priority.label(l),
            style: ctx.text.bodySmall.copyWith(color: c.textSecondary),
          ),
          onTap: () => Navigator.pop(ctx, _Action.priority),
        ),
        SheetActionRow(icon: AppIcons.tag, label: l.actions_tag, onTap: () => Navigator.pop(ctx, _Action.tag)),
        if (onSearch != null)
          SheetActionRow(
            icon: AppIcons.search,
            label: l.search_in_conv_action,
            onTap: () => Navigator.pop(ctx, _Action.search),
          ),
        if (onAddNote != null)
          SheetActionRow(icon: AppIcons.note, label: l.actions_add_note, onTap: () => Navigator.pop(ctx, _Action.note)),
        if (detail.aiEnabledInWorkspace)
          SheetActionRow(
            icon: aiPaused ? AppIcons.aiAgent : AppIcons.aiOff,
            label: aiPaused ? l.actions_ai_resume : l.actions_ai_pause,
            onTap: () => Navigator.pop(ctx, _Action.toggleAi),
          ),
        SheetActionRow(
          icon: AppIcons.email,
          label: l.actions_mark_unread,
          onTap: () => Navigator.pop(ctx, _Action.unread),
        ),
        if (detail.permissions.isAdmin)
          SheetActionRow(
            icon: AppIcons.export,
            label: l.actions_export,
            onTap: () => Navigator.pop(ctx, _Action.export),
          ),
        SheetActionRow(
          icon: detail.blocked ? AppIcons.unblock : AppIcons.block,
          label: detail.blocked ? l.actions_unblock : l.actions_block,
          destructive: !detail.blocked,
          onTap: () => Navigator.pop(ctx, _Action.block),
        ),
      ],
    ),
  );
  if (picked == null || !context.mounted) return;

  switch (picked) {
    case _Action.resolve:
      HapticFeedback.lightImpact();
      onResolved(actions.resolve());
    case _Action.assign:
      if (onOpenAssign != null) {
        onOpenAssign();
      } else {
        await showAssignSheet(context, ref, conversationIds: [conversationId], source: AssignSource.menu);
      }
    case _Action.unassign:
      actions.unassign();
      AppSnackbar.show(context, message: l.actions_unassigned_toast, kind: SnackKind.success);
    case _Action.snooze:
      final until = await showSnoozePicker(context);
      if (until == null || !context.mounted) return;
      final undo = actions.snooze(until);
      AppSnackbar.undo(context, message: l.actions_snoozed_toast, onUndo: undo);
    case _Action.priority:
      await showPriorityPicker(context, ref, conversationId: conversationId);
    case _Action.tag:
      await showTagSheet(context, ref, conversationId: conversationId);
    case _Action.note:
      onAddNote?.call();
    case _Action.search:
      onSearch?.call();
    case _Action.toggleAi:
      actions.setAiPaused(!aiPaused);
      AppSnackbar.show(
        context,
        message: aiPaused ? l.actions_ai_resumed_toast : l.actions_ai_paused_toast,
        kind: SnackKind.success,
      );
    case _Action.unread:
      actions.markUnread();
      Navigator.of(context).maybePop();
    case _Action.export:
      await _export(context, ref, detail);
    case _Action.block:
      if (detail.blocked) {
        actions.setBlocked(false);
        AppSnackbar.show(context, message: l.actions_unblocked_toast, kind: SnackKind.success);
      } else {
        await confirmBlockCustomer(context, ref, conversationId);
      }
  }
}

enum _Action { note, resolve, assign, unassign, snooze, priority, tag, search, toggleAi, unread, export, block }

/// Pinned first row in `textSuccess` with a check icon (§6).
class _ResolveRow extends StatelessWidget {
  const _ResolveRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            children: [
              AppIcon(AppIcons.resolve, color: c.textSuccess),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.l10n.chat_resolve,
                  style: context.text.bodyLarge.copyWith(color: c.textSuccess, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destructive confirm → block (§6, §5 quick action).
Future<void> confirmBlockCustomer(BuildContext context, WidgetRef ref, String conversationId) async {
  final l = context.l10n;
  final name = ref.read(conversationProvider(conversationId))?.customer.name ?? '';
  final ok = await AppDialog.confirm(
    context,
    title: l.actions_block_title(name),
    body: l.actions_block_body,
    confirmLabel: l.actions_block,
    icon: AppIcons.block,
  );
  if (!ok || !context.mounted) return;
  ref.read(chatActionsProvider(conversationId)).setBlocked(true);
  AppSnackbar.show(context, message: l.actions_blocked_toast, kind: SnackKind.success);
}

Future<void> _export(BuildContext context, WidgetRef ref, ConversationDetail detail) async {
  final l = context.l10n;
  final meId = detail.meId;
  String describe(Message m) {
    if (m.systemEvent != null) {
      return SystemEventFormatter.format(
        m.systemEvent!,
        l: l,
        meId: meId,
        formatTime: (t) => AppFormat.date(context, t),
        priorityLabel: (p) => Priority.values.where((x) => x.name == p).firstOrNull?.label(l) ?? p,
        channelLabel: (ch) => Channel.values.where((x) => x.name == ch).firstOrNull?.label(l) ?? ch,
      );
    }
    final who = switch (m.type) {
      MessageBubbleType.incoming => detail.contact.name,
      MessageBubbleType.outgoingAi => l.chat_ai_handling,
      MessageBubbleType.internalNote => '${l.actions_export_note} · ${m.senderName ?? ''}',
      _ => m.senderName ?? l.common_you,
    };
    final body = m.text.isNotEmpty ? m.text : m.kind.label(l);
    return '$who: $body';
  }

  final text = ref.read(chatActionsProvider(detail.id)).exportText(describe: describe);
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) AppSnackbar.show(context, message: l.actions_exported_toast, kind: SnackKind.success);
}

/// Priority chips picker.
Future<void> showPriorityPicker(BuildContext context, WidgetRef ref, {required String conversationId}) async {
  final l = context.l10n;
  final current = ref.read(conversationProvider(conversationId))?.priority;
  final picked = await AppBottomSheet.show<Priority>(
    context,
    title: l.actions_priority,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final p in Priority.values)
            AppFilterChip(
              label: p.label(ctx.l10n),
              selected: p == current,
              leading: PriorityIndicator(priority: p),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  ref.read(chatActionsProvider(conversationId)).setPriority(picked);
}

/// Tags: multi-select chips + a field to add a new tag.
Future<void> showTagSheet(BuildContext context, WidgetRef ref, {required String conversationId}) {
  final l = context.l10n;
  return AppBottomSheet.show<void>(
    context,
    title: l.actions_tag,
    subtitle: l.actions_tag_subtitle,
    builder: (ctx) => _TagEditor(conversationId: conversationId),
  );
}

class _TagEditor extends ConsumerStatefulWidget {
  const _TagEditor({required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<_TagEditor> {
  final _field = TextEditingController();
  final Set<String> _extra = {};

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _add() {
    final tag = _field.text.trim();
    if (tag.isEmpty) return;
    final current = ref.read(conversationProvider(widget.conversationId))?.tags ?? const [];
    if (!current.contains(tag)) ref.read(chatActionsProvider(widget.conversationId)).toggleTag(tag);
    setState(() => _extra.add(tag));
    _field.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final conv = ref.watch(conversationProvider(widget.conversationId));
    final applied = conv?.tags ?? const <String>[];
    final all = {...ref.watch(allTagsProvider), ..._extra, ...applied}.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in all)
                AppFilterChip(
                  label: tag,
                  selected: applied.contains(tag),
                  onTap: () => ref.read(chatActionsProvider(widget.conversationId)).toggleTag(tag),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _field,
            hint: l.actions_tag_new_hint,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            suffix: AppIconButton(icon: AppIcons.add, semanticLabel: l.actions_tag_add, onPressed: _add),
          ),
        ],
      ),
    );
  }
}
