import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/dashboard_snapshot.dart';
import '../dash_palette.dart';

enum _BarState { past, current, future }

class _Bar {
  const _Bar(this.count, this.state, this.slot);
  final int count;
  final _BarState state;

  /// Tooltip slot text ("12 م", "الثلاثاء 4/11").
  final String slot;
}

/// Conversations card (Dashboard v2 §4.3): title + total, 64dp hand-built
/// bars (past / current teal / future grey), axis labels, tap tooltip.
class ConversationsChart extends StatefulWidget {
  const ConversationsChart({super.key, required this.snapshot, required this.generation, this.empty = false});

  final DashboardSnapshot snapshot;

  /// Bumped on period change: bars grow again.
  final int generation;

  /// New workspace with no conversations: body becomes the empty prompt.
  final bool empty;

  @override
  State<ConversationsChart> createState() => _ConversationsChartState();
}

class _ConversationsChartState extends State<ConversationsChart> with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(vsync: this);
  int? _selected;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(ConversationsChart old) {
    super.didUpdateWidget(old);
    if (old.generation != widget.generation) {
      _selected = null;
      _start();
    }
  }

  void _start() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppMotion.reduced(context)) {
        _grow.value = 1;
        return;
      }
      final n = _bars(context).length;
      _grow.duration = Duration(milliseconds: 400 + 20 * (n > 0 ? n - 1 : 0));
      _grow.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _grow.dispose();
    super.dispose();
  }

  void _tap(int i) {
    _hide?.cancel();
    setState(() => _selected = i);
    _hide = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _selected = null);
    });
  }

  // ---- data ---------------------------------------------------------------------

  List<_Bar> _bars(BuildContext context) {
    final s = widget.snapshot;
    final loc = context.localeName;
    final now = DateTime.now();
    final series = s.volume.series;
    if (s.range == DashboardRange.today) {
      // 12 equal slots over the working day (9 → 21 by default; 24h = 2h slots).
      final startH = s.is24h ? 0 : s.businessHoursStart;
      final endH = s.is24h ? 24 : (s.businessHoursEnd > startH ? s.businessHoursEnd : startH + 12);
      final day = DateTime(now.year, now.month, now.day);
      final from = day.add(Duration(hours: startH));
      final slot = Duration(minutes: (endH - startH) * 60 ~/ 12);
      final fmt = intl.DateFormat('h a', loc);
      return [
        for (var i = 0; i < 12; i++)
          () {
            final a = from.add(slot * i);
            final b = a.add(slot);
            final count = series.where((x) => !x.start.isBefore(a) && x.start.isBefore(b)).fold<int>(0, (n, x) => n + x.total);
            final state = !now.isBefore(b) ? _BarState.past : (!now.isBefore(a) ? _BarState.current : _BarState.future);
            return _Bar(count, state, fmt.format(a));
          }(),
      ];
    }
    final today = DateTime(now.year, now.month, now.day);
    final fmt = intl.DateFormat('E d/M', loc);
    return [
      for (final b in series)
        () {
          final d = DateTime(b.start.year, b.start.month, b.start.day);
          final state = b.isFuture || d.isAfter(today)
              ? _BarState.future
              : (b.isCurrent || d == today ? _BarState.current : _BarState.past);
          return _Bar(b.total, state, fmt.format(b.start));
        }(),
    ];
  }

  List<String> _axis(BuildContext context, List<_Bar> bars) {
    final s = widget.snapshot;
    final loc = context.localeName;
    if (s.range == DashboardRange.today) {
      final startH = s.is24h ? 0 : s.businessHoursStart;
      final endH = s.is24h ? 24 : (s.businessHoursEnd > startH ? s.businessHoursEnd : startH + 12);
      final day = DateTime.now();
      final from = DateTime(day.year, day.month, day.day, startH);
      final fmt = intl.DateFormat('h a', loc);
      final span = (endH - startH) * 60;
      return [for (var k = 0; k <= 4; k++) fmt.format(from.add(Duration(minutes: span * k ~/ 4)))];
    }
    final series = s.volume.series;
    if (series.isEmpty) return const [];
    if (s.range == DashboardRange.last7) {
      final fmt = intl.DateFormat('E', loc);
      return [for (final b in series) fmt.format(b.start)];
    }
    final fmt = intl.DateFormat('d/M', loc);
    final last = series.length - 1;
    return [for (final i in {0, last ~/ 3, last * 2 ~/ 3, last}) fmt.format(series[i].start)];
  }

  // ---- UI -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    final s = widget.snapshot;
    final title = switch (s.range) {
      DashboardRange.last7 => l.dash_range_7d,
      DashboardRange.last30 => l.dash_range_30d,
      _ => l.dash_volume_today,
    };

    final header = Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: t.h6.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
          ),
        ),
        Text(l.dash_total('${s.volume.total}'), style: t.bodySmall.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary)),
      ],
    );

    if (widget.empty) {
      return DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 14),
            AppIcon(AppIcons.conversation, dp: 32, color: p.axis),
            const SizedBox(height: 8),
            Text(l.dash_empty, textAlign: TextAlign.center, style: t.bodySmall.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600)),
            Center(
              child: TextButton(
                onPressed: () => context.push(Routes.whatsapp),
                style: TextButton.styleFrom(foregroundColor: c.primary, textStyle: t.buttonSmall, minimumSize: const Size(48, 40)),
                child: Text(l.dash_connect_wa),
              ),
            ),
          ],
        ),
      );
    }

    final bars = _bars(context);
    final axis = _axis(context, bars);
    final max = bars.fold<int>(0, (m, b) => b.count > m ? b.count : m);
    final gap = s.range == DashboardRange.last30 ? 2.0 : 5.0;
    final peak = bars.isEmpty ? null : bars.reduce((a, b) => b.count > a.count ? b : a);

    Color colorOf(_BarState st) => switch (st) {
          _BarState.past => p.barPast,
          _BarState.current => p.barCurrent,
          _BarState.future => p.barFuture,
        };

    final chart = LayoutBuilder(
      builder: (context, box) {
        final n = bars.length;
        final w = box.maxWidth;
        final barW = n == 0 ? 0.0 : (w - gap * (n - 1)) / n;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        Widget? tip;
        final sel = _selected;
        if (sel != null && sel < n) {
          final center = sel * (barW + gap) + barW / 2;
          final x = rtl ? w - center : center;
          tip = Positioned(
            left: (x - 70).clamp(0.0, w - 140 < 0 ? 0.0 : w - 140),
            width: 140,
            top: -34,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: DashPalette.tooltip, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    l.dash_bar_tip('${bars[sel].count}', bars[sel].slot),
                    maxLines: 1,
                    style: t.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _grow,
                builder: (context, _) => Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: l.dash_bar_tip('${bars[i].count}', bars[i].slot),
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _tap(i),
                            child: SizedBox(
                              height: 64,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: () {
                                    final b = bars[i];
                                    final full = b.state == _BarState.future || max == 0 ? 0.06 : (b.count / max).clamp(0.06, 1.0);
                                    final total = _grow.duration?.inMilliseconds ?? 0;
                                    if (total == 0) return full;
                                    final begin = (20 * i) / total;
                                    final end = ((20 * i) + 400) / total;
                                    final v = Curves.easeOutCubic.transform(((_grow.value - begin) / (end - begin)).clamp(0.0, 1.0));
                                    return full * v;
                                  }(),
                                  widthFactor: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colorOf(bars[i].state),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?tip,
            ],
          ),
        );
      },
    );

    final axisStyle = t.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: p.axis);
    final axisRow = s.range == DashboardRange.last7
        ? Row(
            children: [
              for (var i = 0; i < axis.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Text(axis[i], style: axisStyle))),
              ],
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final a in axis) Text(a, style: axisStyle)],
          );

    return DashCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 10),
          Semantics(
            label: l.dash_a11y_chart(title, l.dash_total('${s.volume.total}'), peak?.slot ?? '', '${peak?.count ?? 0}'),
            child: chart,
          ),
          const SizedBox(height: 4),
          axisRow,
        ],
      ),
    );
  }
}
