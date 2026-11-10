import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../domain/kb_entry.dart';
import 'kb_api.dart' show KbPickedFile;

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

  /// 402 `plan_limit` (e.g. feature `kb_media` not on the plan).
  bool get isPlanLimit => status == 402 || code == 'plan_limit';

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

  /// [hintQuestion]/[hintAnswer] come from the chat screen; used when the
  /// server has no customer question before the message.
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

  /// Images / voice notes on an answer (web "المرفقات"). [onProgress] 0–1.
  Future<KbMedia> uploadMedia(
    String entryId,
    KbPickedFile file, {
    String? title,
    KbMediaSendMode sendMode = KbMediaSendMode.withText,
    void Function(double)? onProgress,
  });
  Future<KbMedia> updateMedia(String mediaId, {String? title, KbMediaSendMode? sendMode, bool? isActive});
  Future<void> deleteMedia(String mediaId);
}

final kbEditorApiProvider = Provider<KbEditorApi>((ref) {
  return HttpKbEditorApi(ref.watch(wdApiRequiredProvider));
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

  @override
  Future<KbMedia> uploadMedia(
    String entryId,
    KbPickedFile file, {
    String? title,
    KbMediaSendMode sendMode = KbMediaSendMode.withText,
    void Function(double)? onProgress,
  }) =>
      _guard(() async {
        // WdApi.upload sends the body in one go: report start + done.
        onProgress?.call(0.1);
        final r = await _api.upload(
          'kb/$entryId/media',
          bytes: file.bytes,
          filename: file.name,
          contentType: file.mime,
          fields: {if (title != null && title.trim().isNotEmpty) 'title': title.trim(), 'send_mode': sendMode.wire},
        );
        onProgress?.call(1);
        return KbMedia.fromJson(r.map);
      });

  @override
  Future<KbMedia> updateMedia(String mediaId, {String? title, KbMediaSendMode? sendMode, bool? isActive}) => _guard(() async {
        final r = await _api.patch('kb/media/$mediaId', body: {'title': ?title, 'send_mode': ?sendMode?.wire, 'is_active': ?isActive});
        return KbMedia.fromJson(r.map);
      });

  @override
  Future<void> deleteMedia(String mediaId) => _guard(() => _api.delete('kb/media/$mediaId'));
}

/// Voice notes: audio mime or a known audio extension.
bool kbIsAudio(KbPickedFile f) {
  if (f.mime.startsWith('audio/')) return true;
  final ext = f.name.split('.').last.toLowerCase();
  return const {'mp3', 'm4a', 'aac', 'ogg', 'oga', 'opus', 'wav', 'amr', 'webm'}.contains(ext);
}

/// Images: image mime or a known image extension.
bool kbIsImage(KbPickedFile f) {
  if (f.mime.startsWith('image/')) return true;
  final ext = f.name.split('.').last.toLowerCase();
  return const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'}.contains(ext);
}
