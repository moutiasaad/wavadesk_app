import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/analytics.dart';
import '../../../../core/utils/l10n.dart';
import '../../domain/dashboard_snapshot.dart';
import '../../domain/greeting.dart';
import '../../domain/metric_formatters.dart';
import '../../../../core/widgets/widgets.dart';
import 'team_member_sheet.dart';

/// Gendered presence label (Dashboard spec §4.1 / §4.6).
String teamPresenceLabel(BuildContext context, TeamPresence p, String? gender) {
  final l = context.l10n;
  final f = Greeting.isFeminine(gender);
  return switch (p) {
    TeamPresence.online => f ? l.dash_presence_online_f : l.dash_presence_online_m,
    TeamPresence.busy => f ? l.dash_presence_busy_f : l.dash_presence_busy_m,
    TeamPresence.away => l.dash_presence_away,
  };
}

/// Core [Presence] for the avatar dot.
Presence teamPresenceDot(TeamPresence p) => switch (p) {
      TeamPresence.online => Presence.online,
      TeamPresence.busy => Presence.busy,
      TeamPresence.away => Presence.away,
    };

/// "الفريق الآن" (Dashboard spec §4.6).
class TeamNowCard extends ConsumerWidget {
  const TeamNowCard({super.key, required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final members = snapshot.teamNow;
    final solo = members.length <= 1;
    final rings = snapshot.permissions.canRedistribute;
    final big = MediaQuery.textScalerOf(context).scale(1) >= 1.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
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
              AppButton(
                label: l.dash_see_all,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                onPressed: () => context.push(Routes.team),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (solo)
            Row(
              children: [
                Expanded(child: Text(l.dash_solo, style: t.bodySmall.copyWith(color: c.textSecondary))),
                AppButton(
                  label: l.dash_invite,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  onPressed: () => context.push(Routes.team),
                ),
              ],
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final m in members) ...[
                    _MemberItem(
                      member: m,
                      ring: rings,
                      twoLines: big,
                      onTap: () {
                        Analytics.log('dash_team_tap', {'is_ai': false, 'presence': m.presence.name});
                        showTeamMemberSheet(context, ref, m, canRedistribute: rings);
                      },
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (snapshot.aiHandling != null)
                    _AiItem(
                      count: snapshot.aiHandling!,
                      twoLines: big,
                      onTap: () {
                        Analytics.log('dash_team_tap', {'is_ai': true, 'presence': null});
                        context.push(Routes.aiAgent);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({required this.member, required this.ring, required this.twoLines, required this.onTap});

  final TeamMember member;
  final bool ring;
  final bool twoLines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final m = member;
    final away = m.presence == TeamPresence.away;
    final load = m.load;
    final ringColor = !ring || load == null
        ? null
        : load >= 0.9
            ? c.error
            : load >= 0.6
                ? c.warning
                : c.success;

    Widget avatar = AppAvatar(
      name: m.name,
      id: m.id,
      imageUrl: m.avatarUrl,
      presence: teamPresenceDot(m.presence),
      ringColor: c.surface,
    );
    avatar = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? Colors.transparent, width: 2),
      ),
      child: avatar,
    );

    return Semantics(
      button: true,
      label: l.dash_a11y_team(m.firstName, teamPresenceLabel(context, m.presence, m.gender), MetricFormat.grouped(m.open)),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              avatar,
              const SizedBox(height: 3),
              Text(
                m.firstName,
                style: t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
                maxLines: twoLines ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                away ? '—' : MetricFormat.grouped(m.open),
                style: t.caption.copyWith(color: c.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiItem extends StatelessWidget {
  const _AiItem({required this.count, required this.twoLines, required this.onTap});

  final int count;
  final bool twoLines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: '${l.dash_ai_name}، ${l.dash_ai_handling(MetricFormat.grouped(count))}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                  child: AppIcon(AppIcons.ai, dp: 18, color: c.primary),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l.dash_ai_name,
                style: t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700),
                maxLines: twoLines ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                MetricFormat.grouped(count),
                style: t.caption.copyWith(color: c.textSecondary, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
