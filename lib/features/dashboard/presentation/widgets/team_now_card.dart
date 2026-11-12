import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/greeting.dart';
import '../dash_palette.dart';
import '../sheets/agent_quick_sheet.dart';

/// Gendered presence label (متاح / مشغول / غير متاح).
String teamPresenceLabel(BuildContext context, TeamPresence p, String? gender) {
  final l = context.l10n;
  final f = Greeting.isFeminine(gender);
  return switch (p) {
    TeamPresence.online => f ? l.dash_presence_online_f : l.dash_presence_online_m,
    TeamPresence.busy => f ? l.dash_presence_busy_f : l.dash_presence_busy_m,
    TeamPresence.away => l.dash_presence_away,
  };
}

Color teamPresenceColor(TeamPresence p) => switch (p) {
      TeamPresence.online => DashPalette.online,
      TeamPresence.busy => DashPalette.busy,
      TeamPresence.away => DashPalette.away,
    };

/// Person avatar (40 / 50) with the spec presence dot ringed in [ring].
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({super.key, required this.member, this.size = 40, required this.ring});

  final TeamMember member;
  final double size;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final dot = size >= 50 ? 12.0 : 10.0;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(
            name: member.name,
            id: member.id,
            imageUrl: member.avatarUrl,
            size: size >= 50 ? AppAvatarSize.lg : AppAvatarSize.md,
          ),
          PositionedDirectional(
            bottom: -1,
            end: -1,
            child: Container(
              width: dot + 4,
              height: dot + 4,
              decoration: BoxDecoration(
                color: teamPresenceColor(member.presence),
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "الفريق الآن" (Dashboard v2 §4.4): horizontal people row ordered
/// available → busy → away (by open chats), max 8 then "+n", AI last.
class TeamNowCard extends ConsumerWidget {
  const TeamNowCard({super.key, required this.snapshot});

  final DashboardSnapshot snapshot;

  static const _maxPeople = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final p = DashPalette.of(context);
    final lead = ref.watch(currentAgentProvider).role != AgentRole.agent;

    final people = [...snapshot.teamNow]..sort((a, b) {
        final byPresence = a.presence.index.compareTo(b.presence.index);
        return byPresence != 0 ? byPresence : b.open.compareTo(a.open);
      });
    final shown = people.take(_maxPeople).toList();
    final extra = people.length - shown.length;
    final ai = snapshot.aiEnabled ? snapshot.aiHandling : null;

    final nameStyle = t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.textPrimary);
    final countStyle = t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.textSecondary);

    Widget item({required Widget avatar, required String name, required String count, String? a11y, VoidCallback? onTap}) => Semantics(
          button: onTap != null,
          label: a11y ?? '$name، $count',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  avatar,
                  const SizedBox(height: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 64),
                    child: Text(name, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 3),
                  Text(count, style: countStyle),
                ],
              ),
            ),
          ),
        );

    final items = <Widget>[
      for (final m in shown)
        item(
          avatar: TeamAvatar(member: m, ring: p.card),
          name: m.firstName,
          count: m.presence == TeamPresence.away ? '—' : '${m.open}',
          a11y: l.dash_a11y_team(m.name, teamPresenceLabel(context, m.presence, m.gender), '${m.open}'),
          onTap: () => showAgentQuickSheet(context, ref, m, canViewChats: lead),
        ),
      if (extra > 0)
        item(
          avatar: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceVariant, shape: BoxShape.circle),
            child: Text('+$extra', style: t.bodySmall.copyWith(fontWeight: FontWeight.w800, color: c.textSecondary)),
          ),
          name: l.dash_more_team('$extra'),
          count: '',
          onTap: lead ? () => context.push(Routes.team) : null,
        ),
      if (ai != null)
        item(
          avatar: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.aiBg, shape: BoxShape.circle),
            child: AppIcon(AppIcons.ai, dp: 20, color: c.primary),
          ),
          name: l.dash_ai_name,
          count: '$ai',
        ),
    ];

    return DashCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l.dash_team_now, style: t.h6.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
                ),
              ),
              if (lead)
                InkWell(
                  onTap: () => context.push(Routes.team),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Center(
                      child: Text(l.dash_see_all, style: t.bodySmall.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.primary)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    items[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
