import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// §8.21 settings row: 34 icon tile (radius 10, tinted by meaning) · title
/// `listTitle` 14.5 + subtitle `bodySmall` · trailing value + mirrored
/// chevron 16 `borderStrong`.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.iconBackground,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.destructive = false,
    this.valueDirection,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String? subtitle;

  /// Trailing value text ("فاتح", "العربية").
  final String? value;

  /// Replaces value + chevron (switch, badge…).
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool destructive;

  /// Force LTR for phone numbers / emails in [value].
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBackground ?? c.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AppIcon(icon, dp: 18, color: iconColor ?? c.primary),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.listTitle.copyWith(fontSize: 14.5, color: destructive ? c.textError : c.textPrimary),
                    ),
                    if (subtitle != null) Text(subtitle!, style: t.bodySmall.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                // Not Flexible: Expanded + Flexible split the row in half and
                // left short values ("متصل", "العربية") floating mid-row. A
                // capped non-flex child keeps every value against the chevron.
                if (value != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.45),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                      child: Text(
                        value!,
                        style: t.bodySmall.copyWith(color: c.textSecondary),
                        textDirection: valueDirection,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (showChevron && onTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// §8.21 grouped list: `surface`, radius 18, 1dp `border`, 16 horizontal
/// margin. Section header `caption` `textSecondary` (16 top, 6 bottom, 22
/// start — §5).
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children, this.title, this.footer});

  final String? title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22, end: 22, top: AppSpacing.lg, bottom: 6),
            child: Semantics(
              header: true,
              child: Text(title!, style: t.caption.copyWith(color: c.textSecondary)),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 60, color: c.divider),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 22, end: 22, top: 6),
            child: Text(footer!, style: t.bodySmall.copyWith(color: c.textTertiary)),
          ),
      ],
    );
  }
}
