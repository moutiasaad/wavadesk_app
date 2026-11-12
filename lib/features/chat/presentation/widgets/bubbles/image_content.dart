import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/media_download.dart';
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

/// Loading skeleton for a photo bubble: light surface with diagonal stripes
/// drifting slowly (still under reduced motion) and a centered label.
class ImageSkeleton extends StatefulWidget {
  const ImageSkeleton({super.key, required this.label});

  final String label;

  @override
  State<ImageSkeleton> createState() => _ImageSkeletonState();
}

class _ImageSkeletonState extends State<ImageSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      label: widget.label,
      child: CustomPaint(
        painter: _StripesPainter(
          drift: _drift,
          background: c.surfaceVariant,
          stripe: c.border.withValues(alpha: c.isDark ? 0.5 : 0.55),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: t.bodySmall.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  _StripesPainter({required this.drift, required this.background, required this.stripe}) : super(repaint: drift);

  final Animation<double> drift;
  final Color background;
  final Color stripe;

  static const _period = 22.0; // stripe + gap, measured along the x axis
  static const _band = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = stripe;
    final shift = drift.value * _period;
    // 45° bands: each is a parallelogram leaning by the box height.
    for (var x = -size.height - _period + shift; x < size.width; x += _period) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + _band, size.height)
        ..lineTo(x + _band + size.height, 0)
        ..lineTo(x + size.height, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.background != background || old.stripe != stripe;
}

/// Single image (Chat spec §4.4): 4dp padding, radius 14, aspect kept,
/// max 240×320, caption below; tap → full-screen viewer (with save). Own
/// images show from memory at once; others load from the signed media
/// link. An incoming WhatsApp photo the server is still fetching shows a
/// spinner until the poll says it is available; load errors retry by
/// themselves a few times, then tap to retry.
class ImageContent extends ConsumerStatefulWidget {
  const ImageContent({super.key, required this.message, required this.foreground});

  final Message message;
  final Color foreground;

  @override
  ConsumerState<ImageContent> createState() => _ImageContentState();
}

class _ImageContentState extends ConsumerState<ImageContent> {
  static const _width = 240.0;
  static const _autoRetries = 3;

  /// How long an incoming photo may stay "not available yet" before we
  /// call it unavailable (the server fetches it from WhatsApp in seconds).
  static const _fetchWindow = Duration(minutes: 3);

  int _retries = 0;
  Timer? _retryTimer;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    if (_retryTimer != null || _retries >= _autoRetries) return;
    _retryTimer = Timer(Duration(seconds: 2 + 2 * _retries), () {
      _retryTimer = null;
      _retries++;
      if (mounted) ref.invalidate(mediaUrlProvider(widget.message.id));
    });
  }

  void _manualRetry() {
    _retries = 0;
    ref.invalidate(mediaUrlProvider(widget.message.id));
  }

  Future<void> _save() async {
    final l = context.l10n;
    final m = widget.message;
    try {
      final bytes = await downloadMessageMedia(ref, m.id);
      final name = 'wavadesk_${m.sentAt.millisecondsSinceEpoch}.jpg';
      if (await saveToDevice(name, bytes) && mounted) {
        AppSnackbar.show(context, message: l.bubble_saved(name), kind: SnackKind.success);
      }
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: l.bubble_save_failed, kind: SnackKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final m = widget.message;
    final tag = 'img-${m.id}';
    final bytes = LocalMedia.of(m.id);
    final onServer = hasServerMedia(m.id);
    final fetching = bytes == null && onServer && !m.mediaAvailable && DateTime.now().difference(m.sentAt) < _fetchWindow;
    final unavailable = bytes == null && onServer && !m.mediaAvailable && !fetching;

    ImageProvider? provider;
    var failed = false;
    if (bytes != null) {
      provider = MemoryImage(bytes);
    } else if (onServer && m.mediaAvailable) {
      switch (ref.watch(mediaUrlProvider(m.id))) {
        case AsyncData(:final value):
          provider = NetworkImage(value);
        case AsyncError():
          failed = _retries >= _autoRetries;
          _scheduleRetry();
        default:
      }
    }

    Widget placeholder({IconData? icon, String? label, VoidCallback? onTap}) => SizedBox(
          width: _width,
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaPlaceholder(seed: m.id, icon: null),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon == null)
                      AppSpinner(size: 24, delayed: false, color: Colors.white.withValues(alpha: 0.9))
                    else
                      AppIcon(icon, dp: 28, color: Colors.white.withValues(alpha: 0.9)),
                    if (label != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(label, style: t.caption.copyWith(color: Colors.white), textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

    Widget skeleton() => SizedBox(
          width: _width,
          height: 180,
          child: ImageSkeleton(label: fetching ? l.bubble_photo_fetching : l.media_image),
        );

    final Widget picture;
    if (provider != null) {
      picture = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _width, minWidth: 120, maxHeight: 320, minHeight: 80),
        child: Image(
          image: provider,
          width: _width,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (_, child, frame, sync) => sync || frame != null ? child : skeleton(),
          errorBuilder: (_, _, _) {
            // A refused / expired link: get a fresh one.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scheduleRetry();
            });
            return placeholder(icon: AppIcons.retry, label: l.bubble_tap_retry);
          },
        ),
      );
    } else if (unavailable) {
      picture = placeholder(icon: AppIcons.image, label: l.bubble_photo_unavailable);
    } else if (failed) {
      picture = placeholder(icon: AppIcons.retry, label: l.bubble_tap_retry);
    } else {
      picture = skeleton();
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: provider == null
                ? (failed ? _manualRetry : null)
                : () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        opaque: false,
                        transitionDuration: AppMotion.normal,
                        reverseTransitionDuration: AppMotion.normal,
                        pageBuilder: (_, _, _) => ImageViewerScreen(
                          heroTag: tag,
                          seed: m.id,
                          caption: m.text,
                          image: provider,
                          onSave: _save,
                        ),
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
          if (m.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: SizedBox(
                width: _width - 16,
                child: TextContent(text: m.text, color: widget.foreground),
              ),
            ),
        ],
      ),
    );
  }
}
