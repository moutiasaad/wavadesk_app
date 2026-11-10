import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../data/chat_api.dart';

@immutable
class ViewerPresence {
  const ViewerPresence({required this.agent, required this.since});

  final Agent agent;

  /// When they started viewing ("منذ {n} ث").
  final DateTime since;
}

final presenceControllerProvider = NotifierProvider.autoDispose
    .family<PresenceController, List<ViewerPresence>, String>(PresenceController.new);

/// Who else is viewing (Claim spec §9, channel `presence-conversation.{id}`).
/// Also keeps *me* present while the screen is visible: [join] on open /
/// resume, [leave] on pop / background, heartbeat every 30s with a backend.
class PresenceController extends AutoDisposeFamilyNotifier<List<ViewerPresence>, String> {
  final Map<String, DateTime> _since = {};

  @override
  List<ViewerPresence> build(String id) {
    final viewers = ref.watch(conversationProvider(id).select((c) => c?.viewers ?? const <Agent>[]));
    final me = ref.read(currentAgentProvider).id;
    // Real API: viewers[].since from the detail (when they opened it).
    final serverSince = ref.watch(remoteChatPermissionsProvider.select((m) => m[id]?.viewerSince)) ?? const {};
    final now = DateTime.now();
    final present = [
      for (final v in viewers)
        if (v.id != me) v,
    ];
    _since.removeWhere((k, _) => !present.any((v) => v.id == k));
    return [
      for (final v in present) ViewerPresence(agent: v, since: serverSince[v.id] ?? _since.putIfAbsent(v.id, () => now)),
    ];
  }

  /// Real API: there is no join/leave endpoint. `GET conversations/{id}`
  /// records me as a viewer for 60 s and returns the other viewers, so a
  /// join is an immediate detail fetch; [chatRemoteSyncProvider] repeats it
  /// every 15 s while the app is in the foreground (the heartbeat), and
  /// leaving simply lets the server entry expire.
  void join() {
    final api = ref.read(chatApiProvider);
    unawaited(api.detail(arg).then((r) => syncRemoteConversation(ref, r)).catchError((Object _) {}));
  }

  void leave() {}
}
