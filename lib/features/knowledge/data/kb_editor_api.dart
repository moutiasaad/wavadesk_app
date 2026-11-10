import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../domain/kb_entry.dart';
import '../domain/phrasing_normalizer.dart';
import 'kb_sample_store.dart';

class KbEditorApiException implements Exception {
  const KbEditorApiException(this.status, {this.code, this.message, this.current, this.updatedBy, this.fields = const {}});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;

  /// 409 `version_conflict`: the server's copy and who saved it.
  final KbQa? current;
  final String? updatedBy;

  /// 422 field errors (e.g. the content-safety screen on `answer`).
  final Map<String, List<String>> fields;

  bool get isNetwork => status == 0;
  bool get isConflict => status == 409;
  bool get isNotFound => status == 404 || status == 410;
  bool get isForbidden => status == 403;
  bool get isRateLimited => status == 429;

  @override
  String toString() => 'KbEditorApiException($status $code)';
}

enum KbConfidence {
  high,
  medium,
  low;

  static KbConfidence parse(Object? v) => values.asNameMap()['$v'] ?? medium;
}

@immutable
class KbSaveResult {
  const KbSaveResult(this.entry, {this.resolvedUnanswered = 0, this.waitingConversations = 0});

  final KbQa entry;
  final int resolvedUnanswered;
  final int waitingConversations;
}

/// `GET messages/{id}/kb-prefill`.
@immutable
class KbMessagePrefill {
  const KbMessagePrefill({required this.question, required this.answer, this.customerName, this.date, this.conversationId});

  final String question;
  final String answer;
  final String? customerName;
  final DateTime? date;
  final String? conversationId;
}

@immutable
class KbSimilar {
  const KbSimilar({required this.id, required this.title, this.score = 0});

  final String id;
  final String title;
  final double score;
}

@immutable
class KbConflict {
  const KbConflict({required this.id, required this.title, required this.reason});

  final String id;
  final String title;
  final String reason;
}

@immutable
class KbDuplicateCheck {
  const KbDuplicateCheck({this.similar = const [], this.conflicts = const []});

  final List<KbSimilar> similar;
  final List<KbConflict> conflicts;
}

@immutable
class KbPreview {
  const KbPreview({required this.testQuestion, required this.reply, required this.confidence, required this.tone});

  final String testQuestion;
  final String reply;
  final KbConfidence confidence;

  /// Wire tone (`friendly|formal|concise`), labelled by the AI Agent strings.
  final String tone;
}

@immutable
class KbVersion {
  const KbVersion({required this.version, this.by, required this.at, required this.summary});

  final int version;
  final KbPerson? by;
  final DateTime at;
  final String summary;
}

/// Add Answer spec §8.
abstract interface class KbEditorApi {
  Future<KbQa> fetch(String id);
  Future<KbQa> fetchDraft(String id);
  Future<KbUnanswered> fetchUnanswered(String id);

  /// [hintQuestion]/[hintAnswer] come from the chat screen; the sample API
  /// has no message store and answers with them.
  Future<KbMessagePrefill> messagePrefill(String messageId, {String? hintQuestion, String? hintAnswer});

  Future<KbSaveResult> create(Map<String, Object?> body, {required String idempotencyKey});
  Future<KbSaveResult> update(String id, int version, Map<String, Object?> body, {required String idempotencyKey});
  Future<KbQa> propose(Map<String, Object?> body, {required String idempotencyKey});
  Future<KbSaveResult> approveDraft(String id, Map<String, Object?> body);
  Future<void> rejectDraft(String id, {String? reason});
  Future<void> delete(String id);

  Future<List<KbTag>> tags();
  Future<List<String>> suggestPhrasings(String question);
  Future<KbDuplicateCheck> checkDuplicates({required String question, String? answer, String? excludeId});
  Future<KbPreview> preview({
    required String question,
    required String answer,
    required List<String> altPhrasings,
    String? testQuestion,
    required bool verbatim,
  });
  Future<List<KbVersion>> versions(String id);
  Future<KbQa> restoreVersion(String id, int version);
}

final kbEditorApiProvider = Provider<KbEditorApi>((ref) {
  if (useRealApi) return HttpKbEditorApi(ref.watch(wdApiRequiredProvider));
  return SampleKbEditorApi(me: ref.read(currentAgentProvider));
});

// ---- HTTP -------------------------------------------------------------------------

class HttpKbEditorApi implements KbEditorApi {
  HttpKbEditorApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      final cur = e.details['current'];
      final fields = <String, List<String>>{};
      for (final entry in e.details.entries) {
        if (entry.value is List) fields[entry.key] = [for (final m in entry.value as List) '$m'];
      }
      final by = e.details['updated_by'];
      throw KbEditorApiException(
        e.status,
        code: e.code,
        message: e.message,
        current: cur is Map ? KbQa.fromJson(Map<String, dynamic>.from(cur)) : null,
        updatedBy: by is Map ? '${by['name'] ?? ''}' : by as String?,
        fields: fields,
      );
    }
  }

  static KbSaveResult _saved(WdResponse r) => KbSaveResult(
        KbQa.fromJson(r.map),
        resolvedUnanswered: (r.meta['resolved_unanswered'] as num?)?.toInt() ?? 0,
        waitingConversations: (r.meta['waiting_conversations'] as num?)?.toInt() ?? 0,
      );

  @override
  Future<KbQa> fetch(String id) => _guard(() async => KbQa.fromJson((await _api.get('kb/$id')).map));

  @override
  Future<KbQa> fetchDraft(String id) => _guard(() async => KbQa.fromJson((await _api.get('kb/drafts/$id')).map));

  @override
  Future<KbUnanswered> fetchUnanswered(String id) =>
      _guard(() async => KbUnanswered.fromJson((await _api.get('kb/unanswered/$id')).map));

  @override
  Future<KbMessagePrefill> messagePrefill(String messageId, {String? hintQuestion, String? hintAnswer}) => _guard(() async {
        final m = (await _api.get('messages/$messageId/kb-prefill')).map;
        final date = m['date'];
        return KbMessagePrefill(
          question: '${m['question'] ?? hintQuestion ?? ''}',
          answer: '${m['answer'] ?? hintAnswer ?? ''}',
          customerName: m['customer_name'] as String?,
          date: date is String ? DateTime.tryParse(date)?.toLocal() : null,
          conversationId: m['conversation_id'] as String?,
        );
      });

  @override
  Future<KbSaveResult> create(Map<String, Object?> body, {required String idempotencyKey}) =>
      _guard(() async => _saved(await _api.post('kb', body: body, idempotencyKey: idempotencyKey)));

  @override
  Future<KbSaveResult> update(String id, int version, Map<String, Object?> body, {required String idempotencyKey}) =>
      _guard(() async => _saved(await _api.patch('kb/$id', body: {'version': version, ...body}, idempotencyKey: idempotencyKey)));

  @override
  Future<KbQa> propose(Map<String, Object?> body, {required String idempotencyKey}) =>
      _guard(() async => KbQa.fromJson((await _api.post('kb/drafts', body: body, idempotencyKey: idempotencyKey)).map));

  @override
  Future<KbSaveResult> approveDraft(String id, Map<String, Object?> body) =>
      _guard(() async => _saved(await _api.post('kb/drafts/$id/approve', body: body)));

  @override
  Future<void> rejectDraft(String id, {String? reason}) =>
      _guard(() => _api.post('kb/drafts/$id/reject', body: {'reason': ?reason}));

  @override
  Future<void> delete(String id) => _guard(() => _api.delete('kb/$id'));

  @override
  Future<List<KbTag>> tags() => _guard(() async => [for (final t in (await _api.get('kb/tags')).list) KbTag.fromJson(t)]);

  @override
  Future<List<String>> suggestPhrasings(String question) => _guard(() async {
        final m = (await _api.post('kb/suggest-phrasings', body: {'question': question})).map;
        return [for (final s in (m['phrasings'] as List? ?? const [])) '$s'];
      });

  @override
  Future<KbDuplicateCheck> checkDuplicates({required String question, String? answer, String? excludeId}) => _guard(() async {
        final m = (await _api.post('kb/check-duplicates', body: {'question': question, 'answer': ?answer, 'exclude_id': ?excludeId})).map;
        return KbDuplicateCheck(
          similar: [
            for (final s in (m['similar'] as List? ?? const []).whereType<Map>())
              KbSimilar(id: '${s['id']}', title: '${s['title'] ?? ''}', score: (s['score'] as num?)?.toDouble() ?? 0),
          ],
          conflicts: [
            for (final s in (m['conflicts'] as List? ?? const []).whereType<Map>())
              KbConflict(id: '${s['id']}', title: '${s['title'] ?? ''}', reason: '${s['reason'] ?? ''}'),
          ],
        );
      });

  @override
  Future<KbPreview> preview({
    required String question,
    required String answer,
    required List<String> altPhrasings,
    String? testQuestion,
    required bool verbatim,
  }) =>
      _guard(() async {
        final m = (await _api.post('kb/preview-answer', body: {
          'question': question,
          'answer': answer,
          'alt_phrasings': altPhrasings,
          'test_question': ?testQuestion,
          'verbatim': verbatim,
        }))
            .map;
        return KbPreview(
          testQuestion: '${m['test_question'] ?? testQuestion ?? question}',
          reply: '${m['reply'] ?? m['answer'] ?? ''}',
          confidence: KbConfidence.parse(m['confidence']),
          tone: '${m['tone'] ?? 'friendly'}',
        );
      });

  @override
  Future<List<KbVersion>> versions(String id) => _guard(() async => [
        for (final v in (await _api.get('kb/$id/versions')).list)
          KbVersion(
            version: (v['version'] as num?)?.toInt() ?? 0,
            by: KbPerson.fromJson(v['by']),
            at: DateTime.tryParse('${v['at']}')?.toLocal() ?? DateTime.now(),
            summary: '${v['summary'] ?? ''}',
          ),
      ]);

  @override
  Future<KbQa> restoreVersion(String id, int version) =>
      _guard(() async => KbQa.fromJson((await _api.post('kb/$id/versions/$version/restore', body: const <String, Object?>{})).map));
}

// ---- Sample -----------------------------------------------------------------------

/// Offline demo on [KbSampleStore]. Triggers typed into the answer:
/// `#err` (save fails), `#409` (conflict), `#preview` (preview fails).
class SampleKbEditorApi implements KbEditorApi {
  SampleKbEditorApi({required this.me});

  final Agent me;
  KbSampleStore get _store => KbSampleStore.instance;

  /// Snapshots per entry id, oldest first (version history).
  static final Map<String, List<(KbVersion, KbQa)>> _history = {};

  final _rnd = math.Random();

  Future<void> _latency([int base = 450]) => Future<void>.delayed(Duration(milliseconds: base + _rnd.nextInt(300)));

  KbPerson get _person => KbPerson(id: me.id, name: me.name, avatarUrl: me.avatarUrl);

  KbQa _require(String id) {
    final e = _store.qaById(id) ?? _legacy(id);
    if (e == null) throw const KbEditorApiException(404, code: 'not_found');
    return e;
  }

  /// Older sample screens (AI suggestion card, search, AI test "why") still
  /// link the `assets/fake` knowledge ids; adopt them into the store.
  KbQa? _legacy(String id) {
    for (final k in MockData.knowledge()) {
      if (k.id != id) continue;
      final e = KbQa(
        id: k.id,
        question: k.title,
        answer: k.body,
        altPhrasings: k.keywords,
        enabled: k.enabled,
        status: k.enabled ? KbStatus.active : KbStatus.disabled,
        usage: KbUsage(month: k.usageCount),
        createdAt: k.updatedAt,
        updatedAt: k.updatedAt,
      );
      _store.upsertQa(e);
      return e;
    }
    return null;
  }

  KbQa _fromBody(String id, Map<String, Object?> b, {KbQa? base, KbStatus? status}) {
    final now = DateTime.now();
    final enabled = b['enabled'] as bool? ?? base?.enabled ?? true;
    return KbQa(
      id: id,
      question: '${b['question'] ?? base?.question ?? ''}'.trim(),
      answer: '${b['answer'] ?? base?.answer ?? ''}'.trim(),
      altPhrasings: [for (final s in (b['alt_phrasings'] as List? ?? base?.altPhrasings ?? const [])) '$s'],
      tags: [for (final t in (b['tag_ids'] as List? ?? [for (final t in base?.tags ?? const <KbTag>[]) t.id])) KbTag(id: '$t', name: '$t')],
      enabled: enabled,
      status: status ?? (enabled ? KbStatus.active : KbStatus.disabled),
      version: (base?.version ?? 0) + 1,
      channels: b.containsKey('channels') ? (b['channels'] as List?)?.map((e) => '$e').toList() : base?.channels,
      expiresAt: b.containsKey('expires_at')
          ? (b['expires_at'] == null ? null : DateTime.tryParse('${b['expires_at']}')?.toLocal())
          : base?.expiresAt,
      verbatim: b['verbatim'] as bool? ?? base?.verbatim ?? false,
      handoffAfter: b['handoff_after'] as bool? ?? base?.handoffAfter ?? false,
      internalNotes: b.containsKey('internal_notes') ? b['internal_notes'] as String? : base?.internalNotes,
      usage: base?.usage ?? const KbUsage(),
      recentUses: base?.recentUses ?? const [],
      createdBy: base?.createdBy ?? _person,
      updatedBy: _person,
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
      draftedBy: status == KbStatus.draft ? _person : null,
      draftSource: status == KbStatus.draft ? KbDraftSource.agent : null,
    );
  }

  void _snapshot(KbQa e, String summary) {
    (_history[e.id] ??= []).add((KbVersion(version: e.version, by: e.updatedBy, at: e.updatedAt ?? DateTime.now(), summary: summary), e));
  }

  (int, int) _resolveSource(Map<String, Object?> b) {
    final src = b['source'];
    if (src is Map && src['type'] == 'unanswered') {
      final u = _store.unansweredById('${src['id']}');
      if (u != null) {
        _store.unanswered.remove(u);
        return (1, u.conversationIds.length.clamp(1, 99));
      }
    }
    return (0, 0);
  }

  void _maybeFail(Map<String, Object?> b) {
    final a = '${b['answer'] ?? ''}';
    if (a.contains('#err')) throw const KbEditorApiException(500, code: 'server_error');
  }

  @override
  Future<KbQa> fetch(String id) async {
    await _latency(350);
    return _require(id);
  }

  @override
  Future<KbQa> fetchDraft(String id) async {
    await _latency(350);
    for (final d in _store.drafts) {
      if (d.id == id) return d;
    }
    throw const KbEditorApiException(404, code: 'not_found');
  }

  @override
  Future<KbUnanswered> fetchUnanswered(String id) async {
    await _latency(350);
    final u = _store.unansweredById(id);
    if (u == null) throw const KbEditorApiException(404, code: 'not_found');
    return u;
  }

  @override
  Future<KbMessagePrefill> messagePrefill(String messageId, {String? hintQuestion, String? hintAnswer}) async {
    await _latency(300);
    return KbMessagePrefill(
      question: hintQuestion ?? '',
      answer: hintAnswer ?? '',
      customerName: 'وعد الزهراني',
      date: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  @override
  Future<KbSaveResult> create(Map<String, Object?> body, {required String idempotencyKey}) async {
    await _latency(700);
    _maybeFail(body);
    final e = _fromBody(_store.nextId('kb'), body);
    _store.upsertQa(e);
    _snapshot(e, 'إنشاء الإجابة');
    final (resolved, waiting) = _resolveSource(body);
    return KbSaveResult(e, resolvedUnanswered: resolved, waitingConversations: waiting);
  }

  @override
  Future<KbSaveResult> update(String id, int version, Map<String, Object?> body, {required String idempotencyKey}) async {
    await _latency(700);
    _maybeFail(body);
    final cur = _require(id);
    if ('${body['answer'] ?? ''}'.contains('#409') || version < cur.version) {
      final theirs = cur.copyWith(
        version: cur.version + 1,
        updatedBy: const KbPerson(id: 'a2', name: 'خالد'),
        updatedAt: DateTime.now(),
      );
      _store.upsertQa(theirs);
      throw KbEditorApiException(409, code: 'version_conflict', current: theirs, updatedBy: 'خالد');
    }
    if (_history[id] == null) _snapshot(cur, 'النسخة الأصلية');
    final e = _fromBody(id, body, base: cur);
    _store.upsertQa(e);
    _snapshot(e, 'تعديل الإجابة');
    return KbSaveResult(e);
  }

  @override
  Future<KbQa> propose(Map<String, Object?> body, {required String idempotencyKey}) async {
    await _latency(600);
    _maybeFail(body);
    final e = _fromBody(_store.nextId('kb'), body, status: KbStatus.draft).copyWith(enabled: false);
    _store.drafts.insert(0, e);
    _resolveSource(body);
    return e;
  }

  @override
  Future<KbSaveResult> approveDraft(String id, Map<String, Object?> body) async {
    await _latency(600);
    _maybeFail(body);
    final i = _store.drafts.indexWhere((d) => d.id == id);
    if (i < 0) throw const KbEditorApiException(404, code: 'not_found');
    final draft = _store.drafts.removeAt(i);
    final e = _fromBody(id, {...body, 'enabled': body['enabled'] ?? true}, base: draft, status: KbStatus.active);
    _store.upsertQa(e);
    _snapshot(e, 'اعتماد المقترح');
    return KbSaveResult(e);
  }

  @override
  Future<void> rejectDraft(String id, {String? reason}) async {
    await _latency(400);
    _store.drafts.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> delete(String id) async {
    await _latency(400);
    _store.qa.removeWhere((e) => e.id == id);
    _store.drafts.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<KbTag>> tags() async {
    await _latency(250);
    final counts = <String, int>{};
    for (final e in _store.qa) {
      for (final t in e.tags) {
        counts[t.name] = (counts[t.name] ?? 0) + 1;
      }
    }
    for (final n in const ['السياسات', 'الشحن', 'الدفع', 'المنتجات', 'العروض']) {
      counts.putIfAbsent(n, () => 0);
    }
    return [for (final e in counts.entries) KbTag(id: e.key, name: e.key, count: e.value)];
  }

  @override
  Future<List<String>> suggestPhrasings(String question) async {
    await _latency(700);
    final q = question.trim().replaceAll(RegExp(r'[؟?]+$'), '');
    final k = PhrasingNormalizer.key(q);
    if (RegExp('استرجاع|ارجاع|ارجع|استبدال').hasMatch(k)) {
      return const ['أبي أرجّع الطلب', 'كم مدة الإرجاع؟', 'ممكن أرجّع بعد شهر؟'];
    }
    if (RegExp('توصيل|شحن|يوصل').hasMatch(k)) {
      return const ['متى يوصل طلبي؟', 'كم ياخذ الشحن؟', 'التوصيل كم يوم؟'];
    }
    if (RegExp('دفع|مدى|فيزا|تقسيط').hasMatch(k)) {
      return const ['وش طرق الدفع عندكم؟', 'أقدر أدفع بمدى؟', 'فيه دفع عند الاستلام؟'];
    }
    return ['ممكن تقولي $q؟', 'أبي أعرف $q', '$q لو سمحت؟'];
  }

  static Set<String> _tokens(String s) => {for (final w in PhrasingNormalizer.key(s).split(' ')) if (w.length > 2) w};

  static double _similarity(String a, String b) {
    final x = _tokens(a), y = _tokens(b);
    if (x.isEmpty || y.isEmpty) return 0;
    return x.intersection(y).length / x.union(y).length;
  }

  @override
  Future<KbDuplicateCheck> checkDuplicates({required String question, String? answer, String? excludeId}) async {
    await _latency(350);
    final similar = <KbSimilar>[];
    final conflicts = <KbConflict>[];
    for (final e in _store.qa) {
      if (e.id == excludeId) continue;
      final score = [e.question, ...e.altPhrasings].map((p) => _similarity(question, p)).fold<double>(0, math.max);
      if (score < 0.34) continue;
      similar.add(KbSimilar(id: e.id, title: e.question, score: score));
      final digits = RegExp(r'\d+');
      if (answer != null && digits.hasMatch(answer)) {
        final mine = digits.allMatches(answer).map((m) => m[0]).toSet();
        final theirs = digits.allMatches(e.answer).map((m) => m[0]).toSet();
        if (theirs.isNotEmpty && mine.intersection(theirs).isEmpty) {
          conflicts.add(KbConflict(id: e.id, title: e.question, reason: 'أرقام مختلفة عن الإجابة الحالية'));
        }
      }
    }
    similar.sort((a, b) => b.score.compareTo(a.score));
    return KbDuplicateCheck(similar: similar.take(1).toList(), conflicts: conflicts.take(1).toList());
  }

  @override
  Future<KbPreview> preview({
    required String question,
    required String answer,
    required List<String> altPhrasings,
    String? testQuestion,
    required bool verbatim,
  }) async {
    await _latency(900);
    if (answer.contains('#preview')) throw const KbEditorApiException(503, code: 'ai_unavailable');
    final test = testQuestion ??
        (altPhrasings.isEmpty
            ? 'ممكن أسأل: ${question.replaceAll(RegExp(r'[؟?]+$'), '')}؟'
            : altPhrasings.reduce((a, b) => _similarity(question, a) <= _similarity(question, b) ? a : b));
    final n = answer.trim().runes.length;
    final confidence = altPhrasings.length >= 2 && n >= 40
        ? KbConfidence.high
        : (altPhrasings.isNotEmpty || n >= 40 ? KbConfidence.medium : KbConfidence.low);
    return KbPreview(
      testQuestion: test,
      reply: verbatim ? answer.trim() : 'أهلًا بك! ${answer.trim()} هل تحتاج أي مساعدة أخرى؟',
      confidence: verbatim ? KbConfidence.high : confidence,
      tone: 'friendly',
    );
  }

  @override
  Future<List<KbVersion>> versions(String id) async {
    await _latency(400);
    final cur = _require(id);
    final h = _history[id];
    if (h == null || h.isEmpty) {
      return [KbVersion(version: cur.version, by: cur.updatedBy, at: cur.updatedAt ?? DateTime.now(), summary: 'النسخة الحالية')];
    }
    return [for (final (v, _) in h.reversed) v];
  }

  @override
  Future<KbQa> restoreVersion(String id, int version) async {
    await _latency(500);
    final cur = _require(id);
    final snap = _history[id]?.where((s) => s.$1.version == version).firstOrNull?.$2;
    if (snap == null) throw const KbEditorApiException(404, code: 'not_found');
    final e = snap.copyWith(version: cur.version + 1, updatedBy: _person, updatedAt: DateTime.now());
    _store.upsertQa(e);
    _snapshot(e, 'استعادة النسخة $version');
    return e;
  }
}
