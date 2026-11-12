import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../conversations/application/conversation_filters_controller.dart';
import '../../../conversations/domain/conversation_filters.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/duration_format.dart';
import '../widgets/team_now_card.dart';
import 'response_time_sheet.dart';

/// Inbox advanced filters showing [m]'s conversations.
AdvancedFilters _filtersFor(TeamMember m, AdvancedFilters base) => m.isMe
    ? base.copyWith(assignee: AssigneeFilter.me, clearColleague: true)
    : base.copyWith(assignee: AssigneeFilter.colleague, colleagueId: m.id);

/// Agent quick sheet (Dashboard v2 §4.4): name, presence, open chats, avg
/// first reply today, and "عرض محادثاته" (leads / admins only).
Future<void> showAgentQuickSheet(BuildContext context, WidgetRef ref, TeamMember member, {required bool canViewChats}) {
  return AppBottomSheet.show<void>(
    context,
    builder: (sheetContext) {
      final c = sheetContext.colors;
      final t = sheetContext.text;
      final l = sheetContext.l10n;
      final m = member;
      final frt = m.avgFirstResponseToday == null ? null : DurationFormat.of(m.avgFirstResponseToday!);
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
                  TeamAvatar(member: m, size: 50, ring: c.surfaceElevated),
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
              child: Text(l.dash_agent_open('${m.open}'), style: t.bodyMedium),
            ),
            if (frt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                child: Text(
                  l.dash_agent_frt('${frt.$1} ${durationUnitLabel(l, frt.$2)}'),
                  style: t.bodyMedium.copyWith(color: c.textSecondary),
                ),
              ),
            ],
            if (canViewChats) ...[
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
            ],
          ],
        ),
      );
    },
  );
}
