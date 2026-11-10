import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../image_viewer_screen.dart';
import 'text_content.dart';

/// Deterministic placeholder artwork for sample images (no real URLs).
class MediaPlaceholder extends StatelessWidget {
  const MediaPlaceholder({super.key, required this.seed, this.icon = AppIcons.image, this.iconSize = 32});

  final String seed;

  /// Null → no glyph (e.g. under a video play button).
  final IconData? icon;
  final double iconSize;

  static double hue(String seed) {
    var h = 0;
    for (final u in seed.codeUnits) {
      h = (h * 31 + u) & 0x7fffffff;
    }
    return (h % 360).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.isDark;
    final h = hue(seed);
    final a = HSLColor.fromAHSL(1, h, 0.45, dark ? 0.28 : 0.78).toColor();
    final b = HSLColor.fromAHSL(1, (h + 40) % 360, 0.5, dark ? 0.18 : 0.62).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
      ),
      child: icon == null
          ? null
          : Center(
              child: AppIcon(icon, dp: iconSize, color: Colors.white.withValues(alpha: 0.85)),
            ),
    );
  }
}

/// Single image (Chat spec §4.4): 4dp padding, radius 14, aspect kept,
/// max 240×320, caption below; tap → full-screen viewer.
class ImageContent extends StatelessWidget {
  const ImageContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tall = MediaPlaceholder.hue(message.id) > 180;
    final size = tall ? const Size(240, 300) : const Size(240, 180);
    final tag = 'img-${message.id}';
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder<void>(
                opaque: false,
                transitionDuration: AppMotion.normal,
                reverseTransitionDuration: AppMotion.normal,
                pageBuilder: (_, _, _) => ImageViewerScreen(heroTag: tag, seed: message.id, caption: message.text),
                transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
              ),
            ),
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox.fromSize(
                  size: size,
                  child: MediaPlaceholder(seed: message.id),
                ),
              ),
            ),
          ),
          if (message.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: SizedBox(
                width: size.width - 16,
                child: TextContent(text: message.text, color: foreground),
              ),
            ),
        ],
      ),
    );
  }
}
