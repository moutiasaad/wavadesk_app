import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Collapsing inbox header (Inbox spec §3, §4.1) on the brand surface
/// (BrandHeader): teal gradient from the top of the screen ([topInset] = the
/// status bar), white `h1` title shrinking to `h4`. In multi-select it
/// becomes ✕ · "{n} محدد" · "تحديد الكل" (§4.9).
class ConversationsAppBarDelegate extends SliverPersistentHeaderDelegate {
  ConversationsAppBarDelegate({
    required this.title,
    required this.onSearch,
    required this.onNotifications,
    required this.unreadNotifications,
    required this.selectedCount,
    required this.onExitSelection,
    required this.onSelectAll,
    required this.textScale,
    this.topInset = 0,
  });

  final String title;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final int unreadNotifications;

  /// > 0 → multi-select app bar.
  final int selectedCount;
  final VoidCallback onExitSelection;
  final VoidCallback onSelectAll;

  /// Header heights grow with large text so titles never clip (§9).
  final double textScale;

  /// Status-bar height: the teal header paints under it.
  final double topInset;

  double get _scale => textScale.clamp(1.0, 2.0);

  @override
  double get minExtent => topInset + 60 * _scale;

  @override
  double get maxExtent => selectedCount > 0 ? minExtent : math.max(minExtent, topInset + 76 * _scale);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = context.text;
    final l = context.l10n;

    // The child must fill the extent the sliver reserves: a shorter child
    // makes layoutExtent > paintExtent ("SliverGeometry is not valid"),
    // which breaks layout and hit-testing of the whole inbox list.
    if (selectedCount > 0) {
      return SizedBox.expand(
        child: BrandHeader(
          safeTop: false,
          elevated: true,
          padding: EdgeInsetsDirectional.fromSTEB(AppSpacing.xs, topInset, AppSpacing.sm, AppSpacing.sm),
          child: Row(
              children: [
                AppIconButton(
                  icon: AppIcons.close,
                  iconSize: 24,
                  semanticLabel: l.inbox_exit_selection,
                  onPressed: onExitSelection,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l.inbox_selected(selectedCount),
                      style: t.h4.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                AppBarTextAction(label: l.inbox_select_all, onPressed: onSelectAll),
              ],
            ),
        ),
      );
    }

    // 0 = expanded, 1 = collapsed.
    final range = maxExtent - minExtent;
    final p = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final titleStyle = TextStyle.lerp(t.h1, t.h4, p)!.copyWith(color: Colors.white, fontWeight: FontWeight.w800);

    return SizedBox.expand(
      child: BrandHeader(
        safeTop: false,
        elevated: p > 0.5 || overlapsContent,
        padding: EdgeInsetsDirectional.fromSTEB(18, topInset + 4 * (1 - p), 10, AppSpacing.sm + 6 * (1 - p)),
        child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              // Morphs into the search field (Search spec §2, §14).
              Hero(
                tag: 'search-field',
                child: AppIconButton(
                  icon: AppIcons.search,
                  variant: AppIconButtonVariant.filled,
                  semanticLabel: l.common_search,
                  onPressed: onSearch,
                ),
              ),
              AppIconButton(
                icon: AppIcons.bell,
                variant: AppIconButtonVariant.filled,
                semanticLabel: unreadNotifications > 0
                    ? l.inbox_a11y_notifications(unreadNotifications)
                    : l.notifications_title,
                onPressed: onNotifications,
                badge: unreadNotifications > 0 ? const NotificationDot() : null,
              ),
            ],
          ),
      ),
    );
  }

  @override
  bool shouldRebuild(ConversationsAppBarDelegate old) =>
      old.title != title ||
      old.unreadNotifications != unreadNotifications ||
      old.selectedCount != selectedCount ||
      old.textScale != textScale ||
      old.topInset != topInset ||
      old.onSearch != onSearch;
}

/// Pinned header: segmented control (H16) + 12 gap, then the connection
/// banner when offline/reconnecting (§3, §5).
class PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  PinnedHeaderDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Material(
    color: context.colors.background,
    child: SizedBox.expand(child: child),
  );

  @override
  bool shouldRebuild(PinnedHeaderDelegate old) => true;
}

/// Floating + snapping header for the quick chips (§3): scrolls away and
/// comes back on scroll-up.
class FloatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  FloatingHeaderDelegate({required this.child, required this.height, required this.vsync});

  final Widget child;
  final double height;

  @override
  final TickerProvider vsync;

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => height;

  @override
  FloatingHeaderSnapConfiguration get snapConfiguration =>
      FloatingHeaderSnapConfiguration(duration: AppMotion.normal, curve: AppMotion.standard);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Material(
    color: context.colors.background,
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        minHeight: height,
        maxHeight: height,
        child: Opacity(opacity: (1 - shrinkOffset / height).clamp(0.0, 1.0), child: child),
      ),
    ),
  );

  @override
  bool shouldRebuild(FloatingHeaderDelegate old) => true;
}
