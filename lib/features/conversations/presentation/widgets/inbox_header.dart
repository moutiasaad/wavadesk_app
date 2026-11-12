import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import 'inbox_palette.dart';

/// Inbox v2 §4.1: teal gradient header (160°), title 24/800 + subtitle (or
/// the matching count while advanced filters are on), then two 44×44 glass
/// buttons — search and bell. Fixed: it never scrolls away.
class InboxHeader extends StatelessWidget {
  const InboxHeader({
    super.key,
    required this.matching,
    required this.unreadNotifications,
    required this.onSearch,
    required this.onBell,
  });

  /// Result count while advanced filters are applied; null shows the subtitle.
  final int? matching;
  final int unreadNotifications;
  final VoidCallback onSearch;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final l = context.l10n;
    final big = MediaQuery.textScalerOf(context).scale(10) >= 20;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // 160°: top-start → bottom-end, slightly off vertical.
            begin: Alignment(-0.34, -1),
            end: Alignment(0.34, 1),
            colors: [InboxPalette.headerStart, InboxPalette.headerEnd],
          ),
        ),
        padding: EdgeInsets.fromLTRB(18, MediaQuery.viewPaddingOf(context).top + 4, 18, 18),
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
                      l.inbox_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w800, height: 1.35, color: Colors.white),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      matching == null ? l.inbox_sub : l.inbox_matching(matching!),
                      key: ValueKey(matching),
                      maxLines: big ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: matching == null ? FontWeight.w400 : FontWeight.w700,
                        color: Colors.white.withValues(alpha: matching == null ? 0.85 : 0.95),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Hero(
              // Morphs into the search field (Search spec §2).
              tag: 'search-field',
              child: InboxGlassButton(icon: AppIcons.search, label: l.common_search, onTap: onSearch),
            ),
            const SizedBox(width: 10),
            InboxGlassButton(
              icon: AppIcons.bell,
              label: unreadNotifications > 0 ? l.inbox_a11y_notifications(unreadNotifications) : l.notifications_title,
              onTap: onBell,
              dot: unreadNotifications > 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// 44×44 rounded-square glass button on the teal header (§4.1).
class InboxGlassButton extends StatefulWidget {
  const InboxGlassButton({super.key, required this.icon, required this.label, required this.onTap, this.dot = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dot;

  @override
  State<InboxGlassButton> createState() => _InboxGlassButtonState();
}

class _InboxGlassButtonState extends State<InboxGlassButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: _down ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AppIcon(widget.icon, dp: 20, color: Colors.white),
                  if (widget.dot)
                    // Top-left corner in both directions, as in the mockup.
                    Positioned(
                      top: 9,
                      left: 10,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: InboxPalette.bellDot,
                          shape: BoxShape.circle,
                          border: Border.all(color: InboxPalette.bellRing, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-select header (§5.3): white bar · × · "{n} محددة" · استلام ·
/// إسناد · إغلاق · مقروءة, plus ⋮ for the rarer bulk actions.
class InboxSelectionBar extends StatelessWidget {
  const InboxSelectionBar({
    super.key,
    required this.count,
    required this.anyUnread,
    required this.onExit,
    required this.onClaim,
    required this.onAssign,
    required this.onClose,
    required this.onRead,
    required this.onMore,
  });

  final int count;
  final bool anyUnread;
  final VoidCallback onExit;
  final VoidCallback onClaim;
  final VoidCallback onAssign;
  final VoidCallback onClose;
  final VoidCallback onRead;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final p = InboxPalette.of(context);
    Widget action(IconData icon, String label, VoidCallback onTap) => Tooltip(
          message: label,
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: InkResponse(
              onTap: count == 0 ? null : onTap,
              radius: 24,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(icon, dp: 18, color: c.textPrimary),
                    const SizedBox(height: 2),
                    Text(label, maxLines: 1, style: context.text.caption.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, color: c.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent),
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top),
        decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: p.divider))),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 4),
              Semantics(
                button: true,
                label: l.inbox_exit_selection,
                excludeSemantics: true,
                child: InkResponse(
                  onTap: onExit,
                  radius: 24,
                  child: SizedBox.square(dimension: 48, child: Center(child: AppIcon(AppIcons.close, dp: 18, color: c.textPrimary))),
                ),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l.inbox_sel_count(count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.h5.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: c.textPrimary),
                  ),
                ),
              ),
              action(AppIcons.claim, l.inbox_act_claim, onClaim),
              action(AppIcons.team, l.inbox_act_assign, onAssign),
              action(AppIcons.check, l.inbox_act_close, onClose),
              action(AppIcons.read, anyUnread ? l.inbox_act_read : l.inbox_act_unread, onRead),
              Semantics(
                button: true,
                label: l.common_more,
                excludeSemantics: true,
                child: InkResponse(
                  onTap: count == 0 ? null : onMore,
                  radius: 22,
                  child: SizedBox(width: 40, height: 48, child: Center(child: AppIcon(AppIcons.more, dp: 18, color: c.textPrimary))),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
