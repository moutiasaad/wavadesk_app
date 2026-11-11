import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import 'bubbles/image_content.dart';

/// Full-screen image viewer (Chat spec §4.4): pinch to zoom, swipe down to
/// close, share / save. Sample images are drawn placeholders, so share and
/// save explain that instead of acting.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.heroTag, required this.seed, this.caption = '', this.image, this.onSave});

  /// Saves the picture on the phone; null → the sample explanation.
  final Future<void> Function()? onSave;

  /// The real picture; null → the sample placeholder.
  final ImageProvider? image;

  final String heroTag;
  final String seed;
  final String caption;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final _transform = TransformationController();
  double _drag = 0;

  bool get _zoomed => _transform.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fade = (1 - (_drag.abs() / 300)).clamp(0.3, 1.0);
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onVerticalDragUpdate: _zoomed ? null : (d) => setState(() => _drag += d.delta.dy),
              onVerticalDragEnd: _zoomed
                  ? null
                  : (d) {
                      if (_drag.abs() > 120 || (d.primaryVelocity ?? 0).abs() > 900) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _drag = 0);
                      }
                    },
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  child: InteractiveViewer(
                    transformationController: _transform,
                    minScale: 1,
                    maxScale: 4,
                    child: Hero(
                      tag: widget.heroTag,
                      child: widget.image != null
                          ? Image(image: widget.image!, fit: BoxFit.contain)
                          : AspectRatio(
                              aspectRatio: MediaPlaceholder.hue(widget.seed) > 180 ? 4 / 5 : 4 / 3,
                              child: MediaPlaceholder(seed: widget.seed, iconSize: 64),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.xs,
              start: AppSpacing.xs,
              end: AppSpacing.xs,
              child: Opacity(
                opacity: fade,
                child: Row(
                  children: [
                    AppIconButton(
                      icon: AppIcons.close,
                      iconSize: 24,
                      iconColor: Colors.white,
                      semanticLabel: l.common_close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    AppIconButton(
                      icon: AppIcons.share,
                      iconColor: Colors.white,
                      semanticLabel: l.bubble_viewer_share,
                      onPressed: () => AppSnackbar.show(context, message: l.bubble_viewer_sample),
                    ),
                    AppIconButton(
                      icon: AppIcons.download,
                      iconColor: Colors.white,
                      semanticLabel: l.bubble_viewer_save,
                      onPressed: () => widget.onSave != null ? widget.onSave!() : AppSnackbar.show(context, message: l.bubble_viewer_sample),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.caption.trim().isNotEmpty)
              PositionedDirectional(
                start: AppSpacing.lg,
                end: AppSpacing.lg,
                bottom: AppSpacing.xxl,
                child: Opacity(
                  opacity: fade,
                  child: Text(
                    widget.caption,
                    style: context.text.bodyMedium.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
