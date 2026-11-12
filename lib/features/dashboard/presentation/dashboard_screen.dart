import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/l10n.dart';
import '../../../core/widgets/widgets.dart';
import '../../shell/home_shell.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_snapshot.dart';
import 'dash_palette.dart';
import 'widgets/conversations_chart.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/dashboard_teal_header.dart';
import 'widgets/kpi_grid.dart';
import 'widgets/team_now_card.dart';

/// لوحة التحكم — tab root (spec "10 Dashboard v2.md"): teal header that
/// scrolls away, 2×2 KPIs, conversations chart, team now. A white compact
/// bar fades in once the header has left the screen.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scroll = ScrollController();
  final _headerKey = GlobalKey();
  late final AppLifecycleListener _lifecycle;
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => ref.read(dashboardControllerProvider.notifier).onResume());
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final header = _headerKey.currentContext?.size?.height ?? 160;
    final top = MediaQuery.viewPaddingOf(context).top;
    // Collapsed once the teal header is hidden under the 52dp bar.
    final collapsed = _scroll.offset >= header - top - 52;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps inactive tabs alive with tickers muted: that is the
    // "visible" signal for the periodic refresh.
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    final state = ref.watch(dashboardControllerProvider);
    final ctrl = ref.read(dashboardControllerProvider.notifier);
    final snap = state.snapshot;
    final reduced = AppMotion.reduced(context);

    Widget body;
    if (state.fullError) {
      body = DashCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(l.dash_error, textAlign: TextAlign.center, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: l.dash_retry, variant: AppButtonVariant.secondary, onPressed: ctrl.refresh),
          ],
        ),
      );
    } else if (snap == null) {
      body = const DashboardSkeleton();
    } else {
      final waDown = snap.alerts.any((a) => a.kind == DashboardAlertKind.whatsappDisconnected);
      final empty = snap.onboarding != null || (snap.volume.total == 0 && snap.metrics.open == 0);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (waDown) ...[const _WhatsAppDownCard(), const SizedBox(height: 10)],
          KpiGrid(snapshot: snap, loading: state.switching),
          const SizedBox(height: 10),
          // Period switch: only the chart body shimmers, the card stays.
          if (state.switching)
            _ChartSkeleton(range: state.range)
          else
            ConversationsChart(snapshot: snap, generation: state.generation, empty: empty),
          const SizedBox(height: 10),
          TeamNowCard(snapshot: snap),
        ],
      );
      // Period switch: each value cross-fades on its own (KPI tiles, chart
      // regrow) — the page itself never swaps out.
    }

    final updated = state.lastUpdated == null ? '—' : intl.DateFormat('HH:mm').format(state.lastUpdated!);

    final content = RefreshIndicator(
      color: Colors.white,
      backgroundColor: DashPalette.header,
      onRefresh: ctrl.refresh,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: KeyedSubtree(
              key: _headerKey,
              child: DashboardTealHeader(range: state.range, onRange: ctrl.setRange),
            ),
          ),
          if (state.offline)
            SliverToBoxAdapter(
              child: Container(
                color: c.warningContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  l.dash_offline(updated),
                  textAlign: TextAlign.center,
                  style: t.caption.copyWith(fontWeight: FontWeight.w600, color: c.textWarning),
                ),
              ),
            ),
          SliverPadding(
            // KPI grid padding 14 / 16 / 0; cards 10 apart; 24 at the bottom
            // above the tab bar the shell draws over the page.
            padding: EdgeInsets.fromLTRB(16, 14, 16, tabBarInset(context) + 24),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: body),
              ),
            ),
          ),
        ],
      ),
    );

    return PopScope(
      canPop: false,
      // Tab root: Android back goes to Conversations first.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.conversations);
      },
      child: Scaffold(
        backgroundColor: p.page,
        body: Stack(
          children: [
            content,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSwitcher(
                duration: reduced ? Duration.zero : AppMotion.fast,
                child: _collapsed ? const DashboardCollapsedBar() : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red info card above the KPIs when WhatsApp is disconnected (§5).
class _WhatsAppDownCard extends StatelessWidget {
  const _WhatsAppDownCard();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    return DashCard(
      color: p.waitingBg,
      borderColor: p.waitingBorder,
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
      child: Row(
        children: [
          AppIcon(AppIcons.warning, dp: 18, color: p.waitingFg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(l.dash_wa_down, style: t.bodySmall.copyWith(fontWeight: FontWeight.w700, color: p.waitingFg)),
          ),
          TextButton(
            onPressed: () => context.push(Routes.whatsappConnect()),
            style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: t.buttonSmall, minimumSize: const Size(48, 40)),
            child: Text(l.dash_alert_wa_action),
          ),
        ],
      ),
    );
  }
}

/// Chart card while a new period loads: same card and title, shimmering
/// bars in place of the data.
class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton({required this.range});

  final DashboardRange range;

  static const _heights = [0.35, 0.55, 0.4, 0.7, 0.5, 0.85, 0.6, 0.45, 0.75, 0.5, 0.3, 0.4];

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final l = context.l10n;
    final title = switch (range) {
      DashboardRange.last7 => l.dash_range_7d,
      DashboardRange.last30 => l.dash_range_30d,
      _ => l.dash_volume_today,
    };
    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: t.h6.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800))),
              const AppSkeleton(child: SkeletonBox(width: 64, height: 12)),
            ],
          ),
          const SizedBox(height: 10),
          AppSkeleton(
            child: SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < _heights.length; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Expanded(child: SkeletonBox(height: 64 * _heights[i], radius: 5)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const AppSkeleton(child: SkeletonBox(height: 10)),
        ],
      ),
    );
  }
}
