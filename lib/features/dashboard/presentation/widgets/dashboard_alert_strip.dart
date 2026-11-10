import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/domain/conversation_filters.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/dashboard_snapshot.dart';
import '../dashboard_links.dart';

/// One alert, highest priority first (spec §4.3).
class DashboardAlertStrip extends ConsumerWidget {
  const DashboardAlertStrip({super.key, required this.alert, required this.scope});

  final DashboardAlert alert;
  final DashboardScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final urgent = alert.kind == DashboardAlertKind.whatsappDisconnected || alert.kind == DashboardAlertKind.slaBreach;
    final n = '${alert.count}';

    final (icon, title, body, action, primary) = switch (alert.kind) {
      DashboardAlertKind.whatsappDisconnected => (AppIcons.wifiOff, l.dash_alert_wa_title, l.dash_alert_wa_body, l.dash_alert_wa_action, true),
      DashboardAlertKind.slaBreach => (AppIcons.clock, l.dash_alert_sla_title(n, '${alert.slaMinutes}'), null, l.dash_alert_sla_action, true),
      DashboardAlertKind.unassignedBacklog => (AppIcons.inbox, l.dash_alert_unassigned_title(n), null, l.dash_alert_view, false),
      DashboardAlertKind.kbUnanswered => (AppIcons.lightbulb, l.dash_alert_kb_title(n), l.dash_alert_kb_body, l.dash_alert_kb_action, false),
      DashboardAlertKind.trialEnding => (AppIcons.hourglass, l.dash_alert_trial_title('${alert.daysLeft}'), null, l.dash_alert_trial_action, false),
    };
    final bg = urgent ? c.errorContainer : (alert.kind == DashboardAlertKind.kbUnanswered && !c.isDark ? const Color(0xFFFFFBEB) : c.warningContainer);
    final fg = urgent ? c.textError : c.textWarning;

    void go() {
      Analytics.log('dash_alert_tap', {'kind': alert.kind.wire});
      switch (alert.kind) {
        case DashboardAlertKind.whatsappDisconnected:
          context.push(Routes.whatsapp);
        case DashboardAlertKind.slaBreach:
          DashboardLinks.inbox(
            context,
            ref,
            segment: scope == DashboardScope.me ? InboxSegment.mine : InboxSegment.unassigned,
            chip: QuickChip.awaiting,
          );
        case DashboardAlertKind.unassignedBacklog:
          DashboardLinks.inbox(context, ref, segment: InboxSegment.unassigned);
        case DashboardAlertKind.kbUnanswered:
          context.go(Routes.knowledge);
        case DashboardAlertKind.trialEnding:
          context.push(Routes.subscription);
      }
    }

    return Semantics(
      container: true,
      liveRegion: urgent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary)),
                  if (body != null) Text(body, style: t.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(
              label: action,
              size: AppButtonSize.small,
              variant: primary ? AppButtonVariant.primary : AppButtonVariant.secondary,
              onPressed: go,
            ),
            if (alert.dismissible)
              IconButton(
                tooltip: l.dash_alert_dismiss,
                visualDensity: VisualDensity.compact,
                icon: Icon(AppIcons.close, size: 18, color: c.textSecondary),
                onPressed: () => ref.read(dashboardControllerProvider.notifier).dismissAlert(alert),
              ),
          ],
        ),
      ),
    );
  }
}
