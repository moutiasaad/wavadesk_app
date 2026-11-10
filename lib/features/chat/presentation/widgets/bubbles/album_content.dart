import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../image_viewer_screen.dart';
import 'image_content.dart';
import 'text_content.dart';

/// Album (Chat spec §4.4): 2×2 grid, 240 wide, "+n" overlay on the 4th tile.
class AlbumContent extends StatelessWidget {
  const AlbumContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final count = message.albumCount < 2 ? 2 : message.albumCount;
    final tiles = count >= 4 ? 4 : count;
    final extra = count - 4;
    const gap = 2.0;
    const tile = (240 - gap) / 2;

    Widget cell(int i) {
      final seed = '${message.id}-$i';
      final tag = 'album-$seed';
      return GestureDetector(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder<void>(
            opaque: false,
            transitionDuration: AppMotion.normal,
            pageBuilder: (_, _, _) => ImageViewerScreen(heroTag: tag, seed: seed, caption: message.text),
            transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
          ),
        ),
        child: Hero(
          tag: tag,
          child: SizedBox.square(
            dimension: tile,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaPlaceholder(seed: seed, iconSize: 24),
                if (i == 3 && extra > 0)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Text('+$extra', style: context.text.h3.copyWith(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: SizedBox(
              width: 240,
              child: Wrap(spacing: gap, runSpacing: gap, children: [for (var i = 0; i < tiles; i++) cell(i)]),
            ),
          ),
          if (message.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: SizedBox(
                width: 224,
                child: TextContent(text: message.text, color: foreground),
              ),
            ),
        ],
      ),
    );
  }
}
