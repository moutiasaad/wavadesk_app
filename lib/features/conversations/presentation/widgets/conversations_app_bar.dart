import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Collapsing inbox header (Inbox spec §3, §4.1). Expanded: `h1` title with
/// padding top 4 / H 18 / bottom 12. Collapsed: 56dp bar with an `h4` title.
/// In multi-select it becomes ✕ · "{n} محدد" · "تحديد الكل" (§4.9).
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

  double get _scale => textScale.clamp(1.0, 2.0);

  @override
  double get minExtent => 56 * _scale;

  @override
  double get maxExtent => selectedCount > 0 ? minExtent : math.max(minExtent, 64 * _scale);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;

    // The child must fill the extent the sliver reserves: a shorter child
    // makes layoutExtent > paintExtent ("SliverGeometry is not valid"),
    // which breaks layout and hit-testing of the whole inbox list.
    if (selectedCount > 0) {
      return Material(
        color: c.background,
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
                      style: t.h4,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                AppBarTextAction(label: l.inbox_select_all, onPressed: onSelectAll),
              ],
            ),
          ),
        ),
      );
    }

    // 0 = expanded, 1 = collapsed.
    final range = maxExtent - minExtent;
    final p = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final titleStyle = TextStyle.lerp(t.h1, t.h4, p)!;

    return Material(
      color: c.background,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: 18, end: 18, top: 4 * (1 - p), bottom: 12 * (1 - p)),
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
                icon: AppIcons.notifications,
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
      ),
    );
  }

  @override
  bool shouldRebuild(ConversationsAppBarDelegate old) =>
      old.title != title ||
      old.unreadNotifications != unreadNotifications ||
      old.selectedCount != selectedCount ||
      old.textScale != textScale ||
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
