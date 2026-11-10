import '../../../l10n/app_localizations.dart';
import 'notification.dart';

/// Notification types (Notifications spec §5). [NotificationType.unknown]
/// renders as a generic row with the server title/body (§5 last bullet).
enum NotificationType {
  assigned('assigned'),
  claimNeeded('claim_needed'),
  slaBreach('sla_breach'),
  transferRequest('transfer_request'),
  mention('mention'),
  aiNoAnswer('ai_no_answer'),
  aiHandoff('ai_handoff'),
  aiLowConfidence('ai_low_confidence'),
  kbSuggestion('kb_suggestion'),
  channelDisconnected('channel_disconnected'),
  channelReconnected('channel_reconnected'),
  channelQualityLow('channel_quality_low'),
  teamJoined('team_joined'),
  teamRoleChanged('team_role_changed'),
  trialEnding('trial_ending'),
  paymentFailed('payment_failed'),
  planLimit('plan_limit'),
  appUpdate('app_update'),
  unknown('');

  const NotificationType(this.wire);

  final String wire;

  static NotificationType parse(String? raw) {
    for (final t in values) {
      if (t != unknown && t.wire == raw) return t;
    }
    // Server-side legacy names (web bell rows).
    return switch (raw) {
      'conversation_assigned' => assigned,
      'conversation_waiting' || 'waiting' => slaBreach,
      'escalated' || 'handoff' => aiHandoff,
      _ => unknown,
    };
  }

  /// Billing rows are visible to owner/admin only (§5).
  bool get isBilling => this == trialEnding || this == paymentFailed;

  /// Rows that show the actor's avatar instead of an icon tile (§4.6).
  bool get personOriginated => this == mention || this == assigned || this == transferRequest;

  /// AI rows allow a 3-line subtitle (§4.6).
  bool get isAi => NotificationFilter.ai.includes(this);

  /// Counted in the launcher badge with the Mine unread count (§8).
  bool get countsInAppBadge => this == assigned || this == mention || this == slaBreach || this == transferRequest;

  /// Worth an in-app banner when it arrives in the foreground (§9.2).
  bool get pushWorthy =>
      this == assigned ||
      this == mention ||
      this == slaBreach ||
      this == transferRequest ||
      this == claimNeeded ||
      this == aiHandoff ||
      this == channelDisconnected ||
      this == paymentFailed;
}

/// Filter chips (§4.2). The id is sent as `?filter=` (§10).
enum NotificationFilter {
  all,
  unread,
  mentions,
  assignments,
  ai,
  system;

  static NotificationFilter parse(String? raw) => values.asNameMap()[raw] ?? all;

  bool includes(NotificationType t) => switch (this) {
        all || unread => true,
        mentions => t == NotificationType.mention,
        assignments => t == NotificationType.assigned ||
            t == NotificationType.claimNeeded ||
            t == NotificationType.transferRequest ||
            t == NotificationType.slaBreach,
        ai => t == NotificationType.aiNoAnswer ||
            t == NotificationType.aiHandoff ||
            t == NotificationType.aiLowConfidence ||
            t == NotificationType.kbSuggestion,
        system => t == NotificationType.channelDisconnected ||
            t == NotificationType.channelReconnected ||
            t == NotificationType.channelQualityLow ||
            t == NotificationType.teamJoined ||
            t == NotificationType.teamRoleChanged ||
            t == NotificationType.trialEnding ||
            t == NotificationType.paymentFailed ||
            t == NotificationType.planLimit ||
            t == NotificationType.appUpdate,
      };

  bool matches(NotificationItem n) => this == unread ? !n.isRead : includes(n.type);

  String label(AppLocalizations l) => switch (this) {
        all => l.ntf_filter_all,
        unread => l.ntf_filter_unread,
        mentions => l.ntf_filter_mentions,
        assignments => l.ntf_filter_assignments,
        ai => l.ntf_filter_ai,
        system => l.ntf_filter_system,
      };
}

/// Client fallback templates for offline / missing server copy (§5: "All copy
/// is server-rendered … with client fallback templates above for offline").
abstract final class NotificationTemplates {
  static String _p(NotificationItem n, String key, [String fallback = '']) => '${n.params[key] ?? fallback}';
  static int _i(NotificationItem n, String key) => int.tryParse(_p(n, key, '0')) ?? 0;

  static String title(AppLocalizations l, NotificationItem n) {
    if (n.title.isNotEmpty) return n.title;
    final actor = n.actor?.name ?? _p(n, 'agent');
    return switch (n.type) {
      NotificationType.assigned => l.ntf_t_assigned,
      NotificationType.claimNeeded => l.ntf_t_claim_needed(_i(n, 'n')),
      NotificationType.slaBreach => l.ntf_t_sla_breach(_p(n, 'customer'), _i(n, 'm')),
      NotificationType.transferRequest => l.ntf_t_transfer_request(actor),
      NotificationType.mention => l.ntf_t_mention(actor),
      NotificationType.aiNoAnswer => l.ntf_t_ai_no_answer,
      NotificationType.aiHandoff => l.ntf_t_ai_handoff,
      NotificationType.aiLowConfidence => l.ntf_t_ai_low_confidence,
      NotificationType.kbSuggestion => l.ntf_t_kb_suggestion(_i(n, 'n')),
      NotificationType.channelDisconnected => l.ntf_t_channel_disconnected,
      NotificationType.channelReconnected => l.ntf_t_channel_reconnected,
      NotificationType.channelQualityLow => l.ntf_t_channel_quality_low,
      NotificationType.teamJoined => l.ntf_t_team_joined(_p(n, 'name', actor)),
      NotificationType.teamRoleChanged => l.ntf_t_team_role_changed(_p(n, 'role')),
      NotificationType.trialEnding => l.ntf_t_trial_ending(_i(n, 'n')),
      NotificationType.paymentFailed => l.ntf_t_payment_failed,
      NotificationType.planLimit => l.ntf_t_plan_limit,
      NotificationType.appUpdate => l.ntf_t_app_update,
      NotificationType.unknown => l.ntf_title,
    };
  }

  /// Context part of the subtitle (time is appended by the tile, §4.6).
  static String body(AppLocalizations l, NotificationItem n) {
    if (n.body.isNotEmpty) return n.body;
    final customer = _p(n, 'customer');
    return switch (n.type) {
      NotificationType.assigned => [customer, _p(n, 'topic')].where((s) => s.isNotEmpty).join(' · '),
      NotificationType.claimNeeded => l.ntf_b_claim_needed(_i(n, 'm')),
      NotificationType.slaBreach => _p(n, 'channel'),
      NotificationType.transferRequest => customer,
      NotificationType.mention => '«${_p(n, 'excerpt')}»',
      NotificationType.aiNoAnswer => l.ntf_b_ai_no_answer(_p(n, 'topic')),
      NotificationType.aiHandoff => [customer, _p(n, 'reason')].where((s) => s.isNotEmpty).join(' · '),
      NotificationType.aiLowConfidence => l.ntf_b_ai_low_confidence(customer),
      NotificationType.kbSuggestion => l.ntf_b_kb_suggestion,
      NotificationType.channelDisconnected => l.ntf_b_channel_disconnected,
      NotificationType.channelReconnected => l.ntf_b_channel_reconnected(_i(n, 'm')),
      NotificationType.channelQualityLow => l.ntf_b_channel_quality_low,
      NotificationType.teamJoined => l.ntf_b_team_joined(_p(n, 'role')),
      NotificationType.teamRoleChanged => l.ntf_b_team_role_changed(n.actor?.name ?? _p(n, 'actor')),
      NotificationType.trialEnding => l.ntf_b_trial_ending,
      NotificationType.paymentFailed => l.ntf_b_payment_failed,
      NotificationType.planLimit => l.ntf_b_plan_limit(_i(n, 'p')),
      NotificationType.appUpdate => l.ntf_b_app_update(_p(n, 'version')),
      NotificationType.unknown => '',
    };
  }

  /// Whether the time is appended to the subtitle: rows whose body is a
  /// sentence (AI / system advice) don't carry a trailing "· 9 د" (§5).
  static bool timeInSubtitle(NotificationType t) => switch (t) {
        NotificationType.aiNoAnswer ||
        NotificationType.kbSuggestion ||
        NotificationType.channelDisconnected ||
        NotificationType.channelReconnected ||
        NotificationType.channelQualityLow ||
        NotificationType.trialEnding ||
        NotificationType.paymentFailed ||
        NotificationType.planLimit ||
        NotificationType.claimNeeded =>
          false,
        _ => true,
      };

  /// Client default inline actions per type (§5) when the server sends none.
  static List<NotificationAction> defaultActions(NotificationType t) => switch (t) {
        NotificationType.claimNeeded => const [NotificationAction(id: 'view', style: NotificationActionStyle.primary)],
        NotificationType.slaBreach => const [NotificationAction(id: 'reply', style: NotificationActionStyle.primary)],
        NotificationType.transferRequest => const [
            NotificationAction(id: 'approve', style: NotificationActionStyle.primary),
            NotificationAction(id: 'reject', style: NotificationActionStyle.secondary),
          ],
        NotificationType.aiNoAnswer => const [
            NotificationAction(id: 'add_answer', style: NotificationActionStyle.primary),
          ],
        NotificationType.aiHandoff => const [NotificationAction(id: 'claim', style: NotificationActionStyle.secondary)],
        NotificationType.kbSuggestion => const [
            NotificationAction(id: 'review', style: NotificationActionStyle.secondary),
          ],
        NotificationType.channelDisconnected => const [
            NotificationAction(id: 'reconnect', style: NotificationActionStyle.primary),
          ],
        NotificationType.trialEnding => const [NotificationAction(id: 'plans', style: NotificationActionStyle.secondary)],
        NotificationType.paymentFailed || NotificationType.appUpdate => const [
            NotificationAction(id: 'update', style: NotificationActionStyle.primary),
          ],
        _ => const [],
      };

  static String actionLabel(AppLocalizations l, NotificationAction a) {
    if (a.label != null && a.label!.isNotEmpty) return a.label!;
    return switch (a.id) {
      'view' => l.ntf_a_view,
      'reply' => l.ntf_a_reply,
      'approve' => l.ntf_a_approve,
      'reject' => l.ntf_a_reject,
      'add_answer' => l.ntf_a_add_answer,
      'claim' => l.ntf_a_claim,
      'review' => l.ntf_a_review,
      'reconnect' => l.ntf_a_reconnect,
      'plans' => l.ntf_a_plans,
      'update' => l.ntf_a_update,
      _ => l.ntf_a_open,
    };
  }
}
