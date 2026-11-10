import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../application/whatsapp_channel_controller.dart';
import '../../domain/wa_status.dart';

/// Connection details (WhatsApp spec §6.1).
Future<void> showWaConnectionDetailsSheet(BuildContext context) => AppBottomSheet.show<void>(
      context,
      title: context.l10n.wa_details_title,
      builder: (_) => const _Details(),
    );

class _Details extends ConsumerWidget {
  const _Details();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final state = ref.watch(whatsAppChannelControllerProvider);
    final ch = state.channel;
    if (ch == null) return const SizedBox(height: 120, child: Center(child: AppSpinner()));

    Widget row(String label, String value, {bool ltr = false, Widget? trailing, Widget? below}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: t.bodyMedium.copyWith(color: c.textSecondary))),
                  Flexible(
                    child: Text(
                      value,
                      style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      textDirection: ltr ? TextDirection.ltr : null,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  ?trailing,
                ],
              ),
              ?below,
            ],
          ),
        );

    final device = ch.device;
    final deviceText = device == null
        ? l.wa_unknown
        : [
            if (device.model != null) device.model!,
            if (device.waApp != null) device.isBusiness ? l.wa_d_wa_business(_short(device.waVersion)) : l.wa_d_wa_personal(_short(device.waVersion)),
          ].join(' · ');
    final q = ch.quality;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(l.wa_d_type, ch.isCloud ? l.wa_d_type_cloud : l.wa_d_type_linked),
        if (!ch.isCloud) row(l.wa_d_device, deviceText),
        row(l.wa_d_last_activity, ch.lastActivityAt == null ? '—' : AppFormat.relative(context, ch.lastActivityAt!)),
        row(l.wa_d_sync, ch.status == WaStatus.syncing ? l.wa_syncing : (ch.status.isHealthy ? l.wa_d_synced : '—')),
        if (ch.isCloud && ch.phoneNumberId != null)
          row(
            l.wa_d_number_id,
            ch.phoneNumberId!,
            ltr: true,
            trailing: AppIconButton(
              icon: AppIcons.copy,
              size: 32,
              iconSize: 15,
              semanticLabel: l.wa_copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: ch.phoneNumberId!));
                AppSnackbar.show(context, message: l.wa_copied);
              },
            ),
          ),
        if (ch.isCloud && q.dailyLimit > 0)
          row(
            l.wa_d_daily_limit,
            '${q.messagingTier ?? ''}  ${l.wa_d_limit_value('${q.dailyUsed}', '${q.dailyLimit}')}'.trim(),
            below: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: q.limitUsage.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: c.surfaceVariant,
                  color: q.limitUsage >= 0.8 ? c.warning : c.primary,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          child: AppButton(
            label: l.wa_refresh,
            icon: AppIcons.regenerate,
            variant: AppButtonVariant.secondary,
            expand: true,
            loading: state.refreshing,
            onPressed: state.refreshing ? null : ref.read(whatsAppChannelControllerProvider.notifier).refreshStatus,
          ),
        ),
      ],
    );
  }

  /// "2.24.21" → "2.24".
  static String _short(String? v) {
    if (v == null) return '';
    final parts = v.split('.');
    return parts.length > 2 ? '${parts[0]}.${parts[1]}' : v;
  }
}
