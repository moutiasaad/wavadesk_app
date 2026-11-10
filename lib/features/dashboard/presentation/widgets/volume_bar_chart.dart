import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/metric_formatters.dart';

/// Conversation volume bars (Dashboard spec §4.5, §12, §13).
///
/// Everything — bars, x labels and the scrub tooltip — is painted by one
/// [CustomPainter], so there is no layout-time rebuild. RTL: the earliest
/// bucket sits on the right.
class VolumeBarChart extends StatefulWidget {
  const VolumeBarChart({
    super.key,
    required this.volume,
    required this.range,
    required this.generation,
    this.showAi = false,
    this.animate = true,
  });

  final VolumeSeries volume;
  final DashboardRange range;

  /// Bars regrow when this changes (scope / range switch).
  final int generation;

  /// Stack the AI-handled share on top of each bar.
  final bool showAi;
  final bool animate;

  static const chartHeight = 96.0;
  static const gap = 5.0;

  @override
  State<VolumeBarChart> createState() => _VolumeBarChartState();
}

class _VolumeBarChartState extends State<VolumeBarChart> with TickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(vsync: this);
  late final AnimationController _tip = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
  int? _selected;
  bool _scrubLogged = false;
  Timer? _hide;

  int get _n => widget.volume.series.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_grow.status == AnimationStatus.dismissed && _grow.value == 0) _startGrow();
  }

  @override
  void didUpdateWidget(VolumeBarChart old) {
    super.didUpdateWidget(old);
    if (old.generation != widget.generation) {
      _clearSelection(animate: false);
      _startGrow();
    } else if (_selected != null && _selected! >= _n) {
      _clearSelection(animate: false);
    }
  }

  void _startGrow() {
    if (!widget.animate || AppMotion.reduced(context) || _n == 0) {
      _grow.value = 1;
      return;
    }
    // 300ms per bar, 30ms stagger.
    _grow.duration = Duration(milliseconds: 300 + 30 * (_n - 1));
    _grow.forward(from: 0);
  }

  @override
  void dispose() {
    _hide?.cancel();
    _grow.dispose();
    _tip.dispose();
    super.dispose();
  }

  // ---- interaction -------------------------------------------------------------

  int? _indexAt(double dx) {
    final box = context.size;
    if (box == null || _n == 0) return null;
    final slot = box.width / _n;
    final visual = (dx / slot).floor().clamp(0, _n - 1);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return rtl ? _n - 1 - visual : visual;
  }

  void _select(int? i) {
    if (i == null || i == _selected) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = i);
    if (AppMotion.reduced(context)) {
      _tip.value = 1;
    } else if (_tip.value < 1) {
      _tip.forward();
    }
  }

  void _beginScrub(double dx) {
    _hide?.cancel();
    if (!_scrubLogged) {
      _scrubLogged = true;
      Analytics.log('dash_chart_scrub', {'range': widget.range.wire});
    }
    _select(_indexAt(dx));
  }

  void _endScrub() {
    _scrubLogged = false;
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 2500), () => _clearSelection());
  }

  void _clearSelection({bool animate = true}) {
    _hide?.cancel();
    if (_selected == null) return;
    if (!animate || !mounted || AppMotion.reduced(context)) {
      _tip.value = 0;
      if (mounted) setState(() => _selected = null);
      return;
    }
    _tip.reverse().whenComplete(() {
      if (mounted && _tip.value == 0) setState(() => _selected = null);
    });
  }

  void _step(int delta) {
    if (_n == 0) return;
    final next = ((_selected ?? (delta > 0 ? -1 : _n)) + delta).clamp(0, _n - 1);
    _select(next);
    _endScrub();
  }

  String _tooltip(BuildContext context, VolumeBucket b) =>
      context.l10n.dash_tooltip(b.label, MetricFormat.grouped(b.total), MetricFormat.grouped(b.ai));

  // ---- build -------------------------------------------------------------------

  /// Indices that carry an x label (§4.5: 5 evenly spaced, 3 at large text;
  /// 30 days: every 7 days).
  List<int> _labelIndices(double textScale) {
    if (_n == 0) return const [];
    if (widget.range == DashboardRange.last30) {
      return [for (var i = _n - 1; i >= 0; i -= 7) i].reversed.toList();
    }
    final count = math.min(_n, textScale >= 1.5 ? 3 : 5);
    if (count <= 1) return [0];
    return {for (var k = 0; k < count; k++) ((_n - 1) * k / (count - 1)).round()}.toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final labelStyle = t.overline.copyWith(fontWeight: FontWeight.w600, color: c.textTertiary, letterSpacing: 0);
    final labelHeight = scaler.scale(labelStyle.fontSize!) * (labelStyle.height ?? 1.3);
    final series = widget.volume.series;

    final title = widget.range == DashboardRange.today
        ? l.dash_volume_today
        : l.dash_volume_range(switch (widget.range) {
            DashboardRange.today => l.dash_range_today,
            DashboardRange.yesterday => l.dash_range_yesterday,
            DashboardRange.last7 => l.dash_range_7d,
            DashboardRange.last30 => l.dash_range_30d,
          });
    final peak = widget.volume.peak;
    final summary = l.dash_a11y_chart(
      title,
      MetricFormat.grouped(widget.volume.total),
      peak?.label ?? '',
      MetricFormat.grouped(peak?.total ?? 0),
    );
    final sel = _selected == null || _selected! >= series.length ? null : series[_selected!];

    return Semantics(
      label: summary,
      value: sel == null ? null : _tooltip(context, sel),
      onIncrease: _n == 0 ? null : () => _step(1),
      onDecrease: _n == 0 ? null : () => _step(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _beginScrub(d.localPosition.dx),
        onTapUp: (_) => _endScrub(),
        onHorizontalDragStart: (d) => _beginScrub(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => _select(_indexAt(d.localPosition.dx)),
        onHorizontalDragEnd: (_) => _endScrub(),
        onHorizontalDragCancel: _endScrub,
        child: AnimatedBuilder(
          animation: Listenable.merge([_grow, _tip]),
          builder: (context, _) => CustomPaint(
            size: Size(double.infinity, VolumeBarChart.chartHeight + 6 + labelHeight),
            painter: _BarsPainter(
              series: series,
              grow: _grow.value,
              barCount: _n,
              showAi: widget.showAi,
              rtl: Directionality.of(context) == TextDirection.rtl,
              selected: _selected,
              tipProgress: _tip.value,
              tipText: sel == null ? null : _tooltip(context, sel),
              tipStyle: t.caption.copyWith(color: c.snackbarForeground),
              tipBg: c.snackbarBackground,
              labelIndices: _labelIndices(scaler.scale(1)),
              labelStyle: labelStyle,
              textScaler: scaler,
              textDirection: Directionality.of(context),
              past: c.primaryContainerBorder,
              current: c.primary,
              future: c.surfaceVariant,
              ai: c.accent.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.series,
    required this.grow,
    required this.barCount,
    required this.showAi,
    required this.rtl,
    required this.selected,
    required this.tipProgress,
    required this.tipText,
    required this.tipStyle,
    required this.tipBg,
    required this.labelIndices,
    required this.labelStyle,
    required this.textScaler,
    required this.textDirection,
    required this.past,
    required this.current,
    required this.future,
    required this.ai,
  });

  final List<VolumeBucket> series;
  final double grow;
  final int barCount;
  final bool showAi;
  final bool rtl;
  final int? selected;
  final double tipProgress;
  final String? tipText;
  final TextStyle tipStyle;
  final Color tipBg;
  final List<int> labelIndices;
  final TextStyle labelStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final Color past;
  final Color current;
  final Color future;
  final Color ai;

  static const _minShare = 0.06;

  /// Growth of bar [i] given the 30ms stagger / 300ms per bar timeline.
  double _barGrow(int i) {
    if (grow >= 1 || barCount <= 1) return Curves.easeOutCubic.transform(grow.clamp(0, 1));
    final totalMs = 300 + 30 * (barCount - 1);
    final ms = grow * totalMs - 30 * i;
    return Curves.easeOutCubic.transform((ms / 300).clamp(0, 1));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = series.length;
    if (n == 0) return;
    const h = 96.0;
    const gap = 5.0;
    final w = math.max(1.0, (size.width - gap * (n - 1)) / n);
    final maxTotal = series.fold<int>(0, (m, b) => math.max(m, b.total));
    double x(int i) => (rtl ? n - 1 - i : i) * (w + gap);

    for (var i = 0; i < n; i++) {
      final b = series[i];
      final share = maxTotal == 0 ? _minShare : math.max(_minShare, b.total / maxTotal);
      final barH = h * share * _barGrow(i);
      if (barH <= 0) continue;
      final rect = Rect.fromLTWH(x(i), h - barH, w, barH);
      final radius = math.min(5.0, w / 2);
      final rr = RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(math.min(2.0, w / 2)),
        bottomRight: Radius.circular(math.min(2.0, w / 2)),
      );
      final color = b.isFuture ? future : (b.isCurrent ? current : past);
      final paint = Paint()..color = selected != null && selected != i ? color.withValues(alpha: color.a * 0.55) : color;
      canvas.drawRRect(rr, paint);

      if (showAi && !b.isFuture && b.total > 0 && b.ai > 0) {
        final aiH = barH * (b.ai / b.total).clamp(0.0, 1.0);
        canvas.save();
        canvas.clipRRect(rr);
        canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, w, aiH), Paint()..color = ai);
        canvas.restore();
      }
    }

    // X labels, centred under their bar and kept inside the canvas.
    for (final i in labelIndices) {
      if (i < 0 || i >= n) continue;
      final tp = TextPainter(
        text: TextSpan(text: series[i].label, style: labelStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      final cx = x(i) + w / 2;
      final left = (cx - tp.width / 2).clamp(0.0, math.max(0.0, size.width - tp.width)).toDouble();
      tp.paint(canvas, Offset(left, h + 6));
    }

    // Scrub tooltip: fade + scale 0.95 → 1.
    final sel = selected;
    if (sel != null && sel < n && tipText != null && tipProgress > 0) {
      final tp = TextPainter(
        text: TextSpan(text: tipText, style: tipStyle),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(0.0, size.width - 20));
      const padH = 10.0, padV = 6.0;
      final bw = tp.width + padH * 2;
      final bh = tp.height + padV * 2;
      final cx = x(sel) + w / 2;
      final left = (cx - bw / 2).clamp(0.0, math.max(0.0, size.width - bw)).toDouble();
      const top = 0.0;
      final scale = 0.95 + 0.05 * tipProgress;
      final center = Offset(left + bw / 2, top + bh / 2);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(scale);
      canvas.translate(-center.dx, -center.dy);
      canvas.saveLayer(
        Rect.fromLTWH(left, top, bw, bh).inflate(2),
        Paint()..color = Color.fromRGBO(0, 0, 0, tipProgress.clamp(0.0, 1.0)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, top, bw, bh), const Radius.circular(8)),
        Paint()..color = tipBg,
      );
      tp.paint(canvas, Offset(left + padH, top + padV));
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.series != series ||
      old.grow != grow ||
      old.showAi != showAi ||
      old.rtl != rtl ||
      old.selected != selected ||
      old.tipProgress != tipProgress ||
      old.tipText != tipText ||
      old.past != past ||
      old.current != current ||
      old.future != future ||
      old.labelIndices.length != labelIndices.length;
}
