import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_surface.dart';

/// §8.21 toggle: 48×29 track, thumb 23, on `primary`, off `borderStrong`.
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, required this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // On the brand header: white track when on, translucent when off.
    final brand = BrandSurface.of(context);
    final track = brand ? (value ? Colors.white : Colors.white.withValues(alpha: 0.3)) : (value ? c.primary : c.borderStrong);
    final thumb = brand && value ? c.primary : Colors.white;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Opacity(
          opacity: onChanged == null ? 0.4 : 1,
          child: SizedBox(
            width: 52,
            height: AppSpacing.minTouch,
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                width: 48,
                height: 29,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: AnimatedAlign(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: thumb,
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Color(0x290F172A), blurRadius: 3, offset: Offset(0, 1))],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// §8.21 radio: 22 circle; selected = 7dp `primary` ring.
class AppRadio extends StatelessWidget {
  const AppRadio({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: AppMotion.fast,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surface,
        border: Border.all(color: selected ? c.primary : c.borderStrong, width: selected ? 7 : 1.5),
      ),
    );
  }
}

/// Radio row; selected row bg `primaryContainer` (§8.21).
class AppRadioRow extends StatelessWidget {
  const AppRadioRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? c.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: t.listTitle),
                      if (subtitle != null) Text(subtitle!, style: t.bodySmall.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                AppRadio(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// §8.21 checkbox: 20, radius 6, `primary` fill.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, this.onChanged, this.circle = false});

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Circular variant (multi-select check that replaces the avatar).
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = circle ? 26.0 : 20.0;
    final box = AnimatedContainer(
      duration: AppMotion.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: value ? c.primary : c.surface,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: value ? c.primary : c.borderStrong, width: 1.5),
      ),
      child: value ? AppIcon(AppIcons.check, dp: size * 0.7, color: c.onPrimary) : null,
    );
    if (onChanged == null) return Semantics(checked: value, child: box);
    return Semantics(
      checked: value,
      child: InkResponse(
        onTap: () => onChanged!(!value),
        radius: 24,
        child: SizedBox.square(
          dimension: AppSpacing.minTouch,
          child: Center(child: box),
        ),
      ),
    );
  }
}
