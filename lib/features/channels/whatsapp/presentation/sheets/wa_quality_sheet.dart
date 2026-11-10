import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/wa_channel.dart';
import '../wa_links.dart';
import '../widgets/wa_connection_card.dart' show waQualityColor, waQualityLabel;

/// Quality sheet (cloud_api, WhatsApp spec §6.3).
Future<void> showWaQualitySheet(BuildContext context, WaChannel channel) => AppBottomSheet.show<void>(
      context,
      title: context.l10n.wa_quality,
      builder: (_) => _Quality(channel: channel),
    );

class _Quality extends StatelessWidget {
  const _Quality({required this.channel});

  final WaChannel channel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final q = channel.quality;
    final color = waQualityColor(context, q.rating);

    Color barColor(WaQualityRating r) => switch (r) {
          WaQualityRating.high => c.success,
          WaQualityRating.medium => c.warning,
          WaQualityRating.low => c.error,
        };
    double barHeight(WaQualityRating r) => switch (r) {
          WaQualityRating.high => 44,
          WaQualityRating.medium => 28,
          WaQualityRating.low => 14,
        };

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(waQualityLabel(l, q.rating), style: t.h3.copyWith(color: color)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l.wa_qs_explain, style: t.bodySmall.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
          if (q.messagingTier != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Text(l.wa_qs_tier, style: t.bodyMedium.copyWith(color: c.textSecondary))),
                Text(l.wa_qs_tier_value(q.messagingTier!), style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          if (q.trend.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(l.wa_qs_trend, style: t.caption.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: [for (final r in q.trend) waQualityLabel(l, r)].join('، '),
              child: SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final r in q.trend)
                      Expanded(
                        child: Container(
                          height: barHeight(r),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(color: barColor(r), borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l.wa_qs_tips, style: t.listTitle.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.xs),
          for (final tip in [l.wa_qs_tip1, l.wa_qs_tip2, l.wa_qs_tip3])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.check, size: 16, color: c.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(tip, style: t.bodySmall)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l.wa_qs_help,
            icon: AppIcons.help,
            variant: AppButtonVariant.text,
            onPressed: WaLinks.whatsAppHelp,
          ),
        ],
      ),
    );
  }
}
