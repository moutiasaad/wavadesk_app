import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/search_query.dart';

/// Search filters (Search spec §7): channel · date · sender · status ·
/// assignee · contains, pinned "عرض النتائج (n)" with a live count.
Future<SearchFilters?> showSearchFiltersSheet(
  BuildContext context, {
  required SearchFilters initial,
  required Future<int> Function(SearchFilters f) count,
}) {
  final draft = ValueNotifier<SearchFilters>(initial);
  final total = ValueNotifier<int?>(null);
  Timer? debounce;
  var seq = 0;
  void recount() {
    debounce?.cancel();
    total.value = null;
    debounce = Timer(const Duration(milliseconds: 300), () async {
      final s = ++seq;
      final n = await count(draft.value);
      if (s == seq) total.value = n;
    });
  }

  draft.addListener(recount);
  recount();
  final l = context.l10n;
  return AppBottomSheet.showExpanded<SearchFilters>(
    context,
    title: l.search_filters,
    initialSize: 0.82,
    headerTrailing: ValueListenableBuilder<SearchFilters>(
      valueListenable: draft,
      builder: (ctx, f, _) => AppButton(
        label: l.search_clear,
        variant: AppButtonVariant.text,
        size: AppButtonSize.small,
        onPressed: f.isEmpty ? null : () => draft.value = SearchFilters.empty,
      ),
    ),
    action: ValueListenableBuilder<int?>(
      valueListenable: total,
      builder: (ctx, n, _) => AppButton(
        label: l.search_show_results(n ?? 0),
        size: AppButtonSize.large,
        expand: true,
        loading: n == null,
        onPressed: () => Navigator.of(ctx).pop(draft.value),
      ),
    ),
    builder: (ctx, controller) => ValueListenableBuilder<SearchFilters>(
      valueListenable: draft,
      builder: (ctx, f, _) => _Body(filters: f, onChanged: (v) => draft.value = v, controller: controller),
    ),
  ).whenComplete(() {
    debounce?.cancel();
    draft.dispose();
    total.dispose();
  });
}

class _Body extends ConsumerWidget {
  const _Body({required this.filters, required this.onChanged, required this.controller});

  final SearchFilters filters;
  final ValueChanged<SearchFilters> onChanged;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final f = filters;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: context.text.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
            ),
          ),
          Wrap(spacing: AppSpacing.sm, runSpacing: -8, children: [child]),
        ],
      ),
    );

    Widget chips<T>(List<(T, String)> items, bool Function(T) isOn, void Function(T) tap) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: -8,
      children: [for (final (v, label) in items) AppFilterChip(label: label, selected: isOn(v), onTap: () => tap(v))],
    );

    final colleagues = ref.watch(colleaguesProvider);
    final colleague = colleagues.where((a) => a.id == f.colleagueId).firstOrNull;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
      children: [
        section(
          l.search_filter_channel,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: -8,
            children: [
              for (final ch in Channel.values.where((x) => x != Channel.other))
                AppFilterChip(
                  label: ch.label(l),
                  leading: AppIcon(ch.glyph, size: AppIconSize.xs, color: f.channels.contains(ch) ? c.onSecondary : ch.brand(c)),
                  selected: f.channels.contains(ch),
                  onTap: () {
                    final next = {...f.channels};
                    next.contains(ch) ? next.remove(ch) : next.add(ch);
                    onChanged(f.copyWith(channels: next));
                  },
                ),
            ],
          ),
        ),
        section(
          l.search_filter_date,
          chips<SearchDateRange>(
            [
              (SearchDateRange.any, l.search_date_any),
              (SearchDateRange.today, l.search_date_today),
              (SearchDateRange.days7, l.search_date_7),
              (SearchDateRange.days30, l.search_date_30),
              (
                SearchDateRange.custom,
                f.date == SearchDateRange.custom && f.from != null
                    ? '${AppFormat.date(context, f.from!)} – ${AppFormat.date(context, f.to ?? f.from!)}'
                    : '${l.search_date_custom} ▸',
              ),
            ],
            (v) => f.date == v,
            (v) async {
              if (v != SearchDateRange.custom) return onChanged(f.copyWith(date: v));
              final now = DateTime.now();
              final r = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 3),
                lastDate: now,
                initialDateRange: f.from == null ? null : DateTimeRange(start: f.from!, end: f.to ?? f.from!),
              );
              if (r != null) onChanged(f.copyWith(date: SearchDateRange.custom, from: r.start, to: r.end));
            },
          ),
        ),
        section(
          l.search_filter_sender,
          chips<SearchSender>(
            [
              (SearchSender.all, l.search_sender_all),
              (SearchSender.contact, l.search_sender_contact),
              (SearchSender.me, l.search_sender_me),
              (SearchSender.colleagues, l.search_sender_colleagues),
              (SearchSender.ai, l.search_sender_ai),
              (SearchSender.notes, l.search_sender_notes),
            ],
            (v) => f.sender == v,
            (v) => onChanged(f.copyWith(sender: v)),
          ),
        ),
        section(
          l.search_filter_status,
          chips<SearchStatusFilter>(
            [
              (SearchStatusFilter.all, l.search_status_all),
              (SearchStatusFilter.open, l.search_status_open),
              (SearchStatusFilter.resolved, l.search_status_resolved),
            ],
            (v) => f.status == v,
            (v) => onChanged(f.copyWith(status: v)),
          ),
        ),
        section(
          l.search_filter_assignee,
          chips<SearchAssigneeFilter>(
            [
              (SearchAssigneeFilter.all, l.search_assignee_all),
              (SearchAssigneeFilter.me, l.search_assignee_me),
              (SearchAssigneeFilter.colleague, colleague == null ? '${l.search_assignee_colleague} ▸' : colleague.name),
            ],
            (v) => f.assignee == v,
            (v) async {
              if (v != SearchAssigneeFilter.colleague) return onChanged(f.copyWith(assignee: v, clearColleague: true));
              final picked = await AppBottomSheet.show<Agent>(
                context,
                title: l.search_assignee_colleague,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final a in colleagues)
                      SheetActionRow(
                        icon: AppIcons.customer,
                        label: a.name,
                        selected: a.id == f.colleagueId,
                        onTap: () => Navigator.of(ctx).pop(a),
                      ),
                  ],
                ),
              );
              if (picked != null) {
                onChanged(f.copyWith(assignee: SearchAssigneeFilter.colleague, colleagueId: picked.id));
              }
            },
          ),
        ),
        section(
          l.search_filter_contains,
          chips<SearchContains>(
            [
              (SearchContains.attachments, l.search_filter_attachments),
              (SearchContains.images, l.search_filter_images),
              (SearchContains.voice, l.search_filter_voice),
            ],
            (v) => f.contains.contains(v),
            (v) {
              final next = {...f.contains};
              next.contains(v) ? next.remove(v) : next.add(v);
              onChanged(f.copyWith(contains: next));
            },
          ),
        ),
      ],
    );
  }
}
