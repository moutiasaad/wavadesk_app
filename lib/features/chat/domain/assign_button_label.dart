import '../../../l10n/app_localizations.dart';
import 'assignee.dart';

/// §5.10 dynamic primary label (+ §6 "إعادة الإسناد إلى {x}" after a live
/// takeover).
String assignButtonLabel(
  AppLocalizations l, {
  required AssignTarget? target,
  required int count,
  bool takenLive = false,
  bool unassigned = true,
}) {
  if (target == null) return l.as_pick;
  final name = switch (target) {
    AgentTarget(:final agent, :final isMe) => isMe ? l.as_me : agent.firstName,
    TeamTarget(:final team) => team.name,
    AiTarget() => l.as_ai_name,
  };
  if (count > 1) return l.as_assign_bulk_to(count, name);
  if (takenLive) return l.as_reassign_to(name);
  return switch (target) {
    AgentTarget(isMe: true) when unassigned => l.as_claim,
    AgentTarget(isMe: true) => l.as_assign_to(l.as_me),
    AgentTarget() => l.as_assign_to(name),
    TeamTarget() => l.as_assign_to(name),
    AiTarget() => l.as_assign_ai,
  };
}
