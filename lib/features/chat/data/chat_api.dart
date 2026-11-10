import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../auth/application/auth_session.dart';
import '../domain/conversation_detail.dart';
import '../domain/message.dart';

class ChatApiException implements Exception {
  const ChatApiException(this.statusCode, {this.code, this.claimedBy, this.body = const {}, this.message});

  /// 0 = transport failure.
  final int statusCode;
  final String? code;

  /// 409 `already_assigned`: `details.assignee.name`.
  final String? claimedBy;

  /// `error.details` of the envelope.
  final Map<String, dynamic> body;

  /// Localised `error.message` (safe to show).
  final String? message;

  bool get isNetwork => statusCode == 0;

  factory ChatApiException.from(WdApiException e) {
    final assignee = e.details['assignee'];
    return ChatApiException(
      e.status,
      code: e.code,
      claimedBy: assignee is Map ? assignee['name'] as String? : null,
      body: e.details,
      message: e.message,
    );
  }
}

class MessagesPage {
  const MessagesPage({required this.items, required this.prevCursor, this.raw = const []});

  /// Oldest → newest.
  final List<Message> items;
  final String? prevCursor;

  /// Server JSON of [items] (same order), e.g. to see which have media.
  final List<Map<String, dynamic>> raw;
}

class AiSuggestionDto {
  const AiSuggestionDto({required this.id, required this.text, required this.sources, required this.confidence});

  final String id;
  final String text;
  final List<String> sources;
  final double confidence;
}

/// One `GET /mobile/v1/conversations/{id}` answer, mapped for the app.
@immutable
class RemoteConversation {
  const RemoteConversation({
    required this.conversation,
    required this.permissions,
    required this.teamName,
    this.slaSeconds,
    this.capacity,
    this.aiHandoff,
    this.viewerSince = const {},
  });

  final Conversation conversation;
  final ChatPermissions permissions;
  final String? teamName;

  /// `sla_seconds`: waiting-tag turns red at this age (Claim spec §4.2.2).
  final int? slaSeconds;

  /// `capacity`: my open conversations vs the workspace limit (§6).
  final ClaimCapacity? capacity;

  /// `ai_handoff`: why the AI escalated to the team (§5.1).
  final AiHandoff? aiHandoff;

  /// Viewer id → `since` (popover "منذ {n} ث").
  final Map<String, DateTime> viewerSince;
}

/// `capacity` of the conversation detail.
@immutable
class ClaimCapacity {
  const ClaimCapacity({required this.open, this.max, this.hardLimit = false});

  final int open;
  final int? max;
  final bool hardLimit;
}

/// `ai_handoff` of the conversation detail. [reasonCode] is one of
/// payment | human | complaint | no_answer | refund | other.
@immutable
class AiHandoff {
  const AiHandoff({required this.reasonCode, this.reasonLabel, this.at});

  final String reasonCode;
  final String? reasonLabel;
  final DateTime? at;
}

/// The signed client, or null in sample mode.
final chatApiProvider = Provider<ChatApi?>((ref) {
  final api = ref.watch(wdApiProvider);
  if (api == null) return null;
  final auth = ref.read(authRepositoryProvider);
  return ChatApi(api, meId: () => '${auth.session?.user['id'] ?? ''}', role: () => '${auth.session?.user['role'] ?? ''}');
});

/// Server permissions per conversation (from the last detail fetch).
final remoteChatPermissionsProvider =
    NotifierProvider<RemoteChatPermissions, Map<String, RemoteConversation>>(RemoteChatPermissions.new);

class RemoteChatPermissions extends Notifier<Map<String, RemoteConversation>> {
  @override
  Map<String, RemoteConversation> build() => const {};

  void put(RemoteConversation r) => state = {...state, r.conversation.id: r};
}

/// First-load outcome of [chatRemoteSyncProvider] per conversation, so the
/// chat shows a skeleton (not "not found") until the server has answered.
enum ChatDetailLoad { loading, ready, notFound, error }

final chatDetailLoadProvider = NotifierProvider<ChatDetailLoadStatus, Map<String, ChatDetailLoad>>(ChatDetailLoadStatus.new);

class ChatDetailLoadStatus extends Notifier<Map<String, ChatDetailLoad>> {
  @override
  Map<String, ChatDetailLoad> build() => const {};

  void put(String id, ChatDetailLoad s) {
    if (state[id] != s) state = {...state, id: s};
  }
}

/// Loads the conversation header from the server, mirrors it into the
/// in-memory inbox (the chat screen reads `conversationProvider`) and keeps
/// it fresh while the chat is open (polled; no WebSocket client yet).
final chatRemoteSyncProvider = Provider.autoDispose.family<void, String>((ref, id) {
  final api = ref.watch(chatApiProvider);
  if (api == null) return;
  var disposed = false;
  Future<void> load() async {
    // Presence heartbeat only while the app is visible (Claim spec §9).
    final life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;
    try {
      final r = await api.detail(id);
      if (disposed) return;
      syncRemoteConversation(ref, r);
      ref.read(chatDetailLoadProvider.notifier).put(id, ChatDetailLoad.ready);
    } on ChatApiException catch (e) {
      // Offline / 5xx: keep what we have; a real 404/403 means it's gone.
      if (disposed) return;
      final status = ref.read(chatDetailLoadProvider.notifier);
      if (e.statusCode == 404 || e.statusCode == 403) {
        status.put(id, ChatDetailLoad.notFound);
      } else if (ref.read(chatDetailLoadProvider)[id] != ChatDetailLoad.ready) {
        status.put(id, ChatDetailLoad.error);
      }
    } catch (_) {
      if (disposed) return;
      if (ref.read(chatDetailLoadProvider)[id] != ChatDetailLoad.ready) {
        ref.read(chatDetailLoadProvider.notifier).put(id, ChatDetailLoad.error);
      }
    }
  }

  unawaited(load());
  final t = Timer.periodic(const Duration(seconds: 15), (_) => load());
  ref.onDispose(() {
    disposed = true;
    t.cancel();
  });
});

/// Writes a server conversation into the inbox + permissions store.
void syncRemoteConversation(Ref ref, RemoteConversation r) {
  ref.read(inboxProvider.notifier).upsertFromApi(r.conversation);
  ref.read(remoteChatPermissionsProvider.notifier).put(r);
}

/// REST client for the chat contract over the signed `/mobile/v1` API.
class ChatApi {
  ChatApi(this._api, {required this.meId, required this.role});

  final WdApi _api;
  final String Function() meId;
  final String Function() role;

  WdApi get raw => _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw ChatApiException.from(e);
    }
  }

  Future<RemoteConversation> detail(String id) =>
      _guard(() async => remoteConversationFromJson((await _api.get('conversations/$id')).map, meId: meId(), role: role()));

  Future<MessagesPage> messages(String id, {String? before, int limit = 40}) => _guard(() async {
    final r = await _api.get('conversations/$id/messages', query: {'limit': limit.clamp(1, 50), 'before': before});
    return _page(r);
  });

  Future<MessagesPage> around(String id, String messageId, {int limit = 40}) => _guard(() async {
    final r = await _api.get('conversations/$id/messages/around/$messageId', query: {'limit': limit.clamp(2, 50)});
    return _page(r);
  });

  MessagesPage _page(WdResponse r) {
    final raw = r.list;
    return MessagesPage(
      items: [for (final m in raw) messageFromJson(m, meId: meId())],
      prevCursor: r.nextCursor,
      raw: raw,
    );
  }

  /// `POST conversations/{id}/messages`. A replay with the same
  /// Idempotency-Key answers 200 + `meta.deduplicated` and the original.
  Future<Message> sendMessage(String id, Map<String, Object?> body, {required String idempotencyKey}) => _guard(
    () async => messageFromJson(
      (await _api.post('conversations/$id/messages', body: body, idempotencyKey: idempotencyKey)).map,
      meId: meId(),
    ),
  );

  Future<void> deleteMessage(String messageId) => _guard(() => _api.delete('messages/$messageId'));

  /// Returns the message's reactions after the toggle.
  Future<List<Reaction>> react(String messageId, String emoji) => _guard(() async {
    final r = await _api.post('messages/$messageId/reactions', body: {'emoji': emoji});
    final list = r.data is List ? r.list : (r.map['reactions'] is List ? (r.map['reactions'] as List) : const []);
    return [
      for (final x in list)
        if (x is Map) Reaction(emoji: '${x['emoji']}', byContact: x['mine'] != true),
    ];
  });

  Future<AiSuggestionDto?> aiSuggestion(String id) => _guard(() async {
    final j = (await _api.get('conversations/$id/ai-suggestion')).map;
    if (j.isEmpty || (j['text'] ?? j['body']) == null) return null;
    return AiSuggestionDto(
      id: '${j['id']}',
      text: (j['text'] ?? j['body']) as String,
      sources: [
        for (final s in (j['kb_sources'] ?? j['sources'] ?? const []) as List)
          if (s is Map) '${s['title']}',
      ],
      confidence: (j['confidence'] as num?)?.toDouble() ?? 1,
    );
  });

  Future<void> regenerateSuggestion(String id) => _guard(() => _api.post('conversations/$id/ai-suggestion/regenerate'));

  /// rating: up | down
  Future<void> feedback(String messageId, String rating) => _guard(
    () => _api.post('messages/$messageId/feedback', body: {'rating': rating == 'down' ? 'down' : 'up'}),
  );

  Future<String> transcribe(String messageId) => _guard(() async {
    final j = (await _api.post('messages/$messageId/transcribe')).map;
    return (j['text'] ?? j['transcript'] ?? '') as String;
  });

  Future<void> saveDraft(String id, String text) =>
      _guard(() => _api.put('conversations/$id/draft', body: {'body': text.isEmpty ? null : text}));

  Future<void> markRead(String id) => _guard(() => _api.post('conversations/$id/read'));

  /// claim | assign | unassign | resolve | reopen | snooze | unsnooze |
  /// priority | tags | ai-toggle | block-contact. Answers the new detail.
  Future<RemoteConversation> action(
    String id,
    String action, [
    Map<String, Object?> body = const {},
    String? idempotencyKey,
  ]) => _guard(() async {
    final r = await _api.post('conversations/$id/$action', body: body, idempotencyKey: idempotencyKey);
    return remoteConversationFromJson(r.map, meId: meId(), role: role());
  });

  /// Unblock lives on the contact (`DELETE contacts/{ct}/block`).
  Future<void> unblockContact(String contactId) => _guard(() => _api.delete('contacts/$contactId/block'));

  /// 5-minute signed URL for a message's media (or an own upload).
  Future<String> mediaUrl(String messageOrUploadId) =>
      _guard(() async => (await _api.get('media/$messageOrUploadId/url')).map['url'] as String);

  /// online | busy | away
  Future<void> setPresence(String status) => _guard(() => _api.put('me/presence', body: {'status': status}));

  Future<List<QuickReply>> quickReplies(String q) => _guard(() async {
    final r = await _api.get('quick-replies', query: {'q': q});
    return [
      for (final x in r.list)
        QuickReply(shortcut: '${x['shortcut'] ?? ''}', title: '${x['title'] ?? ''}', text: '${x['body'] ?? ''}'),
    ];
  });

  /// Empty in v1 (no template sending through Wavadesk yet).
  Future<List<MessageTemplate>> templates() => _guard(() async {
    final r = await _api.get('whatsapp/templates');
    return [
      for (final t in r.list)
        MessageTemplate(id: '${t['id']}', name: '${t['name']}', body: '${t['body']}', category: '${t['category']}'),
    ];
  });
}

// ---- Mapping ------------------------------------------------------------------------

Channel _channel(Object? c) => switch (c) {
  'whatsapp' || 'wacloud' => Channel.whatsapp,
  'webchat' => Channel.web,
  'messenger' => Channel.messenger,
  _ => Channel.other,
};

Priority _priority(Object? p) => switch (p) {
  'urgent' => Priority.urgent,
  'high' => Priority.high,
  'normal' => Priority.medium,
  _ => Priority.low,
};

/// App priority → server value (`low|normal|high|urgent`).
String priorityToServer(Priority p) => switch (p) {
  Priority.urgent => 'urgent',
  Priority.high => 'high',
  Priority.medium => 'normal',
  Priority.low => 'low',
};

Agent _agent(Map<String, dynamic> u) => Agent(
  id: '${u['id']}',
  name: '${u['name'] ?? ''}',
  email: '',
  avatarUrl: u['avatar_url'] as String?,
  gender: switch (u['gender']) {
    'f' || 'female' => 'f',
    'm' || 'male' => 'm',
    _ => null,
  },
  presence: switch (u['presence']) {
    'away' => Presence.away,
    'busy' => Presence.busy,
    'offline' => Presence.away,
    _ => Presence.online,
  },
);

DateTime? _time(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

RemoteConversation remoteConversationFromJson(Map<String, dynamic> j, {required String meId, required String role}) {
  final contact = Map<String, dynamic>.from(j['contact'] as Map? ?? const {});
  final assignee = j['assignee'] is Map ? Map<String, dynamic>.from(j['assignee'] as Map) : null;
  final team = j['team'] is Map ? Map<String, dynamic>.from(j['team'] as Map) : null;
  final perms = Map<String, dynamic>.from(j['permissions'] as Map? ?? const {});
  final window = j['reply_window'] is Map ? Map<String, dynamic>.from(j['reply_window'] as Map) : null;
  final status = j['status'] as String? ?? 'unassigned';
  final aiHandling = j['ai_handling'] == true;
  final isMine = j['is_mine'] == true || (assignee != null && '${assignee['id']}' == meId);
  final snoozed = _time(j['snoozed_until']);
  final channelKey = j['channel'] as String?;

  final ownership = isMine
      ? Ownership.mine
      : assignee != null
      ? Ownership.colleague
      : (aiHandling ? Ownership.ai : Ownership.unassigned);

  final convStatus = switch (status) {
    'resolved' => ConversationStatus.resolved,
    _ when snoozed != null && snoozed.isAfter(DateTime.now()) => ConversationStatus.snoozed,
    'unassigned' when aiHandling => ConversationStatus.ai,
    'unassigned' => ConversationStatus.waiting,
    _ => ConversationStatus.open,
  };

  final conv = Conversation(
    id: '${j['id']}',
    customer: Customer(
      id: '${contact['id'] ?? 'virtual-${j['id']}'}',
      name: (contact['name'] as String?) ?? (contact['phone'] as String?) ?? '—',
      channel: _channel(channelKey),
      phone: contact['phone'] as String?,
      email: contact['email'] as String?,
      avatarUrl: contact['avatar_url'] as String?,
      blocked: contact['blocked'] == true,
    ),
    status: convStatus,
    ownership: ownership,
    messages: const [],
    priority: _priority(j['priority']),
    assignee: assignee == null ? null : _agent(assignee),
    unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
    // First unanswered inbound; older servers only had last_activity_at.
    waitingSince: j.containsKey('waiting_since')
        ? _time(j['waiting_since'])
        : (ownership == Ownership.unassigned ? _time(j['last_activity_at']) : null),
    tags: [for (final t in (j['tags'] as List? ?? const [])) '$t'],
    viewers: [
      for (final v in (j['viewers'] as List? ?? const []))
        if (v is Map) _agent(Map<String, dynamic>.from(v)),
    ],
    snoozedUntil: snoozed,
    serviceWindowOpen: window == null || window['open'] != false,
    // WhatsApp exposes the per-conversation pause; other channels only "bot or not".
    aiPaused: channelKey == 'whatsapp' ? j['ai_suspended'] == true : !aiHandling,
  );

  final cap = j['capacity'] is Map ? Map<String, dynamic>.from(j['capacity'] as Map) : null;
  final handoff = j['ai_handoff'] is Map ? Map<String, dynamic>.from(j['ai_handoff'] as Map) : null;
  final escalation = (j['escalation_reason'] as String?)?.trim();
  return RemoteConversation(
    conversation: conv,
    teamName: team?['name'] as String?,
    slaSeconds: (j['sla_seconds'] as num?)?.toInt(),
    capacity: cap == null
        ? null
        : ClaimCapacity(
            open: (cap['open'] as num?)?.toInt() ?? 0,
            max: (cap['max'] as num?)?.toInt(),
            hardLimit: cap['hard_limit'] == true,
          ),
    aiHandoff: handoff != null
        ? AiHandoff(
            reasonCode: '${handoff['reason_code'] ?? 'other'}',
            reasonLabel: handoff['reason_label'] as String?,
            at: _time(handoff['at']),
          )
        // Older servers: free-text escalation reason only.
        : (escalation != null && escalation.isNotEmpty && assignee == null
              ? AiHandoff(reasonCode: 'other', reasonLabel: escalation)
              : null),
    viewerSince: {
      for (final v in (j['viewers'] as List? ?? const []))
        if (v is Map && _time(v['since']) != null) '${v['id']}': _time(v['since'])!,
    },
    permissions: ChatPermissions(
      canReply: perms['can_reply'] == true && isMine,
      canAssign: perms['can_assign'] == true,
      canResolve: perms['can_resolve'] == true,
      canDeleteMessages: perms['can_delete'] == true,
      isAdmin: role == 'admin',
      canClaim: perms.isEmpty || perms['can_claim'] == true || isMine || status == 'assigned',
      claimTeamName: team?['name'] as String?,
      canHandToAi: perms['can_toggle_ai'] == true,
    ),
  );
}
