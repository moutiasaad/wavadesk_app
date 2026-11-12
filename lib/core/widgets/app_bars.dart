import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'brand_surface.dart';

/// The app's header surface (every screen's top bar): teal brand gradient,
/// rounded bottom corners, soft shadow (stronger when [elevated]), light
/// status-bar icons. [child] sits below the status bar on a [BrandSurface]
/// with white icons / text, so shared buttons and switches turn light.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.child,
    this.elevated = false,
    this.padding = const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.xs, AppSpacing.sm, AppSpacing.md),
    this.safeTop = true,
  });

  final Widget child;

  /// Content scrolls under the header: deeper shadow.
  final bool elevated;
  final EdgeInsetsGeometry padding;

  /// Pad for the status bar (false inside a sliver that already does).
  final bool safeTop;

  static const radius = Radius.circular(24);

  /// Light / dark gradient stops.
  static List<Color> colorsOf(BuildContext context) => context.colors.isDark
      ? const [Color(0xFF0B5552), Color(0xFF0E6E69)]
      : const [Color(0xFF0F7E7A), Color(0xFF169C94)];

  @override
  Widget build(BuildContext context) {
    final colors = colorsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd, colors: colors),
          borderRadius: const BorderRadius.only(bottomLeft: radius, bottomRight: radius),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: elevated ? 0.35 : 0.16),
              blurRadius: elevated ? 18 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: safeTop,
          bottom: false,
          child: Padding(
            padding: padding,
            child: BrandSurface(
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// For a [BrandHeader] placed inside a screen's top SafeArea (chat,
/// search, notifications, editor): paints the brand gradient into the
/// status-bar strip above it, which would otherwise keep the page color.
/// No-op without a status bar or outside a SafeArea.
class BrandStatusBarBleed extends StatelessWidget {
  const BrandStatusBarBleed({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).top;
    // Not under a SafeArea (BrandHeader pads itself) or no status bar.
    if (inset == 0 || MediaQuery.paddingOf(context).top > 0) return child;
    final colors = BrandHeader.colorsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -inset,
          left: 0,
          right: 0,
          height: inset + 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [colors.first, Color.lerp(colors.first, colors.last, 0.5)!],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Tab-root header (Account…): brand header with a large white title and
/// up to 2 actions.
class AppBarLarge extends StatelessWidget implements PreferredSizeWidget {
  const AppBarLarge({super.key, required this.title, this.subtitle, this.actions = const [], this.background});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Kept for older call sites; the header always uses the brand colors.
  final Color? background;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 70 : 84);

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 2, 'AppBarLarge allows up to 2 actions');
    final t = context.text;
    return BrandHeader(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.sm, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: t.h2.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: t.caption.copyWith(color: Colors.white.withValues(alpha: 0.78)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Inner-screen header: teal brand gradient with rounded bottom corners,
/// a round glassy back button (the title area is part of its tap zone),
/// bold white title and an optional [subtitle]. Actions are drawn on a
/// [BrandSurface], so the shared buttons / switches turn light. A stronger
/// shadow once content scrolls under ([scrolledUnder]).
class AppBarStandard extends StatelessWidget implements PreferredSizeWidget {
  const AppBarStandard({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.scrolledUnder = false,
    this.onBack,
    this.background,
    this.showBack = true,
    this.leading,
  });

  final String title;

  /// Small second line under the title.
  final String? subtitle;
  final List<Widget> actions;
  final bool scrolledUnder;
  final VoidCallback? onBack;

  /// Kept for older call sites; the header always uses the brand colors.
  final Color? background;
  final bool showBack;
  final Widget? leading;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 66 : 78);

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    void back() => (onBack ?? () => Navigator.of(context).maybePop())();

    final titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: t.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: t.caption.copyWith(color: Colors.white.withValues(alpha: 0.78)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    final Widget start;
    if (leading != null) {
      start = Row(children: [leading!, const SizedBox(width: AppSpacing.sm), Expanded(child: titleBlock)]);
    } else if (showBack) {
      // A big back target: the round button and the title both go back.
      start = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: back,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: context.l10n.common_back,
              excludeSemantics: true,
              child: _GlassBackButton(onTap: back),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: titleBlock),
          ],
        ),
      );
    } else {
      start = Padding(padding: const EdgeInsetsDirectional.only(start: AppSpacing.md), child: titleBlock);
    }

    return BrandHeader(
      elevated: scrolledUnder,
      child: Row(
        children: [
          Expanded(child: start),
          ...actions,
        ],
      ),
    );
  }
}

/// 40 dp round back button, white on a translucent white disc.
class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 40,
          child: AppIcon(AppIcons.back, dp: 16, color: Colors.white), // = AppIconButton.headerIconSize
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
  Widget build(BuildContext context) {
    if (BrandSurface.of(context)) {
      // On the brand header: a light pill.
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            backgroundColor: Colors.white.withValues(alpha: onPressed == null ? 0.08 : 0.18),
            textStyle: context.text.buttonMedium,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            minimumSize: const Size(48, 38),
          ),
          onPressed: onPressed,
          child: Text(label),
        ),
      );
    }
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: context.colors.primary,
        textStyle: context.text.buttonMedium,
        minimumSize: const Size(48, 48),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
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
