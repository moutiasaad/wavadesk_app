import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/duration_format.dart';
import '../dash_palette.dart';

String durationUnitLabel(AppLocalizations l, DurationUnit u) => switch (u) {
      DurationUnit.seconds => l.dash_unit_sec,
      DurationUnit.minutes => l.dash_minute,
      DurationUnit.hours => l.dash_unit_hr,
    };

/// Response-time sheet (Dashboard v2 §6.1): big value, change vs the
/// previous period, and a you / team / AI breakdown.
Future<void> showResponseTimeSheet(BuildContext context, DashboardSnapshot s) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.dash_first_response,
    builder: (_) => _Body(snapshot: s),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    final m = snapshot.metrics;
    final avg = m.avgFirstResponseSeconds;
    final big = avg == null ? null : DurationFormat.of(avg);

    // Previous period = current − delta (the API sends the delta in seconds).
    String? change;
    Color? changeColor;
    final delta = m.firstResponseDeltaSeconds;
    if (avg != null && delta != null && delta != 0) {
      final prev = avg - delta;
      if (prev > 0) {
        final pct = (delta.abs() / prev * 100).round();
        if (pct > 0) {
          change = delta < 0 ? l.dash_faster('$pct') : l.dash_slower('$pct');
          changeColor = delta < 0 ? p.up : p.down;
        }
      }
    }

    String fmt(int seconds) {
      final (v, u) = DurationFormat.of(seconds);
      return '$v ${durationUnitLabel(l, u)}';
    }

    final mine = snapshot.teamNow.where((x) => x.isMe).firstOrNull?.avgFirstResponseToday;
    final rows = <(String, String)>[
      if (mine != null) (l.dash_breakdown_you, fmt(mine)),
      if (avg != null) (l.dash_breakdown_team, fmt(avg)),
      if (snapshot.aiEnabled) (l.dash_breakdown_ai, l.dash_ai_instant),
    ];
    final tabular = const [FontFeature.tabularFigures()];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(big?.$1 ?? '—', style: t.metricValue.copyWith(fontSize: 40, fontFeatures: tabular)),
              if (big != null) ...[
                const SizedBox(width: 6),
                Text(durationUnitLabel(l, big.$2), style: t.bodySmall.copyWith(color: c.textSecondary)),
              ],
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: change, style: t.bodySmall.copyWith(color: changeColor, fontWeight: FontWeight.w700)),
                TextSpan(text: '  ${l.dash_vs_previous}', style: t.caption.copyWith(color: c.textTertiary)),
              ]),
            ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: p.cardBorder),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(rows[i].$1, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w600))),
                    Text(rows[i].$2, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800, fontFeatures: tabular)),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
