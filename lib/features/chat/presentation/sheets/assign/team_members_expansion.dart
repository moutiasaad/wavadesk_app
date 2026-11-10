import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/assignee.dart';
import '../../../domain/assignee_sorter.dart';
import 'assignee_tile.dart';

/// Inline member list under a team row, indented 52dp; picking a member
/// selects that agent (Assign spec §5.7). Size + fade 200ms.
class TeamMembersExpansion extends StatelessWidget {
  const TeamMembersExpansion({
    super.key,
    required this.team,
    required this.expanded,
    required this.meId,
    required this.selectedKey,
    required this.onSelect,
    required this.isCurrent,
    this.query = '',
  });

  final TeamAssignee team;
  final bool expanded;
  final String meId;
  final String? selectedKey;
  final void Function(AgentAssignee a) onSelect;
  final bool Function(AgentAssignee a) isCurrent;
  final String query;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final members = AssigneeSorter.sort(team.members);
    return AnimatedSize(
      duration: reduced ? Duration.zero : AppMotion.normal,
      curve: AppMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: AnimatedOpacity(
        opacity: expanded ? 1 : 0,
        duration: reduced ? Duration.zero : AppMotion.normal,
        child: !expanded
            ? const SizedBox(width: double.infinity)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final m in members)
                    AssigneeTile.agent(
                      agent: m,
                      isMe: m.id == meId,
                      selected: selectedKey == 'agent:${m.id}',
                      isCurrent: isCurrent(m),
                      query: query,
                      indent: 52,
                      onTap: () => onSelect(m),
                    ),
                ],
              ),
      ),
    );
  }
}
