import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'app_icon_button.dart';

/// §8.17 bottom sheets. `surfaceElevated`, top radius 28, high elevation,
/// grab handle 40×5. Auto height (≤ 60%) for actions; expanded (≤ 92%,
/// draggable) for profile, assign, AI rewrite.
abstract final class AppBottomSheet {
  /// Short action list / picker. Content sizes itself, capped at 60%.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    String? subtitle,
    Widget? action,
    bool showClose = true,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      // Non-dismissible sheets force an explicit choice (no swipe, no scrim tap).
      isDismissible: dismissible,
      enableDrag: dismissible,
      backgroundColor: Colors.transparent,
      barrierColor: context.colors.scrim,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      builder: (ctx) => _SheetFrame(
        title: title,
        subtitle: subtitle,
        action: action,
        showClose: showClose,
        child: Flexible(child: SingleChildScrollView(child: builder(ctx))),
      ),
    );
  }

  /// Tall, draggable sheet (up to 92%). [builder] receives the scroll
  /// controller to attach to its scrollable.
  static Future<T?> showExpanded<T>(
    BuildContext context, {
    required Widget Function(BuildContext context, ScrollController controller) builder,
    String? title,
    String? subtitle,
    Widget? action,
    Widget? headerTrailing,
    double initialSize = 0.92,
    bool showClose = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: context.colors.scrim,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          snap: true,
          builder: (ctx, controller) => _SheetFrame(
            title: title,
            subtitle: subtitle,
            action: action,
            headerTrailing: headerTrailing,
            showClose: showClose,
            fill: true,
            child: Expanded(child: builder(ctx, controller)),
          ),
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.child,
    this.title,
    this.subtitle,
    this.action,
    this.headerTrailing,
    this.showClose = true,
    this.fill = false,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget? headerTrailing;
  final bool showClose;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        boxShadow: context.shadows.high,
      ),
      padding: fill ? null : EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Grab handle 40×5, 8 top / 12 bottom.
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
            child: Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: c.borderStrong, borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xl,
                end: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(header: true, child: Text(title!, style: t.h3)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, style: t.bodySmall.copyWith(color: c.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  ?headerTrailing,
                  if (showClose)
                    AppIconButton(
                      icon: AppIcons.close,
                      variant: AppIconButtonVariant.filled,
                      semanticLabel: context.l10n.common_close,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                ],
              ),
            ),
          child,
          if (action != null)
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl + bottomInset),
              child: action,
            )
          else
            SizedBox(height: AppSpacing.sm + bottomInset),
        ],
      ),
    );
  }
}

/// §8.17 action-sheet row: height 52, icon 20 + `bodyLarge` 600; destructive
/// rows in `textError`.
class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = destructive ? c.textError : c.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          color: selected ? c.primaryContainer : null,
          child: Row(
            children: [
              Icon(icon, size: 20, color: destructive ? c.textError : c.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
