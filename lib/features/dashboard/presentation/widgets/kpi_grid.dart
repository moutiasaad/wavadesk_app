import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../conversations/application/conversation_filters_controller.dart';
import '../../../conversations/application/relative_time_ticker.dart';
import '../../../conversations/domain/conversation_filters.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/duration_format.dart';
import '../dash_palette.dart';
import '../dashboard_links.dart';
import '../sheets/response_time_sheet.dart';

/// 2×2 KPI grid (Dashboard v2 §4.2): gap 10; one column at 200% text.
class KpiGrid extends ConsumerWidget {
  const KpiGrid({super.key, required this.snapshot, this.loading = false});

  final DashboardSnapshot snapshot;

  /// New period loading: labels stay, values shimmer.
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final p = DashPalette.of(context);
    final s = snapshot;
    final m = s.metrics;
    final now = ref.watch(inboxClockProvider);
    void log(String metric) => Analytics.log('dash_metric_tap', {'metric': metric});

    // 1 · open, with the change vs the previous period (hidden when 0).
    final d = m.openDelta ?? 0;
    final open = KpiTile(
      label: l.dash_open,
      value: '${m.open}',
      meta: d == 0 ? null : (d > 0 ? '+$d' : '−${-d}'),
      metaColor: d > 0 ? p.up : p.down,
      metaBold: true,
      onTap: () {
        log('open');
        DashboardLinks.inbox(context, ref, segment: InboxSegment.mine);
      },
    );

    // 2 · waiting for me (red), "nothing waiting" in green when 0.
    final Widget waiting;
    if (m.awaiting == 0) {
      waiting = KpiTile(
        label: l.dash_awaiting_me,
        value: '0',
        meta: l.dash_nothing_waiting,
        metaColor: p.up,
        onTap: () => _openWaiting(context, ref),
      );
    } else {
      final oldest = m.oldestWaitSeconds == null
          ? null
          : ((m.oldestWaitSeconds! + now.difference(s.generatedAt).inSeconds.clamp(0, 1 << 30)) / 60).ceil();
      waiting = KpiTile(
        label: l.dash_awaiting_me,
        value: '${m.awaiting}',
        meta: oldest == null ? null : l.dash_oldest('$oldest ${l.dash_minutes_short}'),
        labelColor: p.waitingFg,
        valueColor: p.waitingFg,
        background: p.waitingBg,
        border: p.waitingBorder,
        onTap: () => _openWaiting(context, ref),
      );
    }

    // 3 · average first reply: 45 ثانية / 1:20 دقيقة / 1:05 ساعة.
    final frt = m.avgFirstResponseSeconds == null ? null : DurationFormat.of(m.avgFirstResponseSeconds!);
    final first = KpiTile(
      label: l.dash_first_response,
      value: frt?.$1 ?? '—',
      meta: frt == null ? null : durationUnitLabel(l, frt.$2),
      onTap: () {
        log('first_response');
        showResponseTimeSheet(context, s);
      },
    );

    // 4 · AI share (teal), "متوقف" when the AI is off.
    final ai = m.ai;
    final fourth = ai == null
        ? KpiTile(
            label: l.dash_ai_reply,
            labelIcon: AppIcons.ai,
            value: '—',
            meta: l.dash_ai_off,
            onTap: () => context.push(Routes.aiAgent),
          )
        : KpiTile(
            label: l.dash_ai_reply,
            labelIcon: AppIcons.ai,
            value: '${(ai.rate * 100).round()}%',
            meta: l.dash_of_questions,
            labelColor: p.aiFg,
            valueColor: p.aiFg,
            metaColor: p.aiFg,
            background: p.aiBg,
            border: p.aiBorder,
            onTap: () {
              log('ai_reply');
              context.push(Routes.aiAgent);
            },
          );

    final tiles = [
      for (final t in [open, waiting, first, fourth]) t is KpiTile && loading ? t.asLoading() : t,
    ];
    final perRow = MediaQuery.textScalerOf(context).scale(10) >= 20 ? 1 : 2;
    return Semantics(
      container: true,
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i += perRow) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + perRow && j < tiles.length; j++) ...[
                    if (j > i) const SizedBox(width: 10),
                    Expanded(child: tiles[j]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Inbox · "بانتظار الرد", oldest first.
  void _openWaiting(BuildContext context, WidgetRef ref) {
    Analytics.log('dash_metric_tap', {'metric': 'awaiting'});
    final filters = ref.read(conversationFiltersProvider.notifier);
    filters.setAdvanced(ref.read(conversationFiltersProvider).advanced.copyWith(sort: InboxSort.oldest));
    DashboardLinks.inbox(context, ref, segment: InboxSegment.mine, chip: QuickChip.awaiting);
  }
}

/// One KPI card: label 12/700, then value 28/800 (tabular) and meta 12 on
/// one baseline row (gap 6). The whole tile is one semantic button.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.meta,
    this.labelIcon,
    this.labelColor,
    this.valueColor,
    this.metaColor,
    this.metaBold = false,
    this.background,
    this.border,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final String value;
  final String? meta;
  final IconData? labelIcon;
  final Color? labelColor;
  final Color? valueColor;
  final Color? metaColor;
  final bool metaBold;
  final Color? background;
  final Color? border;
  final VoidCallback onTap;

  /// Value + meta replaced by shimmer bars (period switch).
  final bool loading;

  KpiTile asLoading() => KpiTile(
        label: label,
        value: value,
        meta: meta,
        labelIcon: labelIcon,
        labelColor: labelColor,
        valueColor: valueColor,
        metaColor: metaColor,
        metaBold: metaBold,
        background: background,
        border: border,
        onTap: onTap,
        loading: true,
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final lc = labelColor ?? c.textSecondary;
    final reduced = AppMotion.reduced(context);
    return Semantics(
      button: true,
      label: l.dash_kpi_a11y(label, value, meta ?? ''),
      excludeSemantics: true,
      child: DashCard(
        color: background,
        borderColor: border,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (labelIcon != null) ...[AppIcon(labelIcon, dp: 12, color: lc), const SizedBox(width: 4)],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: lc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: reduced ? Duration.zero : AppMotion.fast,
              child: loading
                  ? const AppSkeleton(
                      key: ValueKey('loading'),
                      child: Padding(
                        padding: EdgeInsets.only(top: 6, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SkeletonBox(width: 46, height: 24, radius: 6),
                            SizedBox(width: 6),
                            SkeletonBox(width: 40, height: 10),
                          ],
                        ),
                      ),
                    )
                  : Wrap(
                key: ValueKey('$value|$meta'),
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 6,
                children: [
                  Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: t.metricValue.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: valueColor ?? c.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (meta != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        meta!,
                        style: t.caption.copyWith(
                          fontSize: 12,
                          fontWeight: metaBold ? FontWeight.w700 : FontWeight.w500,
                          color: metaColor ?? c.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
