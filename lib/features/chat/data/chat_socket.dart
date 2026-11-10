import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../auth/data/auth_api.dart' show apiBaseUrl;

/// Per-conversation real-time events (Chat spec §7). Channels
/// `conversation.{id}` + `presence-conversation.{id}`.
sealed class ChatSocketEvent {
  const ChatSocketEvent();
}

class ChatRefreshNeeded extends ChatSocketEvent {
  const ChatRefreshNeeded();
}

class ChatInboundMessage extends ChatSocketEvent {
  const ChatInboundMessage();
}

/// Ownership moved away from me (snackbar "أُسندت المحادثة إلى {name}").
class ChatTakenFromMe extends ChatSocketEvent {
  const ChatTakenFromMe(this.byName);
  final String byName;
}

abstract interface class ChatSocket {
  Stream<ChatSocketEvent> events(String conversationId);

  /// online / connecting / offline — drives banner priority 1.
  Stream<NetworkState> get status;
  NetworkState get currentStatus;
  void dispose();
}

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final s = apiBaseUrl.isEmpty ? SampleChatSocket(ref) : PollingChatSocket();
  ref.onDispose(s.dispose);
  return s;
});

/// Bridges the sample [InboxController] events.
class SampleChatSocket implements ChatSocket {
  SampleChatSocket(this._ref) {
    _current = _ref.read(inboxProvider).network;
    _ref.listen(inboxProvider.select((s) => s.network), (_, n) {
      _current = n;
      _status.add(n);
    });
  }

  final Ref _ref;
  final _status = StreamController<NetworkState>.broadcast();
  late NetworkState _current;

  @override
  Stream<ChatSocketEvent> events(String conversationId) => _ref
      .read(inboxProvider.notifier)
      .events
      .where((e) => e.conversationId == conversationId)
      .map(
        (e) => switch (e) {
          NewMessageEvent() => const ChatInboundMessage(),
          ColleagueClaimedEvent(:final agent) => ChatTakenFromMe(agent.name),
          AssignedToMeEvent() || NewConversationEvent() => const ChatRefreshNeeded(),
        },
      );

  @override
  Stream<NetworkState> get status => _status.stream;

  @override
  NetworkState get currentStatus => _current;

  @override
  void dispose() => _status.close();
}

/// Fallback while no WebSocket client is wired: refresh every 15s (§7).
class PollingChatSocket implements ChatSocket {
  final _status = StreamController<NetworkState>.broadcast();

  @override
  Stream<ChatSocketEvent> events(String conversationId) =>
      Stream.periodic(const Duration(seconds: 15), (_) => const ChatRefreshNeeded());

  @override
  Stream<NetworkState> get status => _status.stream;

  @override
  NetworkState get currentStatus => NetworkState.online;

  @override
  void dispose() => _status.close();
}
