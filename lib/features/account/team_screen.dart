import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/data.dart';
import '../../core/data/team_directory.dart';
import '../../core/models/models.dart';
import '../../core/state/load_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import 'team_create_sheets.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  @override
  void initState() {
    super.initState();
    // Last list at once (kept by the provider), fresh one quietly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(teamDirectoryProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final me = ref.watch(currentAgentProvider);
    final dir = ref.watch(teamDirectoryProvider);
    // The signed-in user first, with the presence picked on the Account tab.
    final mine = dir.members.where((a) => a.id == dir.meId).firstOrNull;
    final agents = [
      me.copyWith(openConversations: mine?.openConversations),
      for (final a in dir.members)
        if (a.id != me.id && a.id != dir.meId) a,
    ];
    final teams = dir.teams;

    return ScrolledUnderBuilder(
      builder: (context, under) => Scaffold(
        backgroundColor: c.backgroundMuted,
        appBar: AppBarStandard(
          title: l.team_title,
          scrolledUnder: under,
          background: c.backgroundMuted,
          actions: [
            // Admins only, like the web Users / Teams pages.
            if (me.role == AgentRole.admin)
              AppIconButton(
                icon: AppIcons.add,
                semanticLabel: l.team_add,
                onPressed: () => showTeamAddMenu(context),
              ),
          ],
        ),
        body: LoadSwitcher(
          phase: dir.phase,
          isEmpty: false,
          skeleton: (_) => AppSkeleton.list(rows: 6),
          error: (_) => EmptyState(
            icon: AppIcons.offline,
            title: l.account_load_error,
            actionLabel: l.common_retry,
            onAction: ref.read(teamDirectoryProvider.notifier).refresh,
          ),
          empty: (_) => const SizedBox.shrink(),
          content: (_) => RefreshIndicator(
            color: c.primary,
            onRefresh: ref.read(teamDirectoryProvider.notifier).refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: AppSpacing.xxl + MediaQuery.viewPaddingOf(context).bottom),
              children: [
                SettingsGroup(
                  title: l.team_section_members(agents.length),
                  children: [
                    for (final a in agents)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            AppAvatar(name: a.name, id: a.id, presence: a.presence, ringColor: c.surface),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.id == me.id ? l.team_you(a.name) : a.name, style: t.listTitle),
                                  Text(
                                    '${a.role.label(l)} · ${a.presence.label(l)}',
                                    style: t.bodySmall.copyWith(color: c.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              l.dashboard_team_open(a.openConversations),
                              style: t.caption.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (teams.isNotEmpty)
                  SettingsGroup(
                    title: l.team_section_teams,
                    children: [
                      for (final team in teams)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
                          child: Row(
                            children: [
                              const AppAvatar.team(),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: Text(team.name, style: t.listTitle)),
                              Text(l.team_members(team.memberCount), style: t.caption.copyWith(color: c.textSecondary)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
