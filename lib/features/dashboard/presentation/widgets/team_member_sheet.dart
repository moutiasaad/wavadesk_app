import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../chat/domain/assignee.dart';
import '../../../chat/presentation/sheets/assign/assign_sheet.dart';
import '../../../conversations/application/conversation_filters_controller.dart';
import '../../../conversations/data/conversations_repository.dart';
import '../../../conversations/domain/conversation_filters.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/metric_formatters.dart';
import 'team_now_card.dart';

/// Inbox advanced filters showing [m]'s conversations.
AdvancedFilters _filtersFor(TeamMember m, AdvancedFilters base) => m.isMe
    ? base.copyWith(assignee: AssigneeFilter.me, clearColleague: true)
    : base.copyWith(assignee: AssigneeFilter.colleague, colleagueId: m.id);

/// Agent quick sheet (Dashboard spec §4.6): who, status, load, today's first
/// response; "view their conversations" and (leads) "redistribute".
Future<void> showTeamMemberSheet(BuildContext context, WidgetRef ref, TeamMember member, {required bool canRedistribute}) {
  return AppBottomSheet.show<void>(
    context,
    builder: (sheetContext) {
      final c = sheetContext.colors;
      final t = sheetContext.text;
      final l = sheetContext.l10n;
      final m = member;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Row(
                children: [
                  AppAvatar(
                    name: m.name,
                    id: m.id,
                    imageUrl: m.avatarUrl,
                    size: AppAvatarSize.lg,
                    presence: teamPresenceDot(m.presence),
                    ringColor: c.surfaceElevated,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: t.h5, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(teamPresenceLabel(sheetContext, m.presence, m.gender), style: t.bodySmall.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: Text(l.dash_agent_open(MetricFormat.grouped(m.open)), style: t.bodyMedium),
            ),
            if (m.avgFirstResponseToday != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: Text(
                  l.dash_agent_frt(MetricFormat.duration(m.avgFirstResponseToday!, hourUnit: l.dash_hours_short, minuteUnit: l.dash_minutes_short)),
                  style: t.bodyMedium.copyWith(color: c.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            SheetActionRow(
              icon: AppIcons.inbox,
              label: l.dash_agent_view,
              onTap: () {
                Navigator.of(sheetContext).pop();
                final filters = ref.read(conversationFiltersProvider.notifier);
                filters.setSegment(InboxSegment.all);
                filters.setChip(QuickChip.all);
                filters.setAdvanced(_filtersFor(m, ref.read(conversationFiltersProvider).advanced));
                context.go(Routes.conversations);
              },
            ),
            if (canRedistribute && m.open > 0)
              SheetActionRow(
                icon: AppIcons.assign,
                label: l.dash_redistribute,
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _redistribute(context, ref, m);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// Bulk assign of [m]'s open conversations (the same query the inbox uses,
/// so sample and API modes both work).
Future<void> _redistribute(BuildContext context, WidgetRef ref, TeamMember m) async {
  final l = context.l10n;
  List<String> ids;
  try {
    final page = await ref.read(conversationsRepositoryProvider).fetch(
          InboxQuery(segment: InboxSegment.all, advanced: _filtersFor(m, AdvancedFilters.empty)),
          limit: 50,
        );
    ids = [for (final c in page.items) if (c.isActive) c.id];
  } catch (_) {
    if (context.mounted) AppSnackbar.show(context, message: l.dash_card_error, kind: SnackKind.error);
    return;
  }
  if (!context.mounted) return;
  if (ids.isEmpty) {
    AppSnackbar.show(context, message: l.dash_redistribute_none);
    return;
  }
  Analytics.log('dash_redistribute', {'count': ids.length});
  await showAssignSheet(context, ref, conversationIds: ids, source: AssignSource.bulk);
}
