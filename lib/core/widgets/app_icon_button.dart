import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppIconButtonVariant { plain, filled, outlined, primary }

/// §8.11 icon buttons. All circular; visual 40 (44 for primary) inside a
/// 48dp hit area. Every instance needs a [semanticLabel] (§11).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.variant = AppIconButtonVariant.plain,
    this.size,
    this.iconSize,
    this.iconColor,
    this.background,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final AppIconButtonVariant variant;

  /// Visual diameter. Defaults to 40 (44 for [AppIconButtonVariant.primary]).
  final double? size;
  final double? iconSize;
  final Color? iconColor;
  final Color? background;

  /// Overlay at the top-end corner (notification dot).
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = size ?? (variant == AppIconButtonVariant.primary ? 44.0 : 40.0);
    final (Color bg, Color fg, Border? border) = switch (variant) {
      AppIconButtonVariant.plain => (Colors.transparent, c.textPrimary, null),
      AppIconButtonVariant.filled => (c.surfaceVariant, c.textPrimary, null),
      AppIconButtonVariant.outlined => (c.surface, c.textPrimary, Border.all(color: c.border)),
      AppIconButtonVariant.primary => (c.primary, c.onPrimary, null),
    };
    final hit = d < AppSpacing.minTouch ? AppSpacing.minTouch : d;

    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: SizedBox.square(
          dimension: hit,
          child: Center(
            child: Opacity(
              opacity: onPressed == null ? 0.4 : 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: background ?? bg,
                    shape: CircleBorder(side: border?.top ?? BorderSide.none),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onPressed,
                      child: SizedBox.square(
                        dimension: d,
                        child: Icon(icon, size: iconSize ?? 20, color: iconColor ?? fg),
                      ),
                    ),
                  ),
                  if (badge != null) PositionedDirectional(top: 6, end: 7, child: badge!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 9dp `error` dot with a 2dp `background` ring (§8.1 notifications).
class NotificationDot extends StatelessWidget {
  const NotificationDot({super.key, this.ringColor});

  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        color: c.error,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? c.background, width: 2),
      ),
    );
  }
}
