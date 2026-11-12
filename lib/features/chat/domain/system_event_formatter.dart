import '../../../core/models/models.dart';
import '../../../l10n/app_localizations.dart';

/// System-event copy (Chat spec §9). Uses "أنت" forms when the actor is the
/// signed-in agent ("استلمت المحادثة", "أسندت المحادثة إلى سارة").
abstract final class SystemEventFormatter {
  static String format(
    SystemEvent e, {
    required AppLocalizations l,
    required String meId,
    String Function(DateTime t)? formatTime,
    String Function(String priorityName)? priorityLabel,
    String Function(String channelName)? channelLabel,
  }) {
    final me = e.actorId != null && e.actorId == meId;
    final actor = e.actorName ?? '';
    final target = e.target ?? '';
    final value = e.value ?? '';
    return switch (e.kind) {
      SystemEventKind.claimed => me ? l.sys_claimed_me : l.sys_claimed(actor),
      SystemEventKind.assigned => me ? l.sys_assigned_me(target) : l.sys_assigned(actor, target),
      SystemEventKind.unassigned => me ? l.sys_unassigned_me : l.sys_unassigned(actor),
      SystemEventKind.aiHandoff => l.sys_ai_handoff(handoffReason(value, l)),
      SystemEventKind.aiPaused => me ? l.sys_ai_paused_me : l.sys_ai_paused(actor),
      SystemEventKind.aiResumed => me ? l.sys_ai_resumed_me : l.sys_ai_resumed(actor),
      SystemEventKind.resolved => me ? l.sys_resolved_me : l.sys_resolved(actor),
      SystemEventKind.reopened => l.sys_reopened,
      SystemEventKind.snoozed => () {
        final t = DateTime.tryParse(value);
        final when = t == null ? value : (formatTime?.call(t) ?? value);
        return me ? l.sys_snoozed_me(when) : l.sys_snoozed(actor, when);
      }(),
      SystemEventKind.priority => () {
        final label = priorityLabel?.call(value) ?? value;
        return me ? l.sys_priority_me(label) : l.sys_priority(actor, label);
      }(),
      SystemEventKind.tagAdded => me ? l.sys_tag_added_me(value) : l.sys_tag_added(actor, value),
      SystemEventKind.windowClosed => l.sys_window_closed,
      SystemEventKind.blocked => me ? l.sys_blocked_me : l.sys_blocked(actor),
      SystemEventKind.unblocked => me ? l.sys_unblocked_me : l.sys_unblocked(actor),
      SystemEventKind.started => l.sys_started(channelLabel?.call(value) ?? value),
      SystemEventKind.called => me ? l.sys_called_me : l.sys_called(actor),
      SystemEventKind.assignUndone => l.as_event_undo(me ? l.common_you : actor),
    };
  }

  /// API `ai_handoff.reason_code` → copy (Claim spec §5.1); free text
  /// (sample data / older servers) is shown as is.
  static String handoffReason(String value, AppLocalizations l) => switch (value) {
    'payment' => l.claim_reason_payment,
    'human' => l.claim_reason_human,
    'complaint' => l.claim_reason_complaint,
    'no_answer' => l.claim_reason_no_answer,
    'refund' => l.claim_reason_refund,
    'low_confidence' => l.claim_reason_low_conf,
    'keyword' => l.claim_reason_keyword,
    'other' => l.claim_reason_other,
    _ => value,
  };
}
