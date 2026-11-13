import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../auth/application/auth_session.dart';

/// System pills the real API doesn't return in the message list (it has no
/// ownership events), kept for this app session and merged into the thread
/// by `MessagesController`: "استلمت المحادثة", "استلم {name} المحادثة"
/// (Claim spec §6).
final localChatEventsProvider = NotifierProvider<LocalChatEvents, Map<String, List<Message>>>(LocalChatEvents.new);

class LocalChatEvents extends Notifier<Map<String, List<Message>>> {
  int _seq = 0;

  @override
  Map<String, List<Message>> build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    return const {};
  }

  void add(String conversationId, SystemEvent event) {
    final m = Message(
      id: 'local-evt-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      type: MessageBubbleType.system,
      sentAt: DateTime.now(),
      systemEvent: event,
    );
    state = {
      ...state,
      conversationId: [...?state[conversationId], m],
    };
  }
}
