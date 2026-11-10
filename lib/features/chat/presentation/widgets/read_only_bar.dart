import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/conversation_detail.dart';
import '../../domain/ownership.dart';

/// Bottom slot when the agent can't reply (Chat spec §4.10): 56dp +
/// safe area, `surfaceVariant`, centered message + action. Colleague / AI
/// cases keep a note button so agents can still leave internal notes.
class ReadOnlyBar extends StatelessWidget {
  const ReadOnlyBar({
    super.key,
    required this.slot,
    required this.detail,
    this.onAction,
    this.onNote,
    this.onAdminTakeOver,
  });

  final BottomSlot slot;
  final ConversationDetail detail;
  final VoidCallback? onAction;
  final VoidCallback? onNote;
  final VoidCallback? onAdminTakeOver;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final name = detail.assignee?.name ?? '';

    final (String text, String? actionLabel, bool primary) = switch (slot) {
      BottomSlot.readOnlyColleague => (l.chat_ro_colleague(name), l.chat_ro_request, false),
      BottomSlot.readOnlyResolved => (l.chat_ro_resolved, l.chat_reopen, true),
      BottomSlot.readOnlyAi => (l.chat_ro_ai, l.chat_take_over, true),
      BottomSlot.readOnlyBlocked => (l.chat_ro_blocked, l.chat_unblock, false),
      BottomSlot.readOnlyTeam => (l.claim_team_only(detail.permissions.claimTeamName ?? ''), null, false),
      BottomSlot.readOnlyPast || BottomSlot.claim || BottomSlot.composer => (l.chat_ro_past, null, false),
    };

    Widget? action;
    if (actionLabel != null && onAction != null) {
      action = primary
          ? AppButton(label: actionLabel, size: AppButtonSize.small, onPressed: onAction)
          : TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                textStyle: t.buttonSmall,
                minimumSize: const Size(48, 40),
              ),
              onPressed: onAction,
              child: Text(actionLabel),
            );
    }

    final adminTakeOver = slot == BottomSlot.readOnlyColleague && detail.permissions.isAdmin && onAdminTakeOver != null
        ? TextButton(
            style: TextButton.styleFrom(
              foregroundColor: c.textSecondary,
              textStyle: t.buttonSmall,
              minimumSize: const Size(48, 40),
            ),
            onPressed: onAdminTakeOver,
            child: Text(l.readonly_take_instead),
          )
        : null;

    return Container(
      color: c.surfaceVariant,
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: [
              if (slot.allowsNotes && onNote != null)
                AppIconButton(icon: AppIcons.note, semanticLabel: l.readonly_add_note, onPressed: onNote)
              else
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      text,
                      style: t.bodySmall.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    ?action,
                    ?adminTakeOver,
                  ],
                ),
              ),
              // Balances the note button so the content stays centred.
              SizedBox(width: slot.allowsNotes && onNote != null ? AppSpacing.minTouch : AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
