import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../conversations/application/relative_time_ticker.dart';
import '../../../conversations/domain/conversation_filters.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/metric_formatters.dart';
import '../dashboard_links.dart';
import 'first_response_sheet.dart';
import 'metric_card.dart';

/// 2×2 metrics (spec §4.4); 4×1 on tablets, 1 column at 200% text (§11).
class MetricGrid extends ConsumerWidget {
  const MetricGrid({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final s = state.snapshot!;
    final m = s.metrics;
    final now = ref.watch(inboxClockProvider);
    final me = s.scope == DashboardScope.me;
    final thousand = l.dash_thousand;
    String count(num v) => MetricFormat.count(v.toInt(), thousandWord: thousand);
    String a11y(String label, String value, String? aside) => l.dash_a11y_metric(label, value, aside ?? '');
    void tap(String metric, VoidCallback go) {
      Analytics.log('dash_metric_tap', {'metric': metric});
      go();
    }

    // 1 · open
    final openDelta = MetricFormat.delta(m.openDelta);
    final open = DashboardMetricCard(
      label: l.dash_open,
      value: m.open,
      display: count,
      aside: openDelta,
      // For "open", up is neutral (§4.4).
      asideColor: c.textSecondary,
      countUp: state.firstLoad,
      flash: state.flashed.contains('open'),
      semanticLabel: a11y(l.dash_open, count(m.open), openDelta),
      onTap: () => tap('open', () => DashboardLinks.inbox(context, ref, segment: me ? InboxSegment.mine : InboxSegment.all)),
    );

    // 2 · awaiting
    final awaitingLabel = me ? l.dash_awaiting_me : l.dash_awaiting_team;
    final oldest = m.oldestWaitSeconds == null ? null : m.oldestWaitSeconds! + now.difference(s.generatedAt).inSeconds.clamp(0, 1 << 30);
    final awaitingAside = m.awaiting == 0 ? l.dash_none_waiting : (oldest == null ? null : l.dash_oldest('${MetricFormat.minutes(oldest)}'));
    final awaiting = DashboardMetricCard(
      label: awaitingLabel,
      value: m.awaiting,
      display: count,
      aside: awaitingAside,
      asideColor: m.awaiting == 0 ? c.textSuccess : null,
      variant: m.awaiting > 0 ? MetricVariant.alert : MetricVariant.normal,
      countUp: state.firstLoad,
      flash: state.flashed.contains('awaiting'),
      semanticLabel: a11y(awaitingLabel, count(m.awaiting), awaitingAside),
      onTap: () => tap(
        'awaiting',
        () => DashboardLinks.inbox(context, ref, segment: me ? InboxSegment.mine : InboxSegment.all, chip: QuickChip.awaiting),
      ),
    );

    // 3 · first response
    final frt = m.avgFirstResponseSeconds;
    String dur(num v) => MetricFormat.duration(v.toInt(), hourUnit: l.dash_hours_short, minuteUnit: l.dash_minutes_short);
    final frtDelta = MetricFormat.durationDelta(m.firstResponseDeltaSeconds);
    final frtAside = [if (frt != null && frt < 3600) l.dash_minute, ?frtDelta].join(' ');
    final faster = (m.firstResponseDeltaSeconds ?? 0) < 0;
    final first = DashboardMetricCard(
      label: l.dash_first_response,
      value: frt ?? 0,
      display: (v) => frt == null ? '—' : dur(v),
      aside: frtAside.isEmpty ? null : frtAside,
      // Lower is better: green when it went down.
      asideColor: frtDelta == null ? null : (faster ? c.textSuccess : c.textError),
      asideIcon: frtDelta == null ? null : (faster ? AppIcons.trendDown : AppIcons.trendUp),
      countUp: state.firstLoad && frt != null,
      semanticLabel: a11y(l.dash_first_response, frt == null ? '—' : dur(frt), frtAside),
      onTap: () => tap('first_response', () => showFirstResponseSheet(context, s)),
    );

    // 4 · AI reply rate, or resolved when the AI is off
    final ai = m.ai;
    final fourth = ai != null
        ? DashboardMetricCard(
            label: l.dash_ai_reply,
            labelIcon: AppIcons.sparkle,
            value: (ai.rate * 100).round(),
            display: (v) => '${v.round()}%',
            aside: l.dash_of_questions,
            variant: MetricVariant.tonal,
            countUp: state.firstLoad,
            semanticLabel: a11y(l.dash_ai_reply, MetricFormat.percent(ai.rate), l.dash_of_questions),
            onTap: () => tap('ai_reply', () => context.push(Routes.aiAgent)),
          )
        : DashboardMetricCard(
            label: l.dash_resolved,
            value: m.resolved,
            display: count,
            aside: s.range == DashboardRange.today ? l.dash_range_today : null,
            countUp: state.firstLoad,
            semanticLabel: a11y(l.dash_resolved, count(m.resolved), null),
            onTap: () => tap('resolved', () => DashboardLinks.inbox(context, ref, segment: InboxSegment.all, chip: QuickChip.closed)),
          );

    final cards = [open, awaiting, first, fourth];
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final big = MediaQuery.textScalerOf(context).scale(10) >= 20;
    final perRow = big ? 1 : (wide ? 4 : 2);

    return Column(
      children: [
        for (var i = 0; i < cards.length; i += perRow) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + perRow && j < cards.length; j++) ...[
                  if (j > i) const SizedBox(width: 10),
                  Expanded(child: cards[j]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
