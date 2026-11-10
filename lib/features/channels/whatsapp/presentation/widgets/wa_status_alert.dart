import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/analytics.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_channel.dart';
import '../../domain/wa_status.dart';
import '../sheets/wa_quality_sheet.dart';

/// **أبلغ المسؤول** (agents, §7): notifies the workspace admins.
Future<void> waNotifyAdmin(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  Analytics.log('wa_notify_admin');
  try {
    await ref.read(whatsAppChannelControllerProvider.notifier).notifyAdmin();
    if (context.mounted) AppSnackbar.show(context, message: l.wa_notify_sent, kind: SnackKind.success);
  } catch (_) {
    if (context.mounted) AppSnackbar.show(context, message: l.wa_save_failed, kind: SnackKind.error);
  }
}

/// One alert card under the connection card (WhatsApp spec §4.3).
class WaStatusAlert extends ConsumerWidget {
  const WaStatusAlert({super.key, required this.kind, required this.channel});

  final WaAlertKind kind;
  final WaChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final admin = channel.permissions.isAdmin;
    final refreshing = ref.watch(whatsAppChannelControllerProvider.select((s) => s.refreshing));

    void reconnect() => context.push(Routes.whatsappConnect(source: 'alert'));
    final notify = AppButton(
      label: l.wa_notify_admin,
      size: AppButtonSize.small,
      variant: AppButtonVariant.secondary,
      onPressed: () => waNotifyAdmin(context, ref),
    );

    final since = channel.statusSince == null ? null : DateTime.now().difference(channel.statusSince!);
    final (tone, icon, title, body, action) = switch (kind) {
      WaAlertKind.disconnected => (
          WaPillTone.error,
          AppIcons.disconnected,
          since == null ? l.wa_disconnected : l.wa_alert_disc_title(AppFormat.shortDuration(context, since)),
          l.wa_alert_disc_body,
          admin
              ? AppButton(label: l.wa_reconnect, size: AppButtonSize.small, onPressed: reconnect)
              : notify,
        ),
      WaAlertKind.phoneOffline => (
          WaPillTone.warning,
          AppIcons.device,
          l.wa_alert_phone_title,
          l.wa_alert_phone_body,
          admin
              ? AppButton(
                  label: l.wa_check_again,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.secondary,
                  loading: refreshing,
                  onPressed: refreshing ? null : ref.read(whatsAppChannelControllerProvider.notifier).refreshStatus,
                )
              : notify,
        ),
      WaAlertKind.qualityLow => (
          WaPillTone.warning,
          AppIcons.warning,
          l.wa_alert_quality,
          l.wa_alert_quality_body,
          AppButton(
            label: l.wa_details,
            size: AppButtonSize.small,
            variant: AppButtonVariant.secondary,
            onPressed: () => showWaQualitySheet(context, channel),
          ),
        ),
      WaAlertKind.limitNear => (
          WaPillTone.warning,
          AppIcons.stats,
          l.wa_alert_limit('${channel.quality.dailyUsed}', '${channel.quality.dailyLimit}'),
          null,
          null,
        ),
      WaAlertKind.appOutdated => (WaPillTone.warning, AppIcons.device, l.wa_alert_update, null, null),
      WaAlertKind.pending => (
          WaPillTone.info,
          AppIcons.whatsapp,
          l.wa_alert_pending,
          l.wa_alert_pending_body,
          admin ? AppButton(label: l.wa_connect, size: AppButtonSize.small, onPressed: reconnect) : notify,
        ),
    };
    final (bg, fg) = switch (tone) {
      WaPillTone.error => (c.errorContainer, c.textError),
      WaPillTone.warning => (c.warningContainer, c.textWarning),
      WaPillTone.info => (c.infoContainer, c.textInfo),
      _ => (c.surfaceVariant, c.textSecondary),
    };

    return Semantics(
      container: true,
      liveRegion: kind == WaAlertKind.disconnected,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 10, AppSpacing.lg, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.surface.withValues(alpha: 0.7), shape: BoxShape.circle),
              child: AppIcon(icon, dp: 18, color: fg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.listTitle.copyWith(fontSize: 14, color: c.textPrimary)),
                  if (body != null) Text(body, style: t.bodySmall.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: AppSpacing.sm), action],
          ],
        ),
      ),
    );
  }
}
