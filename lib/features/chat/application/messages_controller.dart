import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../data/messages_repository.dart';
import '../data/chat_api.dart' show remoteChatPermissionsProvider;
import 'local_chat_events.dart';

@immutable
class MessagesState {
  const MessagesState({
    this.messages = const [],
    this.hasOlder = false,
    this.loadingOlder = false,
    this.loading = false,
    this.loadFailed = false,
    this.unreadAnchorId,
    this.unreadCount = 0,
    this.highlightId,
  });

  /// Visible window, oldest → newest.
  final List<Message> messages;
  final bool hasOlder;
  final bool loadingOlder;

  /// First fetch in flight with nothing held → skeleton bubbles.
  final bool loading;

  /// First fetch failed with nothing cached → error + retry.
  final bool loadFailed;

  /// First unread message when the chat opened (unread divider).
  final String? unreadAnchorId;
  final int unreadCount;

  /// `?messageId=` / quote tap: pulses this bubble.
  final String? highlightId;

  MessagesState copyWith({
    List<Message>? messages,
    bool? hasOlder,
    bool? loadingOlder,
    bool? loading,
    bool? loadFailed,
    String? unreadAnchorId,
    int? unreadCount,
    bool clearUnread = false,
    String? highlightId,
    bool clearHighlight = false,
  }) => MessagesState(
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    unreadAnchorId: clearUnread ? null : (unreadAnchorId ?? this.unreadAnchorId),
    unreadCount: clearUnread ? 0 : (unreadCount ?? this.unreadCount),
    highlightId: clearHighlight ? null : (highlightId ?? this.highlightId),
  );
}

final messagesControllerProvider = NotifierProvider.autoDispose.family<MessagesController, MessagesState, String>(
  MessagesController.new,
);

/// Paging (40/page), real-time merge and the send queue (Chat spec §4.3,
/// §4.7.6). Works over [MessagesRepository]; a local window lets "load
/// older" page through history that is already in memory.
class MessagesController extends AutoDisposeFamilyNotifier<MessagesState, String> {
  static const pageSize = 40;

  int _window = pageSize;
  Timer? _highlightTimer;
  DateTime? _openedAt;
  bool _replied = false;

  MessagesRepository get _repo => ref.read(messagesRepositoryProvider);

  @override
  MessagesState build(String id) {
    _openedAt = DateTime.now();
    final sub = _repo.changes(id).listen((_) => _sync());
    // API mode: local ownership pills + the AI handoff pill (Claim spec §5.1, §6).
    ref.listen(localChatEventsProvider.select((m) => m[id]), (_, _) => _sync());
    ref.listen(remoteChatPermissionsProvider.select((m) => m[id]?.aiHandoff), (_, _) => _sync());
    ref.onDispose(() {
      sub.cancel();
      _highlightTimer?.cancel();
    });

    final all = _all(id);
    final unread = ref.read(conversationProvider(id))?.unreadCount ?? 0;
    return MessagesState(
      messages: _slice(all),
      hasOlder: all.length > _window || _repo.hasOlder(id),
      loading: _repo.isLoading(id),
      loadFailed: _repo.loadFailed(id),
      unreadAnchorId: _unreadAnchor(all, unread),
      unreadCount: unread,
    );
  }

  /// Unread divider anchor: the oldest of the last [unread] inbound messages.
  static String? _unreadAnchor(List<Message> all, int unread) {
    if (unread <= 0) return null;
    var seen = 0;
    for (var i = all.length - 1; i >= 0; i--) {
      if (all[i].type == MessageBubbleType.incoming) {
        seen++;
        if (seen == unread) return all[i].id;
      }
    }
    return null;
  }

  /// Retry after a failed first load.
  void reload() => _repo.reload(arg);

  /// Repository messages + session-local system pills, in time order.
  List<Message> _all(String id) {
    final base = _repo.current(id);
    final extra = <Message>[...?ref.read(localChatEventsProvider)[id]];
    final handoff = ref.read(remoteChatPermissionsProvider)[id]?.aiHandoff;
    if (handoff != null && !base.any((m) => m.systemEvent?.kind == SystemEventKind.aiHandoff)) {
      // Placed at the handoff time, or just after the newest message.
      final at = handoff.at ?? (base.isEmpty ? DateTime.now() : base.last.sentAt.add(const Duration(milliseconds: 1)));
      extra.add(Message(
        id: 'handoff-$id',
        type: MessageBubbleType.system,
        sentAt: at,
        // Known codes are localised by the formatter; "other" shows the server label.
        systemEvent: SystemEvent(
          kind: SystemEventKind.aiHandoff,
          value: handoff.reasonCode == 'other' ? (handoff.reasonLabel ?? 'other') : handoff.reasonCode,
        ),
      ));
    }
    if (extra.isEmpty) return base;
    final merged = [...base, ...extra]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return merged;
  }

  List<Message> _slice(List<Message> all) => all.length <= _window ? all : all.sublist(all.length - _window);

  void _sync() {
    final all = _all(arg);
    // Keep the window anchored on the oldest visible message.
    if (state.messages.isNotEmpty) {
      final i = all.indexWhere((m) => m.id == state.messages.first.id);
      if (i >= 0) _window = all.length - i;
    }
    final wasLoading = state.loading;
    state = state.copyWith(
      messages: _slice(all),
      hasOlder: all.length > _window || _repo.hasOlder(arg),
      loading: _repo.isLoading(arg),
      loadFailed: _repo.loadFailed(arg),
      // The first page just arrived: place the unread divider now.
      unreadAnchorId: wasLoading && state.unreadAnchorId == null ? _unreadAnchor(all, state.unreadCount) : null,
    );
  }

  /// Within 600dp of the top → previous page.
  Future<void> loadOlder() async {
    if (state.loadingOlder || !state.hasOlder) return;
    state = state.copyWith(loadingOlder: true);
    final all = _all(arg);
    if (all.length > _window) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _window += pageSize;
    } else {
      try {
        await _repo.loadOlder(arg);
        _window += pageSize;
      } catch (_) {}
    }
    state = state.copyWith(loadingOlder: false);
    _sync();
  }

  /// Shows the whole history so a quoted / deep-linked message is loaded.
  void ensureLoaded(String messageId) {
    final all = _all(arg);
    final i = all.indexWhere((m) => m.id == messageId);
    if (i >= 0 && all.length - i > _window) {
      _window = all.length - i + 5;
      _sync();
    }
  }

  void clearUnreadDivider() {
    if (state.unreadAnchorId != null) state = state.copyWith(clearUnread: true);
  }

  /// Pulses a bubble (2 × 600ms). A match the app doesn't hold yet (server
  /// search) is loaded first via `messages/around/{id}`.
  void highlight(String messageId) {
    if (!_repo.current(arg).any((m) => m.id == messageId)) {
      unawaited(_repo.loadAround(arg, messageId).then((found) {
        if (found) highlight(messageId);
      }));
      return;
    }
    ensureLoaded(messageId);
    _highlightTimer?.cancel();
    state = state.copyWith(highlightId: messageId);
    _highlightTimer = Timer(const Duration(milliseconds: 1300), () => state = state.copyWith(clearHighlight: true));
  }

  String send(OutgoingMessage m) {
    Analytics.log('chat_message_send', {
      'type': m.kind.name,
      'is_note': m.isNote,
      'sent_via': m.sentVia,
      'has_reply_quote': m.quote != null,
    });
    if (!_replied && !m.isNote) {
      _replied = true;
      Analytics.log('chat_first_reply', {
        'seconds_since_open': DateTime.now().difference(_openedAt ?? DateTime.now()).inSeconds,
        'method': switch (m.sentVia) {
          'ai_suggestion' => 'ai_send',
          'ai_edited' => 'ai_edit',
          final v => v,
        },
      });
    }
    clearUnreadDivider();
    return _repo.send(arg, m);
  }

  void retry(String messageId) => _repo.retry(arg, messageId);

  void discard(String messageId) {
    final m = state.messages.where((x) => x.id == messageId).firstOrNull;
    Analytics.log('chat_send_failed', {'error_code': 'discarded', 'retries': m?.retries ?? 0});
    _repo.discard(arg, messageId);
  }

  void delete(String messageId) => _repo.delete(arg, messageId);
  void react(String messageId, String emoji) => _repo.react(arg, messageId, emoji);

  void feedback(String messageId, String rating) {
    Analytics.log('chat_ai_feedback', {'rating': rating});
    _repo.feedback(arg, messageId, rating);
  }

  Future<void> transcribe(String messageId) => _repo.transcribe(arg, messageId);
}
