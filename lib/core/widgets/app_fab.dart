import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// §8.20. 56 circle, `primary`, white 24 icon, primary glow. Hides on scroll
/// down and shows on scroll up (200ms slide; fade under reduce-motion).
/// Use [AppFab.extended] only on empty states.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.visible = true,
  }) : label = null;

  const AppFab.extended({
    super.key,
    required this.icon,
    required this.onPressed,
    required String this.label,
    this.visible = true,
  }) : semanticLabel = label;

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? label;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);

    final button = Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        excludeFromSemantics: true,
        child: Container(
          height: 56,
          constraints: const BoxConstraints(minWidth: 56),
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: context.shadows.primaryGlow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: label == null ? 16 : 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 24, color: c.onPrimary),
                    if (label != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(label!, style: context.text.buttonMedium.copyWith(color: c.onPrimary)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (reduced) {
      return AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.normal,
        child: IgnorePointer(ignoring: !visible, child: button),
      );
    }
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 2),
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      child: IgnorePointer(ignoring: !visible, child: button),
    );
  }
}
