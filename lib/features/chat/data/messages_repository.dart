import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../domain/message.dart';
import 'chat_api.dart';
import 'uploads_api.dart';

/// What the composer hands to the send queue.
class OutgoingMessage {
  const OutgoingMessage({
    required this.text,
    this.kind = MessageKind.text,
    this.quote,
    this.sentVia = 'manual',
    this.rewriteId,
    this.isNote = false,
    this.mentions = const [],
    this.fileName,
    this.fileSize,
    this.duration,
    this.albumCount = 0,
    this.locationLabel,
    this.templateName,
    this.templateButtons = const [],
    this.uploadId,
  });

  final String text;
  final MessageKind kind;
  final QuotedMessage? quote;

  /// manual | ai_suggestion | ai_edited | ai_rewrite | quick_reply | template
  final String sentVia;

  /// With `sent_via: ai_rewrite` (Rewrite spec §8).
  final String? rewriteId;
  final bool isNote;
  final List<String> mentions;
  final String? fileName;
  final String? fileSize;
  final Duration? duration;
  final int albumCount;
  final String? locationLabel;
  final String? templateName;
  final List<String> templateButtons;
  final String? uploadId;
}

/// Messages + per-message actions (Chat spec §6 data, §4.7.6 sending).
abstract interface class MessagesRepository {
  /// All locally known messages, oldest → newest.
  List<Message> current(String conversationId);
  Stream<void> changes(String conversationId);

  bool hasOlder(String conversationId);

  /// True while the first fetch is in flight and nothing is held locally
  /// (the chat shows skeleton bubbles, not an empty thread).
  bool isLoading(String conversationId);

  /// The first fetch failed and nothing is cached (error + retry).
  bool loadFailed(String conversationId);

  /// Retries the first fetch after [loadFailed].
  void reload(String conversationId);

  /// Fetches the previous page (40). Returns false when nothing was added.
  Future<bool> loadOlder(String conversationId);

  /// Makes sure [messageId] is held locally (search jump to an older match):
  /// loads the window around it. Returns false when it can't be found.
  Future<bool> loadAround(String conversationId, String messageId);

  /// Returns the new message id (optimistic, appears immediately).
  String send(String conversationId, OutgoingMessage m);
  void retry(String conversationId, String messageId);
  void discard(String conversationId, String messageId);
  void delete(String conversationId, String messageId);
  void react(String conversationId, String messageId, String emoji);
  void feedback(String conversationId, String messageId, String rating);
  Future<void> transcribe(String conversationId, String messageId);
  Future<void> saveDraft(String conversationId, String text);
  UploadsApi get uploads;
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final chat = ref.watch(chatApiProvider);
  final wd = ref.watch(wdApiProvider);
  if (chat == null || wd == null) return SampleMessagesRepository(ref);
  final repo = HttpMessagesRepository(chat, HttpUploadsApi(wd), ref.read(sharedPrefsProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

// ---- Sample data -------------------------------------------------------------------

/// Reads/writes the in-memory [InboxController] so the inbox list and chat
/// stay in sync. Everything is local, so there are never older pages.
class SampleMessagesRepository implements MessagesRepository {
  SampleMessagesRepository(this._ref);

  final Ref _ref;
  InboxController get _inbox => _ref.read(inboxProvider.notifier);

  @override
  final UploadsApi uploads = SimulatedUploadsApi();

  @override
  List<Message> current(String id) => _inbox.byId(id)?.messages ?? const [];

  @override
  Stream<void> changes(String id) {
    final c = StreamController<void>();
    final sub = _ref.listen(conversationProvider(id).select((c) => c?.messages), (_, _) => c.add(null));
    c.onCancel = sub.close;
    return c.stream;
  }

  @override
  bool hasOlder(String id) => false;

  @override
  bool isLoading(String id) => false;

  @override
  bool loadFailed(String id) => false;

  @override
  void reload(String id) {}

  @override
  Future<bool> loadOlder(String id) async => false;

  @override
  Future<bool> loadAround(String id, String messageId) async => current(id).any((m) => m.id == messageId);

  @override
  String send(String id, OutgoingMessage m) {
    if (m.isNote) {
      _inbox.addNote(id, m.text, mentions: m.mentions);
      return current(id).last.id;
    }
    if (m.kind == MessageKind.template && m.templateName != null) {
      return _inbox.sendMessage(
        id,
        m.text,
        kind: MessageKind.template,
        templateName: m.templateName,
        templateButtons: m.templateButtons,
        sentVia: 'template',
      );
    }
    return _inbox.sendMessage(
      id,
      m.text,
      kind: m.kind,
      quote: m.quote,
      sentVia: m.sentVia,
      fileName: m.fileName,
      fileSize: m.fileSize,
      mediaDuration: m.duration,
      albumCount: m.albumCount,
      locationLabel: m.locationLabel,
    );
  }

  @override
  void retry(String id, String messageId) => _inbox.retryMessage(id, messageId);

  @override
  void discard(String id, String messageId) => _inbox.discardMessage(id, messageId);

  @override
  void delete(String id, String messageId) => _inbox.deleteMessage(id, messageId);

  @override
  void react(String id, String messageId, String emoji) => _inbox.react(id, messageId, emoji);

  @override
  void feedback(String id, String messageId, String rating) => _inbox.setAiFeedback(id, messageId, rating);

  @override
  Future<void> transcribe(String id, String messageId) => _inbox.transcribe(id, messageId);

  @override
  Future<void> saveDraft(String id, String text) async {}
}

// ---- Real backend -----------------------------------------------------------------

/// `/mobile/v1` messages + local cache (last 200 per conversation) + a
/// persisted outgoing queue so killing the app never loses a message (§8).
///
/// Each send gets a UUID `client_id` and an `Idempotency-Key`, both fixed
/// when the user taps Send and reused on every retry (FLUTTER_CLIENT_NOTES
/// §6). No WebSocket client yet: while a thread is open the newest page is
/// polled every 8 s and merged by id.
class HttpMessagesRepository implements MessagesRepository {
  HttpMessagesRepository(this._api, this.uploads, this._prefs);

  final ChatApi _api;
  final SharedPreferences _prefs;

  @override
  final UploadsApi uploads;

  final Map<String, List<Message>> _messages = {};
  final Map<String, String?> _cursor = {};
  final Map<String, StreamController<void>> _changes = {};
  final Map<String, Timer> _polls = {};
  final List<Timer> _timers = [];

  /// First fetch finished (either way) / failed with nothing held.
  final Set<String> _loaded = {};
  final Set<String> _failed = {};
  bool _disposed = false;

  static const _pollEvery = Duration(seconds: 8);

  void dispose() {
    _disposed = true;
    for (final t in [..._timers, ..._polls.values]) {
      t.cancel();
    }
    for (final c in _changes.values) {
      c.close();
    }
  }

  void _notify(String id) {
    if (!_disposed) _changes[id]?.add(null);
  }

  static bool _pending(Message m) => m.delivery == DeliveryState.sending || m.delivery == DeliveryState.failed;

  @override
  List<Message> current(String id) {
    if (!_messages.containsKey(id)) {
      _messages[id] = _readCache(id);
      unawaited(_initial(id));
    }
    return _messages[id]!;
  }

  Future<void> _initial(String id) async {
    try {
      final page = await _api.messages(id);
      final pending = [
        for (final m in _messages[id] ?? const <Message>[])
          if (_pending(m)) m,
      ];
      _messages[id] = [...page.items, ...pending.where((p) => !page.items.any((s) => s.id == p.id))];
      _cursor[id] = page.prevCursor;
      _writeCache(id);
      _loaded.add(id);
      _failed.remove(id);
      _notify(id);
      _flushQueue(id);
      unawaited(_api.markRead(id).catchError((_) {}));
    } catch (_) {
      // Offline: keep the cached copy; with nothing cached, show retry.
      _loaded.add(id);
      if ((_messages[id] ?? const []).isEmpty) _failed.add(id);
      _notify(id);
    }
  }

  @override
  bool isLoading(String id) => !_loaded.contains(id) && current(id).isEmpty;

  @override
  bool loadFailed(String id) => _failed.contains(id) && current(id).isEmpty;

  @override
  void reload(String id) {
    _failed.remove(id);
    _loaded.remove(id);
    _notify(id);
    unawaited(_initial(id));
  }

  /// Newest page merged into what we hold (new messages, status ticks,
  /// reactions). Marks the thread read when something new came in.
  Future<void> _poll(String id) async {
    try {
      final page = await _api.messages(id, limit: 30);
      final server = {for (final m in page.items) m.id: m};
      final held = current(id);
      final known = {for (final m in held) m.id};
      final merged = <Message>[
        for (final m in held)
          if (!_pending(m)) server[m.id] ?? m,
        for (final m in page.items)
          if (!known.contains(m.id)) m,
        for (final m in held)
          if (_pending(m)) m,
      ];
      final fresh = page.items.where((m) => !known.contains(m.id)).toList();
      final changed =
          fresh.isNotEmpty ||
          merged.length != held.length ||
          [
            for (var i = 0; i < merged.length; i++)
              if (!identical(merged[i], held[i])) i,
          ].isNotEmpty;
      if (!changed) return;
      _messages[id] = merged;
      _writeCache(id);
      _notify(id);
      if (fresh.any((m) => m.type == MessageBubbleType.incoming)) {
        unawaited(_api.markRead(id).catchError((_) {}));
      }
    } catch (_) {
      // Next tick retries.
    }
  }

  @override
  Stream<void> changes(String id) {
    final c = _changes[id] ??= StreamController<void>.broadcast(
      onListen: () {
        _polls[id]?.cancel();
        _polls[id] = Timer.periodic(_pollEvery, (_) => _poll(id));
      },
      onCancel: () => _polls.remove(id)?.cancel(),
    );
    return c.stream;
  }

  @override
  bool hasOlder(String id) => _cursor[id] != null;

  @override
  Future<bool> loadOlder(String id) async {
    final cursor = _cursor[id];
    if (cursor == null) return false;
    final page = await _api.messages(id, before: cursor);
    final have = {for (final m in current(id)) m.id};
    _messages[id] = [
      ...page.items.where((m) => !have.contains(m.id)),
      ...current(id),
    ];
    _cursor[id] = page.prevCursor;
    _notify(id);
    return page.items.isNotEmpty;
  }

  /// `GET conversations/{id}/messages/around/{msg}`, merged by id and
  /// time. Paging older continues from the start of that window (messages
  /// between it and the newest page are fetched as the user scrolls).
  @override
  Future<bool> loadAround(String id, String messageId) async {
    if (current(id).any((m) => m.id == messageId)) return true;
    try {
      final page = await _api.around(id, messageId);
      if (page.items.isEmpty) return false;
      final byId = {for (final m in current(id)) m.id: m};
      for (final m in page.items) {
        byId[m.id] = m;
      }
      final pending = [
        for (final m in byId.values)
          if (_pending(m)) m,
      ];
      _messages[id] = [
        ...(byId.values.where((m) => !_pending(m)).toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt))),
        ...pending,
      ];
      _cursor[id] = page.prevCursor;
      _notify(id);
      return current(id).any((m) => m.id == messageId);
    } catch (_) {
      return false;
    }
  }

  String _cacheKey(String id) => 'chat_cache_$id';
  String _queueKey(String id) => 'chat_queue_$id';

  List<Message> _readCache(String id) {
    final raw = _prefs.getString(_cacheKey(id));
    if (raw == null) return [];
    try {
      return [
        for (final m in (jsonDecode(raw) as List)) messageFromJson(Map<String, dynamic>.from(m as Map), meId: _api.meId()),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Minimal JSON for the cache (the app's own legacy shape).
  Map<String, Object?> _toJson(Message m) => {
    'id': m.id,
    'sender_type': switch (m.type) {
      MessageBubbleType.incoming => 'contact',
      MessageBubbleType.outgoingAi => 'ai',
      MessageBubbleType.internalNote => 'note',
      MessageBubbleType.system => 'system',
      _ => 'agent',
    },
    'sender': {'id': m.senderId, 'name': m.senderName},
    'type': m.kind.name,
    'text': m.text,
    'delivery': m.delivery.name,
    'created_at': m.sentAt.toUtc().toIso8601String(),
  };

  void _writeCache(String id) {
    final list = current(id);
    final last = list.length > 200 ? list.sublist(list.length - 200) : list;
    _prefs.setString(_cacheKey(id), jsonEncode([for (final m in last) _toJson(m)]));
  }

  void _replace(String id, String messageId, Message Function(Message m) fn) {
    _messages[id] = [for (final m in current(id)) m.id == messageId ? fn(m) : m];
    _notify(id);
  }

  /// App `sentVia` → server `sent_via` (composer | ai_suggestion |
  /// quick_reply | rewrite | voice).
  static String _sentVia(OutgoingMessage o) {
    if (o.kind == MessageKind.voice) return 'voice';
    return switch (o.sentVia) {
      'ai_suggestion' || 'ai_edited' => 'ai_suggestion',
      'quick_reply' => 'quick_reply',
      'ai_rewrite' => 'rewrite',
      _ => 'composer',
    };
  }

  /// Body of `POST conversations/{id}/messages`. Unknown keys are rejected
  /// (422 unknown_field), so only the documented fields go out. Mentions
  /// need user ids; the composer only has names, so they stay in the text.
  static Map<String, Object?> _body(String clientId, OutgoingMessage o) => {
    'client_id': clientId,
    if (o.text.isNotEmpty) 'text': o.text,
    'media_upload_id': ?o.uploadId,
    'reply_to_id': ?o.quote?.messageId,
    if (o.isNote) 'is_note': true,
    'sent_via': _sentVia(o),
    if (o.sentVia == 'ai_rewrite') 'rewrite_id': ?o.rewriteId,
  };

  @override
  String send(String id, OutgoingMessage o) {
    final clientId = WdApi.newIdempotencyKey();
    final idemKey = WdApi.newIdempotencyKey();
    final local = Message(
      id: clientId,
      type: o.isNote ? MessageBubbleType.internalNote : MessageBubbleType.outgoing,
      kind: o.kind,
      text: o.text,
      sentAt: DateTime.now(),
      senderId: _api.meId(),
      delivery: DeliveryState.sending,
      quote: o.quote,
      sentVia: o.sentVia,
      fileName: o.fileName,
      fileSize: o.fileSize,
      mediaDuration: o.duration,
      templateName: o.templateName,
      templateButtons: o.templateButtons,
      mentions: o.mentions,
    );
    _messages[id] = [...current(id), local];
    _notify(id);
    final body = _body(clientId, o);
    _enqueue(id, clientId, idemKey, body);
    _attempt(id, clientId, idemKey, body, 0);
    return clientId;
  }

  void _enqueue(String id, String clientId, String idemKey, Map<String, Object?> body) {
    final q = _prefs.getStringList(_queueKey(id)) ?? [];
    _prefs.setStringList(_queueKey(id), [
      ...q,
      jsonEncode({'client_id': clientId, 'idempotency_key': idemKey, 'body': body}),
    ]);
  }

  void _dequeue(String id, String clientId) {
    final q = _prefs.getStringList(_queueKey(id)) ?? [];
    _prefs.setStringList(_queueKey(id), [
      for (final e in q)
        if (!e.contains('"$clientId"')) e,
    ]);
  }

  Map<String, dynamic>? _queued(String id, String clientId) {
    for (final raw in _prefs.getStringList(_queueKey(id)) ?? const <String>[]) {
      if (raw.contains('"$clientId"')) return jsonDecode(raw) as Map<String, dynamic>;
    }
    return null;
  }

  /// Resends anything left in the persisted queue (after an app restart).
  void _flushQueue(String id) {
    for (final raw in _prefs.getStringList(_queueKey(id)) ?? const <String>[]) {
      final e = jsonDecode(raw) as Map<String, dynamic>;
      final clientId = '${e['client_id']}';
      // Old entries (pre-API) had no key: give them one now, then keep it.
      final key = '${e['idempotency_key'] ?? clientId}';
      _attempt(id, clientId, key, Map<String, Object?>.from(e['body'] as Map), 0);
    }
  }

  /// Exponential backoff 2s, 4s… (max 60s); failed after 3 tries. Errors
  /// the server will keep refusing (4xx) fail at once.
  void _attempt(String id, String clientId, String idemKey, Map<String, Object?> body, int attempt) {
    _api
        .sendMessage(id, body, idempotencyKey: idemKey)
        .then((server) {
          _dequeue(id, clientId);
          // A poll may already have brought the server copy in.
          _messages[id] = [
            for (final m in current(id))
              if (m.id != server.id) m,
          ];
          _replace(id, clientId, (_) => server);
          _writeCache(id);
        })
        .catchError((Object e) {
          final permanent =
              e is ChatApiException && e.statusCode >= 400 && e.statusCode < 500 && e.statusCode != 429 && e.statusCode != 401;
          if (permanent || attempt + 1 >= 3) {
            _replace(id, clientId, (m) => m.copyWith(delivery: DeliveryState.failed, retries: attempt + 1));
            return;
          }
          final wait = Duration(seconds: (2 << attempt).clamp(2, 60));
          _timers.add(Timer(wait, () => _attempt(id, clientId, idemKey, body, attempt + 1)));
        });
  }

  @override
  void retry(String id, String messageId) {
    final e = _queued(id, messageId);
    _replace(id, messageId, (m) => m.copyWith(delivery: DeliveryState.sending, retries: 0));
    if (e != null) {
      _attempt(id, messageId, '${e['idempotency_key'] ?? messageId}', Map<String, Object?>.from(e['body'] as Map), 0);
    }
  }

  @override
  void discard(String id, String messageId) {
    _dequeue(id, messageId);
    _messages[id] = [
      for (final m in current(id))
        if (m.id != messageId) m,
    ];
    _notify(id);
  }

  @override
  void delete(String id, String messageId) {
    _replace(id, messageId, (m) => m.copyWith(kind: MessageKind.deleted, text: ''));
    unawaited(_api.deleteMessage(messageId).catchError((_) {}));
  }

  @override
  void react(String id, String messageId, String emoji) {
    _replace(
      id,
      messageId,
      (m) => m.copyWith(
        reactions: [
          for (final r in m.reactions)
            if (r.byContact) r,
          if (!m.reactions.any((r) => !r.byContact && r.emoji == emoji)) Reaction(emoji: emoji, byContact: false),
        ],
      ),
    );
    unawaited(
      _api
          .react(messageId, emoji)
          .then((list) => _replace(id, messageId, (m) => m.copyWith(reactions: list)))
          .catchError((_) {}),
    );
  }

  @override
  void feedback(String id, String messageId, String rating) {
    _replace(id, messageId, (m) => m.copyWith(aiFeedback: rating));
    unawaited(_api.feedback(messageId, rating).catchError((_) {}));
  }

  @override
  Future<void> transcribe(String id, String messageId) async {
    final text = await _api.transcribe(messageId);
    _replace(id, messageId, (m) => m.copyWith(transcript: text));
  }

  @override
  Future<void> saveDraft(String id, String text) => _api.saveDraft(id, text).catchError((_) {});
}
