import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Exact colors of Inbox v2 (§4, §11), light and dark.
@immutable
class InboxPalette {
  const InboxPalette._({
    required this.list,
    required this.filterBar,
    required this.filterBorder,
    required this.pill,
    required this.pillBorder,
    required this.pillText,
    required this.pillSel,
    required this.pillSelBorder,
    required this.pillSelText,
    required this.count,
    required this.countText,
    required this.filterIcon,
    required this.divider,
    required this.pressed,
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.unreadText,
    required this.note,
    required this.waitBg,
    required this.waitFg,
    required this.suggestBg,
    required this.suggestFg,
    required this.aiBg,
    required this.aiFg,
    required this.unassignedBg,
    required this.unassignedFg,
    required this.colleagueBg,
    required this.colleagueFg,
    required this.snoozedBg,
    required this.snoozedFg,
    required this.emptyTile,
    required this.applied,
    required this.appliedText,
    required this.shadows,
  });

  /// Header gradient (160°), unchanged in dark mode.
  static const headerStart = Color(0xFF0F7E7A);
  static const headerEnd = Color(0xFF0D6D68);

  /// Bell dot ring = the header color under it.
  static const bellRing = Color(0xFF0E7570);
  static const bellDot = Color(0xFFEF4444);
  static const readTicks = Color(0xFF15B6A8);
  static const emptyIcon = Color(0xFF94A3B8);

  // Swipe actions (§4.5).
  static const swipeClaim = Color(0xFF0F7E7A);
  static const swipeAssign = Color(0xFF2563EB);
  static const swipeClose = Color(0xFF15803D);
  static const swipeReopen = Color(0xFF475569);
  static const swipeRead = Color(0xFF64748B);

  final Color list;
  final Color filterBar;
  final Color filterBorder;
  final Color pill;
  final Color pillBorder;
  final Color pillText;
  final Color pillSel;
  final Color pillSelBorder;
  final Color pillSelText;
  final Color count;
  final Color countText;
  final Color filterIcon;
  final Color divider;
  final Color pressed;
  final Color name;
  final Color preview;
  final Color time;
  final Color unread;
  final Color unreadText;
  final Color note;
  final Color waitBg;
  final Color waitFg;
  final Color suggestBg;
  final Color suggestFg;
  final Color aiBg;
  final Color aiFg;
  final Color unassignedBg;
  final Color unassignedFg;
  final Color colleagueBg;
  final Color colleagueFg;
  final Color snoozedBg;
  final Color snoozedFg;
  final Color emptyTile;
  final Color applied;
  final Color appliedText;

  /// Soft double shadow under pills and the filter button (none in dark).
  final bool shadows;

  List<BoxShadow> pillShadow({bool strong = false}) => shadows
      ? [
          BoxShadow(offset: const Offset(0, 2), blurRadius: 8, spreadRadius: -2, color: Color(strong ? 0x1F0F172A : 0x1A0F172A)),
          const BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0A0F172A)),
        ]
      : const [];

  static const _light = InboxPalette._(
    list: Color(0xFFFFFFFF),
    filterBar: Color(0xFFFAFBFC),
    filterBorder: Color(0xFFE9EEF2),
    pill: Color(0xFFFFFFFF),
    pillBorder: Color(0xFFEEF1F4),
    pillText: Color(0xFF1F2937),
    pillSel: Color(0xFFE4F6EA),
    pillSelBorder: Color(0xFFCDEED8),
    pillSelText: Color(0xFF15803D),
    count: Color(0xFF4B5563),
    countText: Color(0xFFFFFFFF),
    filterIcon: Color(0xFF374151),
    divider: Color(0xFFE9EEF2),
    pressed: Color(0xFFF6F8FA),
    name: Color(0xFF0F172A),
    preview: Color(0xFF64748B),
    time: Color(0xFF94A3B8),
    unread: Color(0xFF0F7E7A),
    unreadText: Color(0xFFFFFFFF),
    note: Color(0xFFB45309),
    waitBg: Color(0xFFFFF1F2),
    waitFg: Color(0xFFE11D48),
    suggestBg: Color(0xFFECF7F6),
    suggestFg: Color(0xFF0A5E5B),
    aiBg: Color(0xFFEEF2F5),
    aiFg: Color(0xFF64748B),
    unassignedBg: Color(0xFFFEF3E2),
    unassignedFg: Color(0xFFB45309),
    colleagueBg: Color(0xFFEEF2F5),
    colleagueFg: Color(0xFF475569),
    snoozedBg: Color(0xFFEFF4FF),
    snoozedFg: Color(0xFF2563EB),
    emptyTile: Color(0xFFF1F4F6),
    applied: Color(0xFFECF7F6),
    appliedText: Color(0xFF0A5E5B),
    shadows: true,
  );

  static const _dark = InboxPalette._(
    list: Color(0xFF0B1215),
    filterBar: Color(0xFF0F171A),
    filterBorder: Color(0xFF243036),
    pill: Color(0xFF151E22),
    pillBorder: Color(0xFF243036),
    pillText: Color(0xFFE6ECEF),
    pillSel: Color(0xFF0F2A1A),
    pillSelBorder: Color(0xFF1E4D30),
    pillSelText: Color(0xFF4ADE80),
    count: Color(0xFF93A3AB),
    countText: Color(0xFF0B1215),
    filterIcon: Color(0xFFE6ECEF),
    divider: Color(0xFF1C272C),
    pressed: Color(0xFF151E22),
    name: Color(0xFFE6ECEF),
    preview: Color(0xFF93A3AB),
    time: Color(0xFF7B8A92),
    unread: Color(0xFF2BB8AD),
    unreadText: Color(0xFF0B1215),
    note: Color(0xFFFBBF24),
    waitBg: Color(0xFF2A1218),
    waitFg: Color(0xFFFB7185),
    suggestBg: Color(0xFF0F2E2D),
    suggestFg: Color(0xFF5EEAD4),
    aiBg: Color(0xFF1C272C),
    aiFg: Color(0xFF93A3AB),
    unassignedBg: Color(0xFF2B2112),
    unassignedFg: Color(0xFFFBBF24),
    colleagueBg: Color(0xFF1C272C),
    colleagueFg: Color(0xFF93A3AB),
    snoozedBg: Color(0xFF172036),
    snoozedFg: Color(0xFF93B4FF),
    emptyTile: Color(0xFF151E22),
    applied: Color(0xFF0F2E2D),
    appliedText: Color(0xFF5EEAD4),
    shadows: false,
  );

  static InboxPalette of(BuildContext context) => context.colors.isDark ? _dark : _light;
}
