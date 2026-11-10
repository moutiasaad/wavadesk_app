import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';

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
  final s = PollingChatSocket();
  ref.onDispose(s.dispose);
  return s;
});

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
