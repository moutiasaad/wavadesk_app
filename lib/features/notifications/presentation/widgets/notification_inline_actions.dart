import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/data/data.dart';
import '../../../../core/notifications/push_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/notifications_controller.dart';
import '../../domain/notification.dart';
import '../../domain/notification_type.dart';

/// Up to two small buttons under the subtitle (Notifications spec §4.6, §5).
class NotificationInlineActions extends StatelessWidget {
  const NotificationInlineActions({
    super.key,
    required this.item,
    required this.ui,
    required this.onAction,
    this.enabled = true,
  });

  final NotificationItem item;
  final NotificationRowUi? ui;
  final ValueChanged<String> onAction;

  /// False while offline for actions that need the network (§7).
  final bool enabled;

  static List<NotificationAction> visible(NotificationItem n, NotificationRowUi? ui) {
    if (ui?.resolution != null || ui?.stale == true) return const [];
    final source = n.actions.isEmpty ? NotificationTemplates.defaultActions(n.type) : n.actions;
    return source.where((a) => a.state == NotificationActionState.available).take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final actions = visible(item, ui);
    if (actions.isEmpty) return const SizedBox.shrink();
    final busy = ui?.busyAction;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final a in actions)
            AppButton(
              label: NotificationTemplates.actionLabel(l, a),
              size: AppButtonSize.small,
              height: 34,
              textStyle: context.text.buttonSmall.copyWith(fontSize: 12.5),
              variant: a.style == NotificationActionStyle.primary ? AppButtonVariant.primary : AppButtonVariant.secondary,
              loading: busy == a.id,
              onPressed: busy != null || !enabled ? null : () => onAction(a.id),
            ),
        ],
      ),
    );
  }
}

/// Opens the tap target of a notification (§5) from the list. Marking read is
/// done by the caller.
abstract final class NotificationOpener {
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    NotificationItem n, {
    required String source,
    String? actionId,
  }) async {
    Analytics.log('ntf_open', {
      'type': n.rawType,
      'age_seconds': DateTime.now().difference(n.createdAt).inSeconds,
      'source': source,
    });
    final dest = PushRouter.forNotification(n, actionId: actionId);
    if (dest == null) return;
    if (dest.route != null) {
      // Tab roots switch tabs; everything else stacks on top.
      if (isTabRoute(dest.route!)) {
        context.go(dest.route!);
      } else {
        await context.push(dest.route!);
      }
      return;
    }
    if (dest.billing && !ref.read(currentAgentProvider).isAdmin) {
      await _billingInfo(context);
      return;
    }
    if (dest.external != null) await launchUrl(dest.external!, mode: LaunchMode.externalApplication);
  }

  /// Agents can't manage billing: explain who can (§5 trial_ending).
  static Future<void> _billingInfo(BuildContext context) {
    final l = context.l10n;
    return AppBottomSheet.show<void>(
      context,
      title: l.ntf_billing_agent_title,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Text(l.ntf_billing_agent_body, style: ctx.text.bodyMedium.copyWith(color: ctx.colors.textSecondary)),
      ),
    );
  }
}

/// `/conversations`, `/dashboard`, `/knowledge`, `/account` (shell tabs).
bool isTabRoute(String route) {
  final path = Uri.parse(route).path;
  return path == Routes.conversations || path == Routes.dashboard || path == Routes.knowledge || path == Routes.account;
}

/// Snackbar + navigation for an inline-action outcome (§6).
Future<void> handleNotificationAction(
  BuildContext context,
  WidgetRef ref,
  NotificationItem n,
  String actionId, {
  required bool online,
}) async {
  final l = context.l10n;
  final ctrl = ref.read(notificationsControllerProvider.notifier);
  final outcome = await ctrl.runAction(n, actionId, online: online);
  if (!context.mounted) return;
  switch (outcome) {
    case NotificationActionOutcome.navigate:
      await NotificationOpener.open(context, ref, n, source: 'list', actionId: actionId);
    case NotificationActionOutcome.claimedYou:
      final conv = n.conversationId;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (context.mounted && conv != null) await context.push(Routes.chat(conv));
    case NotificationActionOutcome.claimedBy:
      final name = ref.read(notificationsControllerProvider).rows[n.id]?.claimedBy ?? '';
      AppSnackbar.show(context, message: l.claim_conflict(name), kind: SnackKind.error);
    case NotificationActionOutcome.stale:
      AppSnackbar.show(context, message: l.ntf_target_gone, kind: SnackKind.error);
    case NotificationActionOutcome.offline:
      AppSnackbar.show(context, message: l.ntf_offline_action, kind: SnackKind.error);
    case NotificationActionOutcome.failed:
      AppSnackbar.show(context, message: l.ntf_action_failed, kind: SnackKind.error);
    case NotificationActionOutcome.approved:
    case NotificationActionOutcome.rejected:
      break;
  }
}
