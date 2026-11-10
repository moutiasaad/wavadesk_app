import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/notification_type.dart';

enum NotificationsEmptyKind { all, filter, error }

/// Empty / error states (Notifications spec §7).
class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({
    super.key,
    required this.kind,
    required this.filter,
    required this.onShowAll,
    required this.onRetry,
  });

  final NotificationsEmptyKind kind;
  final NotificationFilter filter;
  final VoidCallback onShowAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return switch (kind) {
      NotificationsEmptyKind.all => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
              child: Icon(AppIcons.notifications, size: 32, color: c.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l.ntf_empty_title, style: context.text.h5, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Text(
                l.ntf_empty_body,
                style: context.text.bodyMedium.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      NotificationsEmptyKind.filter => EmptyState(
          icon: AppIcons.notificationsOff,
          title: l.ntf_empty_filter(filter.label(l)),
          actionLabel: l.ntf_show_all,
          actionVariant: AppButtonVariant.text,
          onAction: onShowAll,
        ),
      NotificationsEmptyKind.error => EmptyState(
          icon: AppIcons.alert,
          title: l.ntf_error,
          actionLabel: l.ntf_retry,
          onAction: onRetry,
        ),
    };
  }
}
