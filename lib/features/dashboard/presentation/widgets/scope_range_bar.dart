import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/dashboard_controller.dart';
import '../../domain/dashboard_snapshot.dart';

String rangeLabel(AppLocalizations l, DashboardRange r) => switch (r) {
      DashboardRange.today => l.dash_range_today,
      DashboardRange.yesterday => l.dash_range_yesterday,
      DashboardRange.last7 => l.dash_range_7d,
      DashboardRange.last30 => l.dash_range_30d,
    };

/// Scope segmented (owner / admin / lead) + range chip (spec §4.2).
class ScopeRangeBar extends ConsumerWidget {
  const ScopeRangeBar({super.key, required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ctrl = ref.read(dashboardControllerProvider.notifier);
    final perms = state.snapshot?.permissions;
    final scopes = perms?.scopes ?? const [DashboardScope.me];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 6, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          if (perms != null && perms.showScopes)
            Expanded(
              child: AppSegmented<DashboardScope>(
                height: 36,
                selected: state.scope,
                segments: [
                  for (final s in scopes)
                    AppSegment(
                      value: s,
                      label: switch (s) {
                        DashboardScope.me => l.dash_scope_me,
                        DashboardScope.team => l.dash_scope_team,
                        DashboardScope.workspace => l.dash_scope_all,
                      },
                    ),
                ],
                onChanged: (s) async {
                  // Leads in several teams pick one (§4.2).
                  if (s == DashboardScope.team && perms.teams.length > 1) {
                    final team = await _pickTeam(context, perms.teams, state.teamId);
                    if (team != null) ctrl.setScope(s, teamId: team.id);
                    return;
                  }
                  ctrl.setScope(s);
                },
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: AppSpacing.sm),
          _RangeChip(range: state.range, onPick: ctrl.setRange),
        ],
      ),
    );
  }

  static Future<DashboardTeamRef?> _pickTeam(BuildContext context, List<DashboardTeamRef> teams, String? current) {
    return AppBottomSheet.show<DashboardTeamRef>(
      context,
      title: context.l10n.dash_team_picker,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in teams)
            ListTile(
              title: Text(t.name, style: ctx.text.listTitle),
              trailing: t.id == current ? AppIcon(AppIcons.check, color: ctx.colors.primary) : null,
              onTap: () => Navigator.of(ctx).pop(t),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.range, required this.onPick});

  final DashboardRange range;
  final ValueChanged<DashboardRange> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Material(
      color: c.surface,
      shape: StadiumBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () async {
          final picked = await AppBottomSheet.show<DashboardRange>(
            context,
            title: l.dash_range_title,
            builder: (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in DashboardRange.values)
                  ListTile(
                    title: Text(rangeLabel(l, r), style: ctx.text.listTitle),
                    trailing: r == range ? AppIcon(AppIcons.check, color: ctx.colors.primary) : null,
                    onTap: () => Navigator.of(ctx).pop(r),
                  ),
              ],
            ),
          );
          if (picked != null) onPick(picked);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rangeLabel(l, range), style: t.chipLabel),
                const SizedBox(width: AppSpacing.xs),
                AppIcon(AppIcons.chevronDown, size: AppIconSize.sm, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
