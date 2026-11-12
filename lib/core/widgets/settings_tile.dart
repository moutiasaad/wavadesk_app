import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'app_skeleton.dart';

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
    this.valueColor,
    this.subtitleColor,
    this.locked = false,
    this.iconBadge,
    this.valueLoading = false,
    this.semanticValue,
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

  /// Status values in color ("متصل" green, "غير متصل" red).
  final Color? valueColor;
  final Color? subtitleColor;

  /// Grey title, lock instead of the chevron (no permission).
  final bool locked;

  /// 8dp dot on the icon tile corner (e.g. red: WhatsApp disconnected).
  final Color? iconBadge;

  /// 60×12 shimmer bar in place of [value] while it loads.
  final bool valueLoading;

  /// Read after the title ("{title}، {value}"); defaults to [value].
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final big = MediaQuery.textScalerOf(context).scale(10) >= 20;
    final valueText = value == null
        ? null
        : Text(
            value!,
            style: t.bodySmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? c.textSecondary,
            ),
            textDirection: valueDirection,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
    final loadingBar = valueLoading ? const AppSkeleton(child: SkeletonBox(width: 60, height: 12)) : null;
    final a11yValue = semanticValue ?? value;
    // One node "{title}، {value}" — except rows with their own control
    // (switch…), which must stay reachable.
    final merged = trailing == null;
    return Semantics(
      button: onTap != null,
      label: merged ? [title, ?a11yValue, if (locked) context.l10n.common_locked].join('، ') : null,
      excludeSemantics: merged,
      child: InkWell(
        onTap: onTap,
        highlightColor: c.backgroundMuted,
        splashColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          child: Row(
            children: [
              if (icon != null) ...[
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: iconBackground ?? c.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AppIcon(icon, dp: 18, color: iconColor ?? c.primary),
                    ),
                    if (iconBadge != null)
                      PositionedDirectional(
                        top: -2,
                        end: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: iconBadge,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.listTitle.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: destructive ? c.textError : (locked ? c.textTertiary : c.textPrimary),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor ?? c.textSecondary,
                        ),
                      ),
                    // 200% text: the value moves under the title.
                    if (big && trailing == null && (valueText != null || loadingBar != null))
                      Padding(padding: const EdgeInsets.only(top: 2), child: loadingBar ?? valueText),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                // Not Flexible: Expanded + Flexible split the row in half and
                // left short values ("متصل", "العربية") floating mid-row. A
                // capped non-flex child keeps every value against the chevron.
                if (!big && (valueText != null || loadingBar != null))
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                      child: loadingBar ?? valueText,
                    ),
                  ),
                if (locked) ...[
                  const SizedBox(width: AppSpacing.xs),
                  AppIcon(AppIcons.lock, dp: 14, color: c.textTertiary),
                ] else if (showChevron && onTap != null) ...[
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
              child: Text(
                title!,
                style: t.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textSecondary),
              ),
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
                  // Inset from the text start, not under the icon tile.
                  if (i > 0) Divider(height: 1, indent: 60, endIndent: 0, color: c.divider),
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
