import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';

/// Real-time events the inbox reacts to (Inbox spec §5).
sealed class InboxSocketEvent {
  const InboxSocketEvent();
}

/// Something changed server-side; re-read the visible window.
class InboxRefreshNeeded extends InboxSocketEvent {
  const InboxRefreshNeeded();
}

class InboxAssignedToMe extends InboxSocketEvent {
  const InboxAssignedToMe(this.conversationId, this.byName);
  final String conversationId;
  final String byName;
}

class InboxClaimedByColleague extends InboxSocketEvent {
  const InboxClaimedByColleague(this.conversationId, this.name);
  final String conversationId;
  final String name;
}

class InboxNewConversation extends InboxSocketEvent {
  const InboxNewConversation(this.conversationId);
  final String conversationId;
}

class InboxInboundMessage extends InboxSocketEvent {
  const InboxInboundMessage(this.conversationId, {required this.assignedToMe});
  final String conversationId;
  final bool assignedToMe;
}

/// Channel `workspace.{id}.agent.{userId}`. Implementation: 20s polling
/// while a WebSocket client isn't wired yet.
abstract interface class ConversationsSocket {
  Stream<InboxSocketEvent> get events;

  /// online / connecting (socket down > 3s) / offline.
  Stream<NetworkState> get status;
  NetworkState get currentStatus;
  void dispose();
}

final conversationsSocketProvider = Provider<ConversationsSocket>((ref) {
  final socket = PollingConversationsSocket();
  ref.onDispose(socket.dispose);
  return socket;
});

/// Fallback transport (§5): asks for a refresh every 20s and maps device
/// connectivity to the banner states.
class PollingConversationsSocket implements ConversationsSocket {
  PollingConversationsSocket() {
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _events.add(const InboxRefreshNeeded()));
    try {
      _conn = Connectivity().onConnectivityChanged.listen((r) {
        final offline = r.isEmpty || r.every((x) => x == ConnectivityResult.none);
        final next = offline ? NetworkState.offline : NetworkState.online;
        if (next == _current) return;
        _current = next;
        _status.add(next);
        if (next == NetworkState.online) _events.add(const InboxRefreshNeeded());
      }, onError: (_) {});
    } catch (_) {}
  }

  final _events = StreamController<InboxSocketEvent>.broadcast();
  final _status = StreamController<NetworkState>.broadcast();
  late final Timer _timer;
  StreamSubscription<List<ConnectivityResult>>? _conn;
  NetworkState _current = NetworkState.online;

  @override
  Stream<InboxSocketEvent> get events => _events.stream;

  @override
  Stream<NetworkState> get status => _status.stream;

  @override
  NetworkState get currentStatus => _current;

  @override
  void dispose() {
    _timer.cancel();
    _conn?.cancel();
    _events.close();
    _status.close();
  }
}
