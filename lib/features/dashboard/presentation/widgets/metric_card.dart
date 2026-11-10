import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum MetricVariant { normal, alert, tonal }

/// Dashboard metric tile (spec §4.4, DS §8.21): label → value + aside on one
/// baseline row. `alert` = rose card, `tonal` = primary container (AI).
class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.display,
    this.aside,
    this.asideColor,
    this.asideIcon,
    this.labelIcon,
    this.variant = MetricVariant.normal,
    this.countUp = false,
    this.flash = false,
    this.semanticLabel,
    this.onTap,
  });

  final String label;

  /// Numeric value for the count-up; [display] formats it.
  final num value;
  final String Function(num v) display;
  final String? aside;
  final Color? asideColor;
  final IconData? asideIcon;
  final IconData? labelIcon;
  final MetricVariant variant;

  /// First load only (§4.4); off with reduce motion.
  final bool countUp;

  /// Live update: 300ms primaryContainer flash behind the number (§8).
  final bool flash;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final reduced = AppMotion.reduced(context);

    final (bg, border, fg, labelFg) = switch (variant) {
      MetricVariant.alert => (
          c.isDark ? const Color(0xFF2E1219) : const Color(0xFFFFF7F8),
          c.isDark ? const Color(0xFF5B1F2C) : const Color(0xFFFECDD3),
          c.isDark ? const Color(0xFFFB7185) : c.textError,
          c.isDark ? const Color(0xFFFB7185) : c.textError,
        ),
      MetricVariant.tonal => (
          c.isDark ? const Color(0xFF0F2E2D) : c.primaryContainer,
          c.isDark ? const Color(0xFF1D4A47) : c.primaryContainerBorder,
          c.isDark ? const Color(0xFF9FE3DC) : c.onPrimaryContainer,
          c.isDark ? const Color(0xFF9FE3DC) : c.onPrimaryContainer,
        ),
      MetricVariant.normal => (c.surface, c.border, c.textPrimary, c.textSecondary),
    };
    final asideFg = variant == MetricVariant.tonal ? fg : (asideColor ?? c.textSecondary);

    Widget number(num v) => Text(display(v), style: t.metricValue.copyWith(color: fg), maxLines: 1);

    final valueWidget = countUp && !reduced
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => number(value is int ? v.round() : v),
          )
        : AnimatedSwitcher(
            duration: reduced ? Duration.zero : AppMotion.fast,
            child: KeyedSubtree(key: ValueKey(display(value)), child: number(value)),
          );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (labelIcon != null) ...[
                      AppIcon(labelIcon, size: AppIconSize.xs, color: labelFg),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: t.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: labelFg),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  children: [
                    AnimatedContainer(
                      duration: reduced ? Duration.zero : AppMotion.slow,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: flash && !reduced ? c.primaryContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: valueWidget,
                    ),
                    if (aside != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (asideIcon != null) ...[
                              AppIcon(asideIcon, size: AppIconSize.xs, color: asideFg),
                              const SizedBox(width: 2),
                            ],
                            Text(aside!, style: t.caption.copyWith(fontSize: 12, color: asideFg)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
