import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// §8.15 skeletons. `surfaceVariant` blocks with a 1.2s shimmer; the
/// shimmer is disabled under reduce-motion (static skeleton, §11).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, required this.child});

  /// Layout built from [SkeletonBox]es.
  final Widget child;

  /// 8 conversation-row skeletons (avatar + 60% / 85% lines).
  static Widget list({int rows = 8}) =>
      AppSkeleton(child: Column(children: [for (var i = 0; i < rows; i++) const _RowSkeleton()]));

  /// 4 alternating bubble skeletons.
  static Widget chat() => const AppSkeleton(child: _ChatSkeleton());

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: AppMotion.loop);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.surfaceVariant;
    final hi = c.isDark ? c.border : c.background;
    final reduced = AppMotion.reduced(context);

    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _ctrl,
          child: widget.child,
          builder: (context, child) {
            if (reduced) return child!;
            final v = _ctrl.value * 2 - 0.5;
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) => LinearGradient(
                colors: [base, hi, base],
                stops: [(v - 0.3).clamp(0, 1), v.clamp(0, 1), (v + 0.3).clamp(0, 1)],
              ).createShader(rect),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.xs, this.circle = false});

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.surfaceVariant,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    ),
  );
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          const SkeletonBox(width: 50, height: 50, circle: true),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: box.maxWidth * 0.6, height: 12),
                  const SizedBox(height: 10),
                  SkeletonBox(width: box.maxWidth * 0.85, height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    const widths = [0.62, 0.48, 0.7, 0.4];
    return LayoutBuilder(
      builder: (context, box) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < widths.length; i++)
              Align(
                alignment: i.isEven ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SkeletonBox(width: box.maxWidth * widths[i], height: i == 2 ? 64 : 42, radius: AppRadius.xl),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
