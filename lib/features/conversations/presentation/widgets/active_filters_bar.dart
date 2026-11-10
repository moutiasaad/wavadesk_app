import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/conversation_filters.dart';
import 'filters_sheet.dart';

/// Dismissible tonal chips for applied advanced filters + "مسح الكل"
/// (Inbox spec §4.4). Padding H16, bottom 8, scrolls horizontally.
class ActiveFiltersBar extends ConsumerWidget {
  const ActiveFiltersBar({super.key, required this.filters, required this.onChanged, required this.onClearAll});

  final AdvancedFilters filters;
  final ValueChanged<AdvancedFilters> onChanged;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = filters;
    final teams = ref.watch(teamsProvider);
    final colleagues = ref.watch(colleaguesProvider);

    final chips = <(String, VoidCallback)>[
      for (final ch in f.channels) (ch.label(l), () => onChanged(f.copyWith(channels: {...f.channels}..remove(ch)))),
      for (final p in f.priorities) (p.label(l), () => onChanged(f.copyWith(priorities: {...f.priorities}..remove(p)))),
      if (f.assignee != AssigneeFilter.all)
        (
          assigneeLabel(l, f, colleagues),
          () => onChanged(f.copyWith(assignee: AssigneeFilter.all, clearColleague: true)),
        ),
      for (final t in f.teamIds)
        (
          teams.where((x) => x.id == t).firstOrNull?.name ?? t,
          () => onChanged(f.copyWith(teamIds: {...f.teamIds}..remove(t))),
        ),
      for (final t in f.tags) (t, () => onChanged(f.copyWith(tags: {...f.tags}..remove(t)))),
      if (f.date != DateRangeFilter.any)
        (dateLabel(context, f), () => onChanged(f.copyWith(date: DateRangeFilter.any, clearRange: true))),
    ];

    return SizedBox(
      height: 44,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg, end: AppSpacing.sm, bottom: AppSpacing.sm),
          children: [
            for (final (label, onRemove) in chips) ...[
              _RemovableTag(label: label, onRemove: onRemove),
              const SizedBox(width: 6),
            ],
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.colors.primary,
                textStyle: context.text.buttonSmall,
                minimumSize: const Size(48, 36),
              ),
              onPressed: onClearAll,
              child: Text(l.inbox_clear_all),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovableTag extends StatelessWidget {
  const _RemovableTag({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Semantics(
        button: true,
        label: '${context.l10n.common_clear} $label',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onRemove,
          child: Container(
            height: 28,
            padding: const EdgeInsetsDirectional.only(start: 10, end: AppSpacing.sm),
            decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: context.text.tagLabel.copyWith(color: c.onPrimaryContainer)),
                const SizedBox(width: AppSpacing.xs),
                Icon(AppIcons.close, size: 14, color: c.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
