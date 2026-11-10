import 'dart:async';

import '../../../core/api/wd_api.dart';
import '../domain/ai_agent_config.dart';

class AiAgentApiException implements Exception {
  const AiAgentApiException(this.status, {this.code, this.message, this.current, this.changedBy});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;

  /// 409 `version_conflict`: the server's current config.
  final AiAgentConfig? current;

  /// 409: who saved last (for "عدّل {name} الإعدادات للتو").
  final String? changedBy;

  bool get isNetwork => status == 0;
  bool get isConflict => status == 409;

  @override
  String toString() => 'AiAgentApiException($status $code)';
}

/// AI Agent spec §8.
abstract interface class AiAgentApi {
  Future<AiAgentConfig> fetch();

  /// [changes] are wire-named partial fields; the server answers the full config.
  Future<AiAgentConfig> patch(int version, Map<String, Object?> changes);
  Future<AiTestReply> test({String? sessionId, required String message, required String channel});
  Future<void> resetTest();
  Future<void> feedback(String replyId, String rating);

  /// (rows, nextCursor)
  Future<(List<AiAuditEntry>, String?)> audit({String? cursor});
  Future<List<Holiday>> holidays({String country = 'SA', required int year});

  Future<RewriteStyle> createStyle(String name, String instruction);
  Future<void> deleteStyle(String id);
}

class HttpAiAgentApi implements AiAgentApi {
  HttpAiAgentApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      final cur = e.details['current'];
      throw AiAgentApiException(
        e.status,
        code: e.code,
        message: e.message,
        current: cur is Map ? AiAgentConfig.fromJson(Map<String, dynamic>.from(cur)) : null,
        changedBy: e.details['changed_by'] as String?,
      );
    }
  }

  @override
  Future<AiAgentConfig> fetch() => _guard(() async => AiAgentConfig.fromJson((await _api.get('ai-agent')).map));

  @override
  Future<AiAgentConfig> patch(int version, Map<String, Object?> changes) =>
      _guard(() async => AiAgentConfig.fromJson((await _api.patch('ai-agent', body: {'version': version, ...changes})).map));

  @override
  Future<AiTestReply> test({String? sessionId, required String message, required String channel}) => _guard(() async {
        final r = await _api.post('ai-agent/test', body: {'session_id': ?sessionId, 'message': message, 'channel': channel});
        return AiTestReply.fromJson(r.map);
      });

  @override
  Future<void> resetTest() => _guard(() => _api.post('ai-agent/test/reset', body: const <String, Object?>{}));

  @override
  Future<void> feedback(String replyId, String rating) =>
      _guard(() => _api.post('ai-agent/test/feedback', body: {'reply_id': replyId, 'rating': rating}));

  @override
  Future<(List<AiAuditEntry>, String?)> audit({String? cursor}) => _guard(() async {
        final r = await _api.get('ai-agent/audit', query: {'cursor': cursor});
        return ([for (final row in r.list) AiAuditEntry.fromJson(row)], r.meta['next_cursor'] as String?);
      });

  @override
  Future<List<Holiday>> holidays({String country = 'SA', required int year}) => _guard(() async {
        final r = await _api.get('holidays', query: {'country': country, 'year': year});
        return [for (final h in r.list) Holiday.fromJson(h)];
      });

  @override
  Future<RewriteStyle> createStyle(String name, String instruction) => _guard(() async {
        final r = await _api.post('ai/rewrite-styles', body: {'name': name, 'instruction': instruction});
        final m = r.map;
        return RewriteStyle(id: '${m['id']}', name: '${m['name'] ?? name}', instruction: '${m['instruction'] ?? instruction}');
      });

  @override
  Future<void> deleteStyle(String id) => _guard(() => _api.delete('ai/rewrite-styles/$id'));
}
