import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/l10n.dart';

/// §8.9 icon form: 14×14, three bars (2dp wide, 4/8/12 high, gap 2).
/// Urgent shows a filled flag. Low is hidden in lists — callers skip it.
class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = priority.color(c);
    final label = context.l10n.a11y_priority(priority.label(context.l10n));

    if (priority == Priority.urgent) {
      return Semantics(
        label: label,
        child: SizedBox.square(dimension: 14, child: CustomPaint(painter: _FlagPainter(color))),
      );
    }

    return Semantics(
      label: label,
      child: SizedBox.square(
        dimension: 14,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Container(
                width: 2,
                height: 4.0 + i * 4,
                margin: const EdgeInsets.only(bottom: 1),
                decoration: BoxDecoration(
                  color: i < priority.bars ? color : c.borderStrong,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pole = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.22, h * 0.1), Offset(w * 0.22, h * 0.92), pole);
    final flag = Path()
      ..moveTo(w * 0.22, h * 0.12)
      ..quadraticBezierTo(w * 0.5, h * 0.02, w * 0.62, h * 0.14)
      ..quadraticBezierTo(w * 0.76, h * 0.26, w * 0.88, h * 0.14)
      ..lineTo(w * 0.88, h * 0.58)
      ..quadraticBezierTo(w * 0.76, h * 0.70, w * 0.62, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 0.46, w * 0.22, h * 0.56)
      ..close();
    canvas.drawPath(flag, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.color != color;
}
