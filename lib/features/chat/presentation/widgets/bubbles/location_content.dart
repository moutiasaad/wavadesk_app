import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// Location (Chat spec §4.4): static map 240×140 radius 12 + address line;
/// tap → maps. The map is drawn (no tile provider in sample data).
class LocationContent extends StatelessWidget {
  const LocationContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final address = message.locationLabel ?? message.text;
    return Semantics(
      button: true,
      label: '${context.l10n.media_location}: $address',
      hint: context.l10n.bubble_open_maps,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}'),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(width: 240, height: 140, child: CustomPaint(painter: _MapPainter(c))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: SizedBox(
                  width: 228,
                  child: Row(
                    children: [
                      AppIcon(AppIcons.location, size: AppIconSize.sm, color: foreground.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: context.text.bodySmall.copyWith(color: foreground),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

class _MapPainter extends CustomPainter {
  _MapPainter(this.c);

  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = c.isDark ? const Color(0xFF1A2428) : const Color(0xFFE8EEF0));
    final block = Paint()..color = c.isDark ? const Color(0xFF202C31) : const Color(0xFFF4F7F8);
    final road = Paint()
      ..color = c.isDark ? const Color(0xFF2C3A40) : Colors.white
      ..strokeWidth = 7;
    final minor = Paint()
      ..color = c.isDark ? const Color(0xFF26333A) : const Color(0xFFFFFFFF)
      ..strokeWidth = 3;
    for (var x = 0.0; x < size.width; x += 48) {
      for (var y = 0.0; y < size.height; y += 36) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, y + 6, 36, 24), const Radius.circular(3)), block);
      }
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
    canvas.drawLine(Offset(0, size.height * 0.62), Offset(size.width, size.height * 0.38), road);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.55, size.height), road);
    // Park
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.78),
      18,
      Paint()..color = c.success.withValues(alpha: 0.25),
    );
    // Pin
    final center = Offset(size.width / 2, size.height / 2 - 8);
    final pin = Path()
      ..moveTo(center.dx, center.dy + 18)
      ..quadraticBezierTo(center.dx - 13, center.dy + 2, center.dx - 11, center.dy - 6)
      ..arcToPoint(Offset(center.dx + 11, center.dy - 6), radius: const Radius.circular(11))
      ..quadraticBezierTo(center.dx + 13, center.dy + 2, center.dx, center.dy + 18)
      ..close();
    canvas.drawShadow(pin, Colors.black, 3, false);
    canvas.drawPath(pin, Paint()..color = c.error);
    canvas.drawCircle(Offset(center.dx, center.dy - 5), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.c != c;
}
