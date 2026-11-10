import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_spinner.dart';

enum AppButtonVariant { primary, secondary, tonal, dark, text, destructive, destructiveFilled }

enum AppButtonSize { large, medium, small }

/// §8.11. Pressed colors are explicit per variant (no generic ripple tint).
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.height,
    this.semanticLabel,
    this.textStyle,
    this.horizontalPadding,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;

  /// Full width (primary screen actions).
  final bool expand;

  /// Overrides the size's height (e.g. 46 for the Claim bar's secondary).
  final double? height;
  final String? semanticLabel;

  /// Overrides size + weight of the label (color still comes from the variant).
  final TextStyle? textStyle;
  final double? horizontalPadding;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  ({double height, double radius, double padding, double icon, TextStyle style}) _metrics(BuildContext context) {
    final t = context.text;
    return switch (widget.size) {
      AppButtonSize.large => (height: 52, radius: AppRadius.lg, padding: 20, icon: 20, style: t.buttonLarge),
      AppButtonSize.medium => (height: 44, radius: AppRadius.md, padding: 16, icon: 18, style: t.buttonMedium),
      AppButtonSize.small => (height: 34, radius: 10, padding: 12, icon: 16, style: t.buttonSmall),
    };
  }

  ({Color bg, Color fg, Color? border, Color pressed}) _palette(AppColors c) {
    return switch (widget.variant) {
      AppButtonVariant.primary => (bg: c.primary, fg: c.onPrimary, border: null, pressed: c.primaryPressed),
      AppButtonVariant.secondary => (bg: c.surface, fg: c.textPrimary, border: c.border, pressed: c.surfaceVariant),
      AppButtonVariant.tonal => (
        bg: c.primaryContainer,
        fg: c.onPrimaryContainer,
        border: c.primaryContainerBorder,
        pressed: Color.lerp(c.primaryContainer, Colors.black, 0.04)!,
      ),
      AppButtonVariant.dark => (
        bg: c.secondary,
        fg: c.onSecondary,
        border: null,
        pressed: c.secondary.withValues(alpha: 0.85),
      ),
      AppButtonVariant.text => (bg: Colors.transparent, fg: c.primary, border: null, pressed: c.primaryContainer),
      AppButtonVariant.destructive => (bg: c.surface, fg: c.textError, border: c.border, pressed: c.errorContainer),
      AppButtonVariant.destructiveFilled => (
        bg: c.error,
        fg: Colors.white,
        border: null,
        pressed: Color.lerp(c.error, Colors.black, 0.08)!,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics(context);
    final p = _palette(context.colors);
    final enabled = widget.onPressed != null && !widget.loading;
    final height = widget.height ?? m.height;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[AppIcon(widget.icon, dp: m.icon, color: p.fg), const SizedBox(width: 7)],
        Flexible(
          child: Text(
            widget.label,
            style: m.style.merge(widget.textStyle).copyWith(color: p.fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    Widget child = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      constraints: BoxConstraints(minHeight: height, minWidth: height),
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding ?? m.padding),
      decoration: BoxDecoration(
        color: _pressed && enabled ? p.pressed : p.bg,
        borderRadius: BorderRadius.circular(m.radius),
        border: p.border == null ? null : Border.all(color: p.border!),
      ),
      // Hug the label (centered vertically in the min height); only `expand`
      // buttons fill the width. A Container `alignment` would always fill.
      child: Align(
        widthFactor: widget.expand ? null : 1,
        heightFactor: 1,
        // Label and spinner cross-fade (150ms); the label keeps its slot so the
        // button width never changes while loading.
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(opacity: widget.loading ? 0 : 1, duration: AppMotion.fast, child: label),
            AnimatedOpacity(
              opacity: widget.loading ? 1 : 0,
              duration: AppMotion.fast,
              child: AppSpinner(size: 18, color: p.fg, delayed: false),
            ),
          ],
        ),
      ),
    );

    if (widget.expand) child = SizedBox(width: double.infinity, child: child);

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: Opacity(
        opacity: widget.onPressed == null ? 0.4 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          // 48dp minimum hit area even for 34/44dp visuals (§11).
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
            child: Align(widthFactor: 1, heightFactor: 1, child: child),
          ),
        ),
      ),
    );
  }
}
