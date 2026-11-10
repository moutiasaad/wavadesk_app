import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/analytics.dart';
import '../data/ai_agent_api.dart';
import '../domain/ai_agent_config.dart';
import 'ai_agent_controller.dart';

enum AiTestRole { tester, ai, handoff, error }

@immutable
class AiTestMessage {
  const AiTestMessage({required this.id, required this.role, required this.text, this.reply, this.rating, required this.at});

  final String id;
  final AiTestRole role;
  final String text;

  /// AI replies: sources, confidence, rule ("لماذا هذا الرد؟").
  final AiTestReply? reply;

  /// 'up' | 'down'
  final String? rating;
  final DateTime at;

  AiTestMessage withRating(String? r) => AiTestMessage(id: id, role: role, text: text, reply: reply, rating: r, at: at);
}

@immutable
class AiTestState {
  const AiTestState({required this.sessionId, this.messages = const [], this.sending = false, this.channel = 'whatsapp'});

  final String sessionId;
  final List<AiTestMessage> messages;
  final bool sending;

  /// whatsapp | web
  final String channel;

  bool get started => messages.isNotEmpty;

  AiTestState copyWith({String? sessionId, List<AiTestMessage>? messages, bool? sending, String? channel}) => AiTestState(
        sessionId: sessionId ?? this.sessionId,
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        channel: channel ?? this.channel,
      );
}

final aiTestControllerProvider = NotifierProvider.autoDispose<AiTestController, AiTestState>(AiTestController.new);

/// Sandbox chat (AI Agent spec §5.5): roles flip — the tester is the
/// customer, the AI answers from the current saved config.
class AiTestController extends AutoDisposeNotifier<AiTestState> {
  static const _uuid = Uuid();

  AiAgentApi get _api => ref.read(aiAgentApiProvider);

  @override
  AiTestState build() => AiTestState(sessionId: _uuid.v4());

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty || state.sending) return;
    final mine = AiTestMessage(id: _uuid.v4(), role: AiTestRole.tester, text: t, at: DateTime.now());
    state = state.copyWith(messages: [...state.messages, mine], sending: true);
    try {
      final r = await _api.test(sessionId: state.sessionId, message: t, channel: state.channel);
      final c = r.confidence;
      Analytics.log('ai_test_message', {
        'channel': state.channel,
        'handoff': r.handoff,
        'confidence_bucket': c == null ? null : (c >= 0.8 ? 'high' : (c >= 0.5 ? 'medium' : 'low')),
        'sources_count': r.sources.length,
      });
      state = state.copyWith(
        sending: false,
        messages: [
          ...state.messages,
          if (r.reply.isNotEmpty) AiTestMessage(id: r.id, role: AiTestRole.ai, text: r.reply, reply: r, at: DateTime.now()),
          if (r.handoff) AiTestMessage(id: '${r.id}_h', role: AiTestRole.handoff, text: r.ruleTriggered ?? '', reply: r, at: DateTime.now()),
        ],
      );
      ref.read(aiAgentControllerProvider.notifier).markTested();
    } catch (e) {
      final code = e is AiAgentApiException ? (e.code ?? '') : '';
      state = state.copyWith(
        sending: false,
        messages: [...state.messages, AiTestMessage(id: _uuid.v4(), role: AiTestRole.error, text: code, at: DateTime.now())],
      );
    }
  }

  Future<void> reset() async {
    state = AiTestState(sessionId: _uuid.v4(), channel: state.channel);
    try {
      await _api.resetTest();
    } catch (_) {}
  }

  void setChannel(String channel) {
    if (channel == state.channel) return;
    state = AiTestState(sessionId: _uuid.v4(), channel: channel);
  }

  Future<void> rate(String messageId, String rating) async {
    final msg = state.messages.where((m) => m.id == messageId).firstOrNull;
    if (msg == null) return;
    final next = msg.rating == rating ? null : rating;
    state = state.copyWith(messages: [for (final m in state.messages) m.id == messageId ? m.withRating(next) : m]);
    if (next == null) return;
    Analytics.log('ai_test_feedback', {'rating': next});
    try {
      await _api.feedback(messageId, next);
    } catch (_) {}
  }
}
