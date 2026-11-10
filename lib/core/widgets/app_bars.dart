import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'app_icon_button.dart';

/// §8.1 root app bar for tab roots. Height 56 + status bar, no shadow or
/// border, title `h1` start-aligned, up to 2 filled icon buttons.
class AppBarLarge extends StatelessWidget implements PreferredSizeWidget {
  const AppBarLarge({super.key, required this.title, this.actions = const [], this.background});

  final String title;
  final List<Widget> actions;

  /// `backgroundMuted` on grouped screens.
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    assert(actions.length <= 2, 'AppBarLarge allows up to 2 actions');
    return Material(
      color: background ?? c.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.screenH, end: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.text.h1, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// §8.1 pushed app bar: height 56, mirrored back button, title `h4`
/// start-aligned, trailing text action or icons. Bottom border only once
/// content scrolls under — pass [scrolledUnder].
class AppBarStandard extends StatelessWidget implements PreferredSizeWidget {
  const AppBarStandard({
    super.key,
    required this.title,
    this.actions = const [],
    this.scrolledUnder = false,
    this.onBack,
    this.background,
    this.showBack = true,
    this.leading,
  });

  final String title;
  final List<Widget> actions;
  final bool scrolledUnder;
  final VoidCallback? onBack;
  final Color? background;
  final bool showBack;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: background ?? c.background,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scrolledUnder ? c.divider : Colors.transparent)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (showBack)
                AppIconButton(
                  icon: AppIcons.back,
                  iconSize: 24,
                  semanticLabel: context.l10n.common_back,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                )
              else
                const SizedBox(width: AppSpacing.md),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.text.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing text action for [AppBarStandard] (`buttonMedium`, `primary`).
class AppBarTextAction extends StatelessWidget {
  const AppBarTextAction({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: context.colors.primary,
      textStyle: context.text.buttonMedium,
      minimumSize: const Size(48, 48),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

/// Tracks whether a scrollable has content under the app bar.
class ScrolledUnderBuilder extends StatefulWidget {
  const ScrolledUnderBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, bool scrolledUnder) builder;

  @override
  State<ScrolledUnderBuilder> createState() => _ScrolledUnderBuilderState();
}

class _ScrolledUnderBuilderState extends State<ScrolledUnderBuilder> {
  bool _under = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
          final under = n.metrics.pixels > 0;
          if (under != _under) setState(() => _under = under);
        }
        return false;
      },
      child: widget.builder(context, _under),
    );
  }
}
