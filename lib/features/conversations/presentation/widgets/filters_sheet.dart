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
import 'inbox_palette.dart';

/// Label for the assignee filter chip/row.
String assigneeLabel(AppLocalizations l, AdvancedFilters f, List<Agent> colleagues) => switch (f.assignee) {
  AssigneeFilter.all => l.inbox_filters_assignee_all,
  AssigneeFilter.me => l.inbox_filters_assignee_me,
  AssigneeFilter.colleague =>
    colleagues.where((a) => a.id == f.colleagueId).firstOrNull?.name ?? l.inbox_filters_assignee_colleague,
  AssigneeFilter.ai => l.inbox_filters_assignee_ai,
  AssigneeFilter.unassigned => l.inbox_filters_assignee_unassigned,
};

String statusLabel(AppLocalizations l, StatusFilter s) => switch (s) {
  StatusFilter.open => l.inbox_st_open,
  StatusFilter.pending => l.inbox_st_pending,
  StatusFilter.snoozed => l.inbox_st_snoozed,
  StatusFilter.closed => l.inbox_st_closed,
};

String aiLabel(AppLocalizations l, AiFilter a) => switch (a) {
  AiFilter.any => '',
  AiFilter.handled => l.inbox_ai_handled,
  AiFilter.escalated => l.inbox_ai_escalated,
  AiFilter.untouched => l.inbox_ai_untouched,
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

/// Advanced filters (Inbox v2 §6.1), 90% height. Edits a draft; nothing
/// applies until the sticky "عرض {n} محادثة" button is pressed; "إعادة
/// تعيين" under it clears the draft only.
Future<void> showInboxFiltersSheet(BuildContext context, WidgetRef ref) {
  final query = ref.read(conversationFiltersProvider);
  final draft = ValueNotifier<AdvancedFilters>(query.advanced);
  return AppBottomSheet.showExpanded<void>(
    context,
    initialSize: 0.9,
    title: context.l10n.inbox_flt_title,
    showClose: false,
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

  /// Live count, debounced 300ms.
  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _fetch);
  }

  Future<void> _fetch() async {
    try {
      final n = await ref.read(conversationsRepositoryProvider).count(widget.query.copyWith(advanced: widget.draft.value));
      if (mounted) setState(() => _count = n);
    } catch (_) {
      if (mounted) setState(() => _count = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final show = SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: context.text.buttonLarge,
        ),
        onPressed: () {
          ref.read(conversationFiltersProvider.notifier).setAdvanced(widget.draft.value);
          Navigator.of(context).pop();
        },
        child: Text(_count == null ? l.inbox_filters_apply : l.inbox_filters_show(_count!)),
      ),
    );
    // Resets the sheet only; applying still needs the button above.
    final reset = ValueListenableBuilder<AdvancedFilters>(
      valueListenable: widget.draft,
      builder: (context, f, _) => SizedBox(
        height: 44,
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: c.error,
            disabledForegroundColor: c.textTertiary,
            side: BorderSide(color: f.activeCount > 0 ? c.error.withValues(alpha: 0.4) : c.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: context.text.buttonMedium,
          ),
          onPressed: f.activeCount > 0 ? () => widget.draft.value = AdvancedFilters.empty : null,
          icon: AppIcon(AppIcons.reopen, size: AppIconSize.sm, color: f.activeCount > 0 ? c.error : c.textTertiary),
          label: Text(l.inbox_flt_reset),
        ),
      ),
    );
    return Column(mainAxisSize: MainAxisSize.min, children: [show, const SizedBox(height: AppSpacing.sm), reset]);
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
  bool _allTags = false;

  AdvancedFilters get _f => widget.draft.value;
  set _f(AdvancedFilters v) => widget.draft.value = v;

  Set<T> _toggle<T>(Set<T> set, T v) => set.contains(v) ? ({...set}..remove(v)) : {...set, v};

  Future<void> _pickColleague() async {
    final colleagues = ref.read(colleaguesProvider);
    var query = '';
    final picked = await AppBottomSheet.show<Agent>(
      context,
      title: context.l10n.inbox_filters_pick_colleague,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final shown = query.isEmpty
              ? colleagues
              : colleagues.where((a) => a.name.toLowerCase().contains(query.toLowerCase())).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: AppSearchField(
                  hint: ctx.l10n.common_search,
                  showCancel: false,
                  onChanged: (v) => setSheet(() => query = v),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final a in shown)
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
          );
        },
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
    final teams = ref.watch(teamsProvider);
    final tags = ref.watch(allTagsProvider);
    final colleagues = ref.watch(colleaguesProvider);

    Widget header(String text) => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Semantics(header: true, child: Text(text, style: t.h6.copyWith(fontWeight: FontWeight.w800))),
        );
    Widget wrap(List<Widget> children) => Wrap(spacing: 8, runSpacing: 8, children: children);

    return ValueListenableBuilder<AdvancedFilters>(
      valueListenable: widget.draft,
      builder: (context, f, _) {
        final shownTags = _allTags || tags.length <= 12 ? tags : tags.take(12).toList();
        return ListView(
          controller: widget.controller,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          children: [
            header(l.inbox_flt_status),
            wrap([
              for (final s in StatusFilter.values)
                _SheetChip(
                  label: statusLabel(l, s),
                  selected: f.statuses.contains(s),
                  onTap: () => _f = f.copyWith(statuses: _toggle(f.statuses, s)),
                ),
            ]),
            header(l.inbox_filters_channel),
            wrap([
              for (final ch in const [Channel.whatsapp, Channel.web, Channel.instagram, Channel.messenger])
                _SheetChip(
                  label: ch.label(l),
                  selected: f.channels.contains(ch),
                  onTap: () => _f = f.copyWith(channels: _toggle(f.channels, ch)),
                ),
            ]),
            if (widget.segment == InboxSegment.all) ...[
              header(l.inbox_flt_assignee),
              wrap([
                for (final a in const [AssigneeFilter.all, AssigneeFilter.me, AssigneeFilter.unassigned])
                  _SheetChip(
                    label: assigneeLabel(l, AdvancedFilters(assignee: a), colleagues),
                    selected: f.assignee == a,
                    onTap: () => _f = f.copyWith(assignee: a, clearColleague: true),
                  ),
                _SheetChip(
                  label: f.assignee == AssigneeFilter.colleague
                      ? assigneeLabel(l, f, colleagues)
                      : l.inbox_filters_assignee_colleague,
                  selected: f.assignee == AssigneeFilter.colleague,
                  onTap: _pickColleague,
                ),
              ]),
            ],
            if (teams.isNotEmpty) ...[
              header(l.inbox_filters_team),
              wrap([
                for (final team in teams)
                  _SheetChip(
                    label: team.name,
                    selected: f.teamIds.contains(team.id),
                    onTap: () => _f = f.copyWith(teamIds: _toggle(f.teamIds, team.id)),
                  ),
              ]),
            ],
            if (tags.isNotEmpty) ...[
              header(l.inbox_filters_tags),
              wrap([
                for (final tag in shownTags)
                  _SheetChip(
                    label: tag,
                    selected: f.tags.contains(tag),
                    onTap: () => _f = f.copyWith(tags: _toggle(f.tags, tag)),
                  ),
                if (!_allTags && tags.length > 12)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      textStyle: t.buttonSmall,
                      minimumSize: const Size(48, 36),
                    ),
                    onPressed: () => setState(() => _allTags = true),
                    child: Text(l.inbox_see_all),
                  ),
              ]),
            ],
            header(l.inbox_filters_priority),
            wrap([
              for (final p in const [Priority.high, Priority.medium, Priority.low])
                _SheetChip(
                  label: p.label(l),
                  selected: f.priorities.contains(p),
                  onTap: () => _f = f.copyWith(priorities: _toggle(f.priorities, p)),
                ),
            ]),
            header(l.inbox_flt_ai),
            wrap([
              // One choice: the server filters one AI state at a time.
              for (final a in const [AiFilter.handled, AiFilter.escalated, AiFilter.untouched])
                _SheetChip(
                  label: aiLabel(l, a),
                  selected: f.ai == a,
                  onTap: () => _f = f.copyWith(ai: f.ai == a ? AiFilter.any : a),
                ),
            ]),
            header(l.inbox_filters_date),
            wrap([
              for (final d in const [DateRangeFilter.today, DateRangeFilter.last7, DateRangeFilter.last30])
                _SheetChip(
                  label: dateLabel(context, AdvancedFilters(date: d)),
                  selected: f.date == d,
                  onTap: () => _f = f.copyWith(date: f.date == d ? DateRangeFilter.any : d, clearRange: true),
                ),
              _SheetChip(
                label: f.date == DateRangeFilter.custom ? dateLabel(context, f) : l.inbox_filters_date_custom,
                selected: f.date == DateRangeFilter.custom,
                onTap: _pickRange,
              ),
            ]),
            header(l.inbox_filters_sort),
            for (final (s, label) in [
              (InboxSort.newest, l.inbox_sort_newest),
              (InboxSort.oldest, l.inbox_sort_oldest),
              (InboxSort.priority, l.inbox_sort_priority),
            ])
              AppRadioRow(
                label: label,
                selected: f.sort == s || (s == InboxSort.newest && (f.sort == InboxSort.smart)),
                onTap: () => _f = f.copyWith(sort: s),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

/// Sheet chip (§6.1): h36, radius full; selected = green with a 14 check.
class _SheetChip extends StatelessWidget {
  const _SheetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = InboxPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? p.pillSel : p.pill,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: selected ? p.pillSelBorder : p.pillBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[AppIcon(AppIcons.check, dp: 14, color: p.pillSelText), const SizedBox(width: 5)],
              Text(
                label,
                style: context.text.bodySmall.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? p.pillSelText : p.pillText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
