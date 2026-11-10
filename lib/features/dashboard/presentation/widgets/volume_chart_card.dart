import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/metric_formatters.dart';
import 'volume_bar_chart.dart';

/// "المحادثات اليوم" card (Dashboard spec §4.5). Outer margins belong to the
/// screen.
class VolumeChartCard extends StatefulWidget {
  const VolumeChartCard({super.key, required this.snapshot, required this.generation});

  final DashboardSnapshot snapshot;
  final int generation;

  @override
  State<VolumeChartCard> createState() => _VolumeChartCardState();
}

class _VolumeChartCardState extends State<VolumeChartCard> {
  bool _showAi = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final s = widget.snapshot;
    final range = s.range;
    final empty = s.volume.total == 0;
    final title = range == DashboardRange.today
        ? l.dash_volume_today
        : l.dash_volume_range(switch (range) {
            DashboardRange.today => l.dash_range_today,
            DashboardRange.yesterday => l.dash_range_yesterday,
            DashboardRange.last7 => l.dash_range_7d,
            DashboardRange.last30 => l.dash_range_30d,
          });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: t.h6.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.dash_total(MetricFormat.grouped(s.volume.total)),
                style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
              ),
            ],
          ),
          if (s.aiEnabled && !empty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppFilterChip(label: l.dash_legend_all, selected: !_showAi, onTap: () => setState(() => _showAi = false)),
                AppFilterChip(
                  label: l.dash_legend_ai,
                  leading: Icon(AppIcons.sparkle, size: 13, color: c.accent),
                  selected: _showAi,
                  onTap: () => setState(() => _showAi = true),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Stack(
            alignment: Alignment.center,
            children: [
              VolumeBarChart(
                volume: s.volume,
                range: range,
                generation: widget.generation,
                showAi: _showAi && s.aiEnabled,
              ),
              if (empty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: VolumeBarChart.chartHeight,
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        range == DashboardRange.today ? l.dash_no_volume : l.dash_no_volume_range,
                        style: t.bodySmall.copyWith(color: c.textTertiary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
