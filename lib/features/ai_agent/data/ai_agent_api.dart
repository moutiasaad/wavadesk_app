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

/// Sample mode: an in-memory workspace. Demo triggers in the test chat:
/// "موظف" → handoff (human_request), "#500" → error, "#slow" → 4 s.
class SampleAiAgentApi implements AiAgentApi {
  SampleAiAgentApi({this.canEdit = true});

  final bool canEdit;
  late AiAgentConfig _config = _seed();
  final List<AiAuditEntry> _audit = [];
  int _replies = 0;

  @override
  Future<AiAgentConfig> fetch() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _config;
  }

  @override
  Future<AiAgentConfig> patch(int version, Map<String, Object?> changes) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!canEdit) throw const AiAgentApiException(403, code: 'role_forbidden');
    if (version != _config.version) {
      throw AiAgentApiException(409, code: 'version_conflict', current: _config, changedBy: 'سارة');
    }
    final merged = {..._config.toJson(), ...changes, 'version': _config.version + 1};
    final hours = WorkingHours.fromJson(Map<String, dynamic>.from(merged['hours']! as Map));
    final handoff = HandoffRules.fromJson(Map<String, dynamic>.from(merged['handoff']! as Map));
    merged['readiness'] = {..._config.readiness.toJson(), 'hours_set': hours.isSet, 'handoff_set': handoff.anyRule};
    _config = AiAgentConfig.fromJson(merged);
    _audit.insert(0, AiAuditEntry(id: 'aud_${_audit.length + 1}', actorName: 'أنت', at: DateTime.now(), changes: changes.keys.toList()));
    return _config;
  }

  @override
  Future<AiTestReply> test({String? sessionId, required String message, required String channel}) async {
    await Future<void>.delayed(Duration(milliseconds: message.contains('#slow') ? 4000 : 900));
    if (message.contains('#500')) throw const AiAgentApiException(503, code: 'ai_unavailable');
    _config = _config.copyWith(readiness: _config.readiness.copyWith(tested: true));
    final id = 'rep_${++_replies}';
    final human = message.contains('موظف') || message.toLowerCase().contains('human');
    if (human) {
      return AiTestReply(id: id, reply: _config.handoff.message, ruleTriggered: 'human_request', handoff: true, confidence: 0.95, tone: _config.tone);
    }
    final shipping = message.contains('توصيل') || message.contains('شحن');
    return AiTestReply(
      id: id,
      reply: shipping
          ? 'التوصيل للدمام 25 ريال، ومجاني فوق 300. يوصلك خلال 2–3 أيام.'
          : 'أهلًا بك! نعمل من السبت إلى الخميس من 9 صباحًا حتى 10 مساءً.',
      sources: [shipping ? ('kb_12', 'رسوم التوصيل') : ('kb_3', 'أوقات العمل')],
      confidence: 0.86,
      tone: _config.tone,
    );
  }

  @override
  Future<void> resetTest() async {}

  @override
  Future<void> feedback(String replyId, String rating) async {}

  @override
  Future<(List<AiAuditEntry>, String?)> audit({String? cursor}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return (
      [
        ..._audit,
        AiAuditEntry(id: 'aud_s2', actorName: 'سارة', at: DateTime.now().subtract(const Duration(days: 1)), changes: const ['tone']),
        AiAuditEntry(id: 'aud_s1', actorName: 'أحمد', at: DateTime.now().subtract(const Duration(days: 4)), changes: const ['mode', 'handoff']),
      ],
      null,
    );
  }

  @override
  Future<List<Holiday>> holidays({String country = 'SA', required int year}) async => [
        Holiday(id: 'founding_$year', name: 'يوم التأسيس', date: '$year-02-22', enabled: true),
        Holiday(id: 'national_$year', name: 'اليوم الوطني', date: '$year-09-23', enabled: true),
      ];

  @override
  Future<RewriteStyle> createStyle(String name, String instruction) async {
    final s = RewriteStyle(id: 'style_${DateTime.now().millisecondsSinceEpoch}', name: name, instruction: instruction);
    _config = _config.copyWith(rewriteStyles: [..._config.rewriteStyles, s]);
    return s;
  }

  @override
  Future<void> deleteStyle(String id) async {
    _config = _config.copyWith(rewriteStyles: [for (final s in _config.rewriteStyles) if (s.id != id) s]);
  }

  AiAgentConfig _seed() {
    final now = DateTime.now();
    return AiAgentConfig(
      version: 17,
      enabled: true,
      mode: AiMode.auto,
      tone: AiTone.friendly,
      hours: WorkingHours(
        week: [
          for (final d in weekDays)
            DayHours(day: d, open: d != 'fri', ranges: d == 'fri' ? const [] : const [TimeRange(9 * 60, 22 * 60)]),
        ],
        holidays: [Holiday(id: 'national_${now.year}', name: 'اليوم الوطني', date: '${now.year}-09-23', enabled: true)],
      ),
      handoff: const HandoffRules(afterReplies: 4, keywords: ['محامي', 'شكوى رسمية', 'إلغاء الاشتراك'], message: 'سأحوّلك الآن لأحد زملائي ليساعدك، لحظات من فضلك.'),
      channels: const {'whatsapp': true, 'web': true, 'messenger': false},
      rewriteStyles: const [RewriteStyle(id: 'style_1', name: 'اعتذار لطيف', instruction: 'ابدأ باعتذار قصير ثم الحل')],
      stats: AiWeekStats(
        answered: 142,
        hoursSaved: 6,
        resolutionRate: 0.64,
        thumbsUpRate: 0.91,
        handoffs: 18,
        topHandoffReasons: const [('human_request', 8), ('payment', 5), ('no_answer', 3), ('complaint', 2)],
        topSources: const [('kb_12', 'رسوم التوصيل', 41), ('kb_3', 'أوقات العمل', 30), ('kb_7', 'سياسة الاسترجاع', 22)],
        daily: [for (var i = 6; i >= 0; i--) (now.subtract(Duration(days: i)), 14 + (i * 7) % 11, 1 + i % 4)],
      ),
      readiness: const AiReadinessFacts(kbEntries: 28, hoursSet: true, handoffSet: true),
      usage: AiUsage(used: 1640, limit: 2000, resetsAt: DateTime(now.year, now.month + 1)),
      handlingNow: 41,
      canEdit: canEdit,
      unansweredCount: 5,
    );
  }
}
