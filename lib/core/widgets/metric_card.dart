import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// §8.21 metric card: `surface`, radius 18, padding 12/14. Label `caption` →
/// value `metricValue` (tabular) → delta `caption` in success/error. The
/// alert variant uses the `error` container with a rose border.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaPositive = true,
    this.icon,
    this.alert = false,
    this.onTap,
  });

  final String label;
  final String value;

  /// Already formatted ("+12%").
  final String? delta;

  /// Whether the delta is good news (green) or bad (red).
  final bool deltaPositive;
  final IconData? icon;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final fg = alert ? c.textError : c.textPrimary;
    return Semantics(
      button: onTap != null,
      label: [label, value, ?delta].join('، '),
      excludeSemantics: true,
      child: Material(
        color: alert ? c.errorContainer : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: alert ? c.metricAlertBorder : c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: alert ? c.textError : c.textSecondary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        label,
                        style: t.caption.copyWith(color: alert ? c.textError : c.textSecondary),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: t.metricValue.copyWith(color: fg)),
                if (delta != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        deltaPositive ? AppIcons.trendUp : AppIcons.trendDown,
                        size: 14,
                        color: deltaPositive ? c.textSuccess : c.textError,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          delta!,
                          style: t.caption.copyWith(color: deltaPositive ? c.textSuccess : c.textError),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
