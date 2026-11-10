import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../domain/assignee.dart';
import 'assignee_tile.dart';

/// "✦ مقترح" — the recommended agent in a tinted container, with the reason
/// after the subtitle (Assign spec §5.5). Selection syncs with the list.
class SuggestedAssigneeRow extends StatelessWidget {
  const SuggestedAssigneeRow({
    super.key,
    required this.suggestion,
    required this.agent,
    required this.selected,
    required this.onTap,
    this.isMe = false,
  });

  final SuggestedAssignee suggestion;
  final AgentAssignee agent;
  final bool selected;
  final VoidCallback onTap;
  final bool isMe;

  static String reasonLabel(AppLocalizations l, SuggestedAssignee s, AgentAssignee a) {
    if (s.reasonLabel != null && s.reasonLabel!.isNotEmpty) return s.reasonLabel!;
    return switch (s.reason) {
      SuggestionReason.handledBefore => a.female ? l.as_reason_handled_f : l.as_reason_handled,
      SuggestionReason.skillMatch => () {
        final skill = s.skill ?? (a.skills.isEmpty ? '' : a.skills.first);
        return a.female ? l.as_reason_skill_f(skill) : l.as_reason_skill(skill);
      }(),
      SuggestionReason.leastBusy => l.as_reason_least,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 2),
          child: Semantics(
            header: true,
            child: Row(
              children: [
                Text(
                  l.as_suggested,
                  style: context.text.caption.copyWith(fontWeight: FontWeight.w700, color: c.textSecondary),
                ),
                const SizedBox(width: AppSpacing.xs),
                ExcludeSemantics(child: Icon(AppIcons.sparkle, size: 12, color: c.primary)),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: AssigneeTile.agent(
            agent: agent,
            isMe: isMe,
            selected: selected,
            onTap: onTap,
            reasonSuffix: reasonLabel(l, suggestion, agent),
          ),
        ),
      ],
    );
  }
}
