import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'brand_surface.dart';

/// The app's header surface (every screen's top bar), like the design:
/// the page color, dark bold title, a hairline under it once content
/// scrolls beneath ([elevated]), dark status-bar icons. [child] sits on a
/// [BrandSurface] so header icon buttons share one glyph size.
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

  /// Header fill (both stops equal): the page color. Avatar rings and the
  /// status-bar bleed use it to blend in.
  static List<Color> colorsOf(BuildContext context) => [context.colors.background, context.colors.background];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overlay = c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: c.background,
          border: Border(bottom: BorderSide(color: elevated ? c.divider : c.background)),
        ),
        child: SafeArea(
          top: safeTop,
          bottom: false,
          child: Padding(
            padding: padding,
            child: BrandSurface(
              child: IconTheme.merge(
                data: IconThemeData(color: c.textPrimary),
                child: DefaultTextStyle.merge(style: TextStyle(color: c.textPrimary), child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// For a [BrandHeader] placed inside a screen's top SafeArea (chat,
/// search, notifications, editor): paints the header color into the
/// status-bar strip above it.
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
                    style: t.h3.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: t.caption.copyWith(color: context.colors.textSecondary),
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
            style: t.h5.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: t.caption.copyWith(color: context.colors.textSecondary),
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

/// 34 dp round back button: light disc, hairline border, dark chevron.
class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 34,
          child: AppIcon(AppIcons.back, dp: 18, color: c.textPrimary), // = AppIconButton.headerIconSize
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
      // In the header: small teal text, no pill (design "قراءة الكل").
      return TextButton(
        style: TextButton.styleFrom(
          foregroundColor: context.colors.primary,
          disabledForegroundColor: context.colors.textTertiary,
          textStyle: context.text.buttonSmall,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          minimumSize: const Size(48, 40),
        ),
        onPressed: onPressed,
        child: Text(label),
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
