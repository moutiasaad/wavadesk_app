import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/metric_formatters.dart';

/// "سرعة أول رد" (spec §4.4.1): big value, target line, 4 buckets.
Future<void> showFirstResponseSheet(BuildContext context, DashboardSnapshot s) {
  final l = context.l10n;
  return AppBottomSheet.show<void>(
    context,
    title: l.dash_frt_title,
    builder: (ctx) => _FirstResponseBody(metrics: s.metrics),
  );
}

class _FirstResponseBody extends StatelessWidget {
  const _FirstResponseBody({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final avg = metrics.avgFirstResponseSeconds;
    final b = metrics.frtBuckets;
    final rows = b == null
        ? const <(String, double, Color)>[]
        : [
            (l.dash_frt_lt1, b.lt1m, c.primary),
            (l.dash_frt_1_5, b.m1to5, c.primary),
            (l.dash_frt_5_15, b.m5to15, c.warning),
            (l.dash_frt_gt15, b.gt15m, c.error),
          ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avg == null ? '—' : MetricFormat.duration(avg, hourUnit: l.dash_hours_short, minuteUnit: l.dash_minutes_short, dayUnit: l.dash_days_short),
                style: t.metricValue.copyWith(fontSize: 36),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (avg != null && avg < 3600)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(l.dash_minute, style: t.caption.copyWith(color: c.textSecondary)),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(l.dash_frt_target('${metrics.slaSeconds ~/ 60}'), style: t.chipLabel.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rows.isEmpty)
            Text(l.dash_frt_empty, style: t.bodySmall.copyWith(color: c.textTertiary))
          else
            for (final (label, share, color) in rows) ...[
              Semantics(
                label: '$label ${MetricFormat.percent(share)}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(width: 92, child: Text(label, style: t.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        child: LinearProgressIndicator(
                          value: share.clamp(0, 1),
                          minHeight: 8,
                          color: color,
                          backgroundColor: c.surfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        MetricFormat.percent(share),
                        textAlign: TextAlign.end,
                        style: t.bodySmall.copyWith(fontWeight: FontWeight.w700, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          const SizedBox(height: AppSpacing.xs),
          Text(l.dash_frt_note, style: t.caption.copyWith(color: c.textTertiary)),
        ],
      ),
    );
  }
}
