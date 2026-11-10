import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/kb_entry.dart';
import '../../domain/kb_subtitle_formatter.dart';

/// Usage card (spec §6.1-3): "استُخدم {n} مرة هذا الشهر · تقييم إيجابي {p}%
/// · آخر استخدام {t}" + 30-day sparkline.
class KbUsageCard extends StatelessWidget {
  const KbUsageCard({super.key, required this.usage});

  final KbUsage usage;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final stats = <String>[
      l.kb_usage_month(usage.month),
      if (usage.thumbsUpRate != null) l.kb_positive((usage.thumbsUpRate! * 100).round()),
      usage.lastUsedAt == null ? l.kb_not_used_yet : l.kb_last_used(KbSubtitleFormatter.span(l, usage.lastUsedAt!)),
    ];
    final daily = usage.daily.length >= 2 ? usage.daily : const <int>[];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              for (var i = 0; i < stats.length; i++)
                Text(
                  stats[i],
                  style: (i == 0 ? t.listTitle.copyWith(fontSize: 14) : t.bodySmall).copyWith(color: i == 0 ? c.textPrimary : c.textSecondary),
                ),
            ],
          ),
          if (daily.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: l.kb_daily_chart,
              child: SizedBox(
                height: 44,
                width: double.infinity,
                child: CustomPaint(painter: _Sparkline(daily, c.primary, c.primaryContainer)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Sparkline extends CustomPainter {
  _Sparkline(this.values, this.color, this.fill);

  final List<int> values;
  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = math.max(1, values.reduce(math.max)).toDouble();
    final dx = size.width / (values.length - 1);
    // Oldest on the reading-start side is handled by the caller's direction;
    // the chart always runs left → right in time (like other charts).
    final pts = [
      for (var i = 0; i < values.length; i++) Offset(i * dx, size.height - 2 - (values[i] / maxV) * (size.height - 4)),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill.withValues(alpha: 0.6));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Sparkline old) => old.values != values || old.color != color;
}
