import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/models.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../application/dashboard_controller.dart';
import 'dashboard_links.dart';
import 'widgets/ai_impact_card.dart';
import 'widgets/channels_breakdown_card.dart';
import 'widgets/dashboard_alert_strip.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/metric_grid.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/scope_range_bar.dart';
import 'widgets/team_now_card.dart';
import 'widgets/volume_chart_card.dart';

/// لوحة التحكم — tab root (spec "10 Dashboard.md").
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scroll = ScrollController();
  late final AppLifecycleListener _lifecycle;
  bool _compact = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(dashboardControllerProvider.notifier).onResume());
    _scroll.addListener(() {
      final compact = _scroll.offset > 80;
      if (compact != _compact) setState(() => _compact = compact);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps inactive tabs alive with tickers muted: that is our
    // "visible" signal for the 60 s refresh (§8).
    final visible = TickerMode.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(dashboardControllerProvider.notifier).setVisible(visible);
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static const _gap = SizedBox(height: 10);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final state = ref.watch(dashboardControllerProvider);
    final ctrl = ref.read(dashboardControllerProvider.notifier);
    final snap = state.snapshot;
    final reduced = AppMotion.reduced(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    Widget body;
    if (state.fullError) {
      body = Padding(
        padding: const EdgeInsets.only(top: AppSpacing.x5l),
        child: EmptyState(
          icon: AppIcons.wifiOff,
          title: l.dash_load_error,
          actionLabel: l.dash_retry,
          onAction: ctrl.refresh,
        ),
      );
    } else if (snap == null) {
      body = const DashboardSkeleton();
    } else {
      final alert = snap.topAlert;
      final chart = VolumeChartCard(snapshot: snap, generation: state.generation);
      final team = TeamNowCard(snapshot: snap);
      body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (alert != null) ...[
              const SizedBox(height: 6),
              DashboardAlertStrip(alert: alert, scope: snap.scope),
            ],
            const SizedBox(height: 6),
            if (snap.onboarding != null)
              OnboardingCard(steps: snap.onboarding!)
            else ...[
              MetricGrid(state: state),
              _gap,
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [Expanded(flex: 3, child: chart), const SizedBox(width: 10), Expanded(flex: 2, child: team)],
                  ),
                )
              else
                chart,
            ],
            if (!wide || snap.onboarding != null) ...[_gap, team],
            if (snap.permissions.isAdmin && snap.metrics.ai != null) ...[
              _gap,
              AiImpactCard(ai: snap.metrics.ai!, handling: snap.aiHandling),
            ],
            if (snap.channels.length > 1) ...[_gap, ChannelsBreakdownCard(channels: snap.channels)],
            if (snap.permissions.canViewReports)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Analytics.log('dash_web_reports');
                      DashboardLinks.webReports();
                    },
                    icon: Icon(AppIcons.link, size: 14, color: c.textSecondary),
                    label: Text(l.dash_web_reports, style: t.buttonSmall.copyWith(color: c.textSecondary)),
                  ),
                ),
              ),
          ],
        ),
      );
      // Scope / range switch: content fade 150 ms (§13).
      body = AnimatedSwitcher(
        duration: reduced ? Duration.zero : AppMotion.fast,
        child: KeyedSubtree(key: ValueKey(state.generation), child: body),
      );
    }

    final content = RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: ctrl.refresh,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          if (state.offline) ConnectionBanner(state: NetworkState.offline),
          DashboardHeader(state: state),
          ScopeRangeBar(state: state),
          Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: body),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      // Tab root: Android back goes to Conversations first (§2).
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.conversations);
      },
      child: Scaffold(
        backgroundColor: c.backgroundMuted,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              content,
              // Compact title after 80 dp of scroll, 150 ms fade (§3).
              IgnorePointer(
                ignoring: !_compact,
                child: AnimatedOpacity(
                  opacity: _compact ? 1 : 0,
                  duration: reduced ? Duration.zero : AppMotion.fast,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.backgroundMuted,
                      border: Border(bottom: BorderSide(color: c.divider)),
                    ),
                    child: Text(l.dash_title, style: t.h6.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
