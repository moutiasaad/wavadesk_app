import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/media_url_provider.dart';
import '../../../data/local_media.dart';
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
/// max 240×320, caption below; tap → full-screen viewer. Own images show
/// from memory at once; others load from the signed media link.
class ImageContent extends ConsumerWidget {
  const ImageContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  static const _width = 240.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tag = 'img-${message.id}';
    final bytes = LocalMedia.of(message.id);
    final ImageProvider? provider = bytes != null
        ? MemoryImage(bytes)
        : hasServerMedia(message.id)
            ? switch (ref.watch(mediaUrlProvider(message.id))) {
                AsyncData(:final value) => NetworkImage(value),
                _ => null,
              }
            : null;
    final failed = bytes == null && hasServerMedia(message.id) && ref.watch(mediaUrlProvider(message.id)).hasError;

    Widget placeholder({bool error = false}) => SizedBox(
          width: _width,
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPlaceholder(seed: message.id, icon: error ? AppIcons.image : null),
              if (!error) Center(child: AppSpinner(size: 24, delayed: false, color: Colors.white.withValues(alpha: 0.9))),
            ],
          ),
        );

    final Widget picture = provider == null
        ? placeholder(error: failed || !hasServerMedia(message.id) && bytes == null)
        : ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _width, minWidth: 120, maxHeight: 320, minHeight: 80),
            child: Image(
              image: provider,
              width: _width,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : placeholder(),
              errorBuilder: (_, _, _) => placeholder(error: true),
            ),
          );

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: provider == null
                ? (failed ? () => ref.invalidate(mediaUrlProvider(message.id)) : null)
                : () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        opaque: false,
                        transitionDuration: AppMotion.normal,
                        reverseTransitionDuration: AppMotion.normal,
                        pageBuilder: (_, _, _) =>
                            ImageViewerScreen(heroTag: tag, seed: message.id, caption: message.text, image: provider),
                        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
                      ),
                    ),
            child: Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: ColoredBox(color: c.surfaceVariant, child: picture),
              ),
            ),
          ),
          if (message.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: SizedBox(
                width: _width - 16,
                child: TextContent(text: message.text, color: foreground),
              ),
            ),
        ],
      ),
    );
  }
}
