import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// §8.13. Height 32, pill. Selected = ink (`secondary`), not teal — teal is
/// reserved for actions. Use [AppFilterChip.tonal] for non-interactive tags.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.leading,
    this.trailingIcon,
    this.onDeleted,
  }) : _tonal = false;

  const AppFilterChip.tonal({super.key, required this.label, this.leading})
    : selected = false,
      onTap = null,
      count = null,
      trailingIcon = null,
      onDeleted = null,
      _tonal = true;

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Shown as " · 4".
  final int? count;
  final Widget? leading;

  /// e.g. chevron-down for dropdown chips ("القناة ▾").
  final IconData? trailingIcon;

  /// Dismissible active-filter chip.
  final VoidCallback? onDeleted;
  final bool _tonal;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color bg, Color fg, Color? border) = _tonal
        ? (c.primaryContainer, c.onPrimaryContainer, null)
        : selected
        ? (c.secondary, c.onSecondary, null)
        : (c.surface, c.textSecondary, c.border);

    final chip = AnimatedContainer(
      duration: AppMotion.fast,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            count == null ? label : '$label · $count',
            style: context.text.chipLabel.copyWith(color: fg),
            maxLines: 1,
          ),
          if (trailingIcon != null) ...[const SizedBox(width: AppSpacing.xs), Icon(trailingIcon, size: 14, color: fg)],
          if (onDeleted != null) ...[const SizedBox(width: AppSpacing.xs), Icon(AppIcons.close, size: 14, color: fg)],
        ],
      ),
    );

    if (_tonal) return chip;

    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : '$label $count',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onDeleted ?? onTap,
        // Keep the 48dp hit target while the chip stays 32 visually.
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: chip),
      ),
    );
  }
}

/// Horizontally scrollable chip row: 16 start/end padding, 8 gap, no
/// scrollbar (§8.13).
class AppChipRow extends StatelessWidget {
  const AppChipRow({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: AppSpacing.sm), children[i]],
          ],
        ),
      ),
    );
  }
}
