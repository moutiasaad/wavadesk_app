import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/conversation_filters.dart';

/// Single-select quick chips + the trailing "فلاتر ▾" chip (Inbox spec
/// §4.3). Horizontal, padding H16, gap 6, no scrollbar.
class QuickFilterChips extends StatelessWidget {
  const QuickFilterChips({
    super.key,
    required this.selected,
    required this.unreadCount,
    required this.advancedCount,
    required this.onSelected,
    required this.onOpenFilters,
  });

  final QuickChip selected;
  final int unreadCount;
  final int advancedCount;
  final ValueChanged<QuickChip> onSelected;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(QuickChip c) => switch (c) {
      QuickChip.all => l.inbox_chip_all,
      QuickChip.unread => l.inbox_chip_unread,
      QuickChip.awaiting => l.inbox_chip_awaiting,
      QuickChip.ai => l.inbox_chip_ai,
      QuickChip.snoozed => l.inbox_chip_snoozed,
      QuickChip.closed => l.inbox_chip_closed,
    };

    final chips = <Widget>[
      for (final chip in QuickChip.values)
        AppFilterChip(
          label: label(chip),
          count: chip == QuickChip.unread && unreadCount > 0 ? unreadCount : null,
          selected: chip == selected,
          onTap: () => onSelected(chip),
        ),
      AppFilterChip(
        label: l.inbox_chip_filters,
        count: advancedCount > 0 ? advancedCount : null,
        selected: advancedCount > 0,
        trailingIcon: AppIcons.chevronDown,
        onTap: onOpenFilters,
      ),
    ];

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}
