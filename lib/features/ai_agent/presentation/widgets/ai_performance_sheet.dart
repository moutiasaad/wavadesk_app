import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/ai_agent_config.dart';
import '../test/ai_why_sheet.dart';

/// Detailed performance (AI Agent spec §4.7): weekly answered / handoffs
/// bars, totals, top handoff reasons, top KB sources.
Future<void> showAiPerformanceSheet(BuildContext context, AiAgentConfig config) {
  return AppBottomSheet.showExpanded<void>(
    context,
    title: context.l10n.ai_perf,
    subtitle: context.l10n.ai_perf_week,
    initialSize: 0.8,
    builder: (ctx, scroll) => _PerformanceBody(stats: config.stats, controller: scroll),
  );
}

class _PerformanceBody extends StatelessWidget {
  const _PerformanceBody({required this.stats, required this.controller});

  final AiWeekStats stats;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.sm),
          child: Text(text, style: t.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
        );
    Widget row(String label, String value, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: t.bodyMedium)),
              Text(
                value,
                style: t.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
      children: [
        Row(
          children: [
            Expanded(child: _Total(label: l.ai_perf_answered, value: stats.answered, color: c.primary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _Total(label: l.ai_perf_handoffs, value: stats.handoffs, color: c.warning)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (stats.daily.isEmpty)
          Text(l.ai_perf_none, style: t.bodySmall.copyWith(color: c.textTertiary))
        else
          _WeekBars(daily: stats.daily),
        if (stats.resolutionRate != null) row(l.ai_perf_resolution, '${(stats.resolutionRate! * 100).round()}%'),
        if (stats.thumbsUpRate != null) row(l.ai_perf_rating, '${(stats.thumbsUpRate! * 100).round()}%'),
        header(l.ai_perf_reasons),
        if (stats.topHandoffReasons.isEmpty)
          Text(l.ai_perf_none, style: t.bodySmall.copyWith(color: c.textTertiary))
        else
          for (final (reason, n) in stats.topHandoffReasons.take(5)) row(aiReasonLabel(l, reason), '$n'),
        header(l.ai_perf_sources),
        if (stats.topSources.isEmpty)
          Text(l.ai_perf_none, style: t.bodySmall.copyWith(color: c.textTertiary))
        else
          for (final (_, title, n) in stats.topSources.take(5)) row(title, '$n'),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label, style: t.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('$value', style: t.metricValue),
        ],
      ),
    );
  }
}

/// 7 day pairs (answered · handoffs), tallest = 100%.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.daily});

  final List<(DateTime, int, int)> daily;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final loc = context.localeName;
    final days = daily.length > 7 ? daily.sublist(daily.length - 7) : daily;
    final maxV = math.max(1, days.fold<int>(0, (m, d) => math.max(m, math.max(d.$2, d.$3))));
    const h = 96.0;

    return Semantics(
      label: [for (final d in days) '${intl.DateFormat('EEEE', loc).format(d.$1)}: ${d.$2} / ${d.$3}'].join('، '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: h,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _bar(c.primary, h * d.$2 / maxV),
                        const SizedBox(width: 3),
                        _bar(c.warning, h * d.$3 / maxV),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    intl.DateFormat('E', loc).format(d.$1),
                    style: t.overline.copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Widget _bar(Color color, double height) => Container(
        width: 10,
        height: math.max(3, height),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4), bottom: Radius.circular(2)),
        ),
      );
}
