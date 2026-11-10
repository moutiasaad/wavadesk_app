import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// The six inbox empty states (Inbox spec §4.10).
enum InboxEmptyKind { mineNone, mineDone, unassigned, newWorkspace, noMatch, error }

class ConversationsEmptyState extends StatelessWidget {
  const ConversationsEmptyState({super.key, required this.kind, required this.onAction});

  final InboxEmptyKind kind;

  /// Switch segment / connect WhatsApp / clear filters / retry.
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (kind) {
      InboxEmptyKind.mineNone => EmptyState(
        icon: AppIcons.resolve,
        title: l.inbox_empty_mine_title,
        body: l.inbox_empty_mine_body,
        actionLabel: l.inbox_empty_mine_action,
        onAction: onAction,
      ),
      InboxEmptyKind.mineDone => EmptyState(
        icon: AppIcons.ai,
        title: l.inbox_empty_done_title,
        body: l.inbox_empty_done_body,
      ),
      InboxEmptyKind.unassigned => EmptyState(
        icon: AppIcons.inbox,
        title: l.inbox_empty_unassigned_title,
        body: l.inbox_empty_unassigned_body,
      ),
      InboxEmptyKind.newWorkspace => EmptyState(
        icon: AppIcons.whatsapp,
        title: l.inbox_empty_new_title,
        body: l.inbox_empty_new_body,
        actionLabel: l.inbox_empty_new_action,
        actionVariant: AppButtonVariant.primary,
        onAction: onAction,
      ),
      InboxEmptyKind.noMatch => EmptyState(
        icon: AppIcons.filterX,
        title: l.inbox_empty_filters_title,
        actionLabel: l.inbox_empty_filters_action,
        onAction: onAction,
      ),
      InboxEmptyKind.error => EmptyState(
        icon: AppIcons.offline,
        title: l.inbox_empty_error_title,
        body: l.inbox_empty_error_body,
        actionLabel: l.common_retry,
        actionVariant: AppButtonVariant.primary,
        onAction: onAction,
      ),
    };
  }
}
