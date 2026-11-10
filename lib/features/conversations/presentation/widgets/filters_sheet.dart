import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/conversation_filters_controller.dart';
import '../../data/conversations_repository.dart';
import '../../domain/conversation_filters.dart';

/// Label for the assignee filter chip/row.
String assigneeLabel(AppLocalizations l, AdvancedFilters f, List<Agent> colleagues) => switch (f.assignee) {
  AssigneeFilter.all => l.inbox_filters_assignee_all,
  AssigneeFilter.me => l.inbox_filters_assignee_me,
  AssigneeFilter.colleague =>
    colleagues.where((a) => a.id == f.colleagueId).firstOrNull?.name ?? l.inbox_filters_assignee_colleague,
  AssigneeFilter.ai => l.inbox_filters_assignee_ai,
  AssigneeFilter.unassigned => l.inbox_filters_assignee_unassigned,
};

/// Label for the date filter chip.
String dateLabel(BuildContext context, AdvancedFilters f) {
  final l = context.l10n;
  return switch (f.date) {
    DateRangeFilter.any => '',
    DateRangeFilter.today => l.inbox_filters_date_today,
    DateRangeFilter.last7 => l.inbox_filters_date_7d,
    DateRangeFilter.last30 => l.inbox_filters_date_30d,
    DateRangeFilter.custom =>
      f.from != null && f.to != null
          ? '${AppFormat.date(context, f.from!)} – ${AppFormat.date(context, f.to!)}'
          : l.inbox_filters_date_custom,
  };
}

/// Advanced filters (Inbox spec §7). Edits a draft; nothing applies until
/// the pinned "عرض {n} محادثة" button is pressed.
Future<void> showInboxFiltersSheet(BuildContext context, WidgetRef ref) {
  final query = ref.read(conversationFiltersProvider);
  final draft = ValueNotifier<AdvancedFilters>(query.advanced);
  return AppBottomSheet.showExpanded<void>(
    context,
    title: context.l10n.inbox_filters_title,
    headerTrailing: ValueListenableBuilder<AdvancedFilters>(
      valueListenable: draft,
      builder: (ctx, value, _) => TextButton(
        style: TextButton.styleFrom(
          foregroundColor: ctx.colors.primary,
          textStyle: ctx.text.buttonMedium,
          minimumSize: const Size(48, 48),
        ),
        // Resets the sheet only; applying still needs the button.
        onPressed: () => draft.value = AdvancedFilters.empty,
        child: Text(ctx.l10n.inbox_filters_clear),
      ),
    ),
    action: _ApplyButton(draft: draft, query: query),
    builder: (ctx, controller) => _FiltersBody(draft: draft, segment: query.segment, controller: controller),
  ).whenComplete(draft.dispose);
}

class _ApplyButton extends ConsumerStatefulWidget {
  const _ApplyButton({required this.draft, required this.query});

  final ValueNotifier<AdvancedFilters> draft;
  final InboxQuery query;

  @override
  ConsumerState<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends ConsumerState<_ApplyButton> {
  Timer? _debounce;
  int? _count;

  @override
  void initState() {
    super.initState();
    widget.draft.addListener(_schedule);
    _fetch();
  }

  @override
  void dispose() {
    widget.draft.removeListener(_schedule);
    _debounce?.cancel();
    super.dispose();
  }

  /// Live count via `?count_only=1`, debounced 300ms (§7).
  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetch);
  }

  Future<void> _fetch() async {
    try {
      final n = await ref
          .read(conversationsRepositoryProvider)
          .count(widget.query.copyWith(advanced: widget.draft.value));
      if (mounted) setState(() => _count = n);
    } catch (_) {
      if (mounted) setState(() => _count = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppButton(
      label: _count == null ? l.inbox_filters_apply : l.inbox_filters_show(_count!),
      size: AppButtonSize.large,
      expand: true,
      onPressed: () {
        ref.read(conversationFiltersProvider.notifier).setAdvanced(widget.draft.value);
        Navigator.of(context).pop();
      },
    );
  }
}

class _FiltersBody extends ConsumerStatefulWidget {
  const _FiltersBody({required this.draft, required this.segment, required this.controller});

  final ValueNotifier<AdvancedFilters> draft;
  final InboxSegment segment;
  final ScrollController controller;

  @override
  ConsumerState<_FiltersBody> createState() => _FiltersBodyState();
}

class _FiltersBodyState extends ConsumerState<_FiltersBody> {
  String _tagQuery = '';

  AdvancedFilters get _f => widget.draft.value;
  set _f(AdvancedFilters v) => widget.draft.value = v;

  Set<T> _toggle<T>(Set<T> set, T v) => set.contains(v) ? ({...set}..remove(v)) : {...set, v};

  Future<void> _pickColleague() async {
    final colleagues = ref.read(colleaguesProvider);
    final picked = await AppBottomSheet.show<Agent>(
      context,
      title: context.l10n.inbox_filters_pick_colleague,
      builder: (ctx) => Column(
        children: [
          for (final a in colleagues)
            AppRadioRow(
              label: a.name,
              subtitle: a.presence.label(ctx.l10n),
              selected: _f.colleagueId == a.id,
              leading: AppAvatar(
                name: a.name,
                id: a.id,
                presence: a.presence,
                size: AppAvatarSize.md,
                ringColor: ctx.colors.surfaceElevated,
              ),
              onTap: () => Navigator.pop(ctx, a),
            ),
        ],
      ),
    );
    if (picked != null) _f = _f.copyWith(assignee: AssigneeFilter.colleague, colleagueId: picked.id);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _f.from != null && _f.to != null ? DateTimeRange(start: _f.from!, end: _f.to!) : null,
    );
    if (range != null) _f = _f.copyWith(date: DateRangeFilter.custom, from: range.start, to: range.end);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.text;
    final c = context.colors;
    final teams = ref.watch(teamsProvider);
    final tags = ref.watch(allTagsProvider);
    final colleagues = ref.watch(colleaguesProvider);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Semantics(header: true, child: Text(text, style: t.h6)),
    );
    Widget wrap(List<Widget> children) => Wrap(spacing: 6, runSpacing: 6, children: children);

    return ValueListenableBuilder<AdvancedFilters>(
      valueListenable: widget.draft,
      builder: (context, f, _) {
        final visibleTags = _tagQuery.isEmpty
            ? tags
            : tags.where((x) => x.toLowerCase().contains(_tagQuery.toLowerCase())).toList();
        return ListView(
          controller: widget.controller,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            header(l.inbox_filters_channel),
            wrap([
              for (final ch in const [
                Channel.whatsapp,
                Channel.web,
                Channel.messenger,
                Channel.instagram,
                Channel.email,
              ])
                AppFilterChip(
                  label: ch.label(l),
                  selected: f.channels.contains(ch),
                  leading: Icon(ch.glyph, size: 14, color: f.channels.contains(ch) ? c.onSecondary : ch.brand(c)),
                  onTap: () => _f = f.copyWith(channels: _toggle(f.channels, ch)),
                ),
            ]),
            header(l.inbox_filters_priority),
            wrap([
              for (final p in Priority.values)
                AppFilterChip(
                  label: p.label(l),
                  selected: f.priorities.contains(p),
                  onTap: () => _f = f.copyWith(priorities: _toggle(f.priorities, p)),
                ),
            ]),
            if (widget.segment == InboxSegment.all) ...[
              header(l.inbox_filters_assignee),
              for (final a in AssigneeFilter.values)
                AppRadioRow(
                  label: a == AssigneeFilter.colleague
                      ? (f.assignee == a ? assigneeLabel(l, f, colleagues) : l.inbox_filters_assignee_colleague)
                      : assigneeLabel(l, AdvancedFilters(assignee: a), colleagues),
                  selected: f.assignee == a,
                  onTap: a == AssigneeFilter.colleague
                      ? _pickColleague
                      : () => _f = f.copyWith(assignee: a, clearColleague: true),
                ),
            ],
            header(l.inbox_filters_team),
            wrap([
              for (final team in teams)
                AppFilterChip(
                  label: team.name,
                  selected: f.teamIds.contains(team.id),
                  onTap: () => _f = f.copyWith(teamIds: _toggle(f.teamIds, team.id)),
                ),
            ]),
            header(l.inbox_filters_tags),
            if (tags.length > 12) ...[
              AppSearchField(
                hint: l.inbox_filters_tags_search,
                showCancel: false,
                onChanged: (v) => setState(() => _tagQuery = v),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            wrap([
              for (final tag in visibleTags)
                AppFilterChip(
                  label: tag,
                  selected: f.tags.contains(tag),
                  onTap: () => _f = f.copyWith(tags: _toggle(f.tags, tag)),
                ),
            ]),
            header(l.inbox_filters_date),
            wrap([
              for (final d in const [DateRangeFilter.today, DateRangeFilter.last7, DateRangeFilter.last30])
                AppFilterChip(
                  label: dateLabel(context, AdvancedFilters(date: d)),
                  selected: f.date == d,
                  onTap: () => _f = f.copyWith(date: f.date == d ? DateRangeFilter.any : d, clearRange: true),
                ),
              AppFilterChip(
                label: f.date == DateRangeFilter.custom ? dateLabel(context, f) : l.inbox_filters_date_custom,
                selected: f.date == DateRangeFilter.custom,
                trailingIcon: AppIcons.chevronEnd,
                onTap: _pickRange,
              ),
            ]),
            header(l.inbox_filters_sort),
            for (final s in InboxSort.values)
              AppRadioRow(
                label: switch (s) {
                  InboxSort.smart => l.inbox_filters_sort_smart,
                  InboxSort.newest => l.inbox_filters_sort_newest,
                  InboxSort.oldest => l.inbox_filters_sort_oldest,
                  InboxSort.waiting => l.inbox_filters_sort_waiting,
                },
                selected: f.sort == s,
                onTap: () => _f = f.copyWith(sort: s),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}
