import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import 'inbox_palette.dart';

/// Inbox v2 §7 empty / error states.
enum InboxEmptyKind { none, mine, unread, unassigned, waiting, ai, closed, filtered, error }

/// Centered in the list area: 72 circle tile with a 32 icon, title 16/800,
/// body 13.5 grey, optional button.
class ConversationsEmptyState extends StatelessWidget {
  const ConversationsEmptyState({super.key, required this.kind, required this.onAction, this.canConnect = false});

  final InboxEmptyKind kind;

  /// Connect WhatsApp / show unassigned / clear filters / retry.
  final VoidCallback onAction;

  /// "اربط واتساب" only when WhatsApp isn't connected (new workspace).
  final bool canConnect;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.text;
    final c = context.colors;
    final p = InboxPalette.of(context);
    final (IconData icon, String title, String? body, String? action) = switch (kind) {
      InboxEmptyKind.none => (AppIcons.conversation, l.inbox_e_none_title, l.inbox_e_none_body, canConnect ? l.inbox_e_connect : null),
      InboxEmptyKind.mine => (AppIcons.check, l.inbox_e_mine_title, l.inbox_e_mine_body, l.inbox_e_mine_action),
      InboxEmptyKind.unread => (AppIcons.read, l.inbox_e_unread, null, null),
      InboxEmptyKind.unassigned => (AppIcons.team, l.inbox_e_unassigned, null, null),
      InboxEmptyKind.waiting => (AppIcons.clock, l.inbox_e_waiting, null, null),
      InboxEmptyKind.ai => (AppIcons.ai, l.inbox_e_ai, null, null),
      InboxEmptyKind.closed => (AppIcons.check, l.inbox_e_closed, null, null),
      InboxEmptyKind.filtered => (AppIcons.filter, l.inbox_e_filtered_title, l.inbox_e_filtered_body, l.inbox_e_filtered_action),
      InboxEmptyKind.error => (AppIcons.warning, l.inbox_e_load, null, l.inbox_e_retry),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: p.emptyTile, shape: BoxShape.circle),
              child: AppIcon(icon, dp: 32, color: InboxPalette.emptyIcon),
            ),
            const SizedBox(height: 14),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: t.h5.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(body, textAlign: TextAlign.center, style: t.bodySmall.copyWith(fontSize: 13.5, color: p.preview)),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: action,
                variant: kind == InboxEmptyKind.error || kind == InboxEmptyKind.none
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
