import 'dart:async';
import 'dart:convert';

import '../../../core/api/wd_api.dart';
import '../domain/kb_entry.dart';

class KbApiException implements Exception {
  const KbApiException(this.status, {this.code, this.message});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;

  bool get isNetwork => status == 0;

  /// Files / links are not on the server yet (501 `not_supported`).
  bool get isNotSupported => status == 501 || code == 'not_supported';
  bool get isNotFound => status == 404;
  bool get isPlanLimit => status == 402 || code == 'plan_limit';

  @override
  String toString() => 'KbApiException($status $code)';
}

/// A file picked for upload (Knowledge Base spec §6.2).
class KbPickedFile {
  const KbPickedFile({required this.name, required this.sizeBytes, required this.mime, this.bytes = const []});

  final String name;
  final int sizeBytes;
  final String mime;
  final List<int> bytes;
}

/// Knowledge Base spec §8 (list, detail toggles, unanswered, files, links).
/// The Add Answer editor has its own client (`kb_editor_api.dart`).
abstract interface class KbApi {
  Future<KbListPage> list({KbType? type, Set<String> tags = const {}, KbSort sort = KbSort.usage, String? cursor, int limit = 30});
  Future<List<KbEntrySummary>> drafts();
  Future<List<KbTag>> tags();
  Future<KbQa> fetchQa(String id);
  Future<void> setEnabled(String id, bool enabled);
  Future<void> delete(String id);
  Future<KbQa> approveDraft(String id);
  Future<void> rejectDraft(String id, {String? reason});

  /// (rows, nextCursor, total)
  Future<(List<KbUnanswered>, String?, int)> unanswered({String sort = 'frequency', String? cursor});
  Future<void> dismissUnanswered(String id);
  Future<KbQa> linkUnanswered(String id, String kbId);

  /// Returns the new entry id; [onProgress] gets 0–1.
  Future<String> uploadFile(KbPickedFile file, {void Function(double)? onProgress, String? replaceId});
  Future<KbFile> file(String id);

  Future<String?> linkPreviewTitle(String url);
  Future<String> addLink(String url, {required bool includeSubpages});
  Future<KbLink> link(String id);
  Future<KbLink> recrawl(String id);
  Future<KbLink> patchLink(String id, {KbRefresh? refresh, List<KbLinkPage>? pages});

  /// Web "استيراد JSON": many entries from one `.json` file.
  Future<KbImportResult> importJson(KbPickedFile file);

  /// The import template, pretty-printed JSON text.
  Future<String> importTemplate();
}

class HttpKbApi implements KbApi {
  HttpKbApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw KbApiException(e.status, code: e.code, message: e.message);
    }
  }

  @override
  Future<KbListPage> list({KbType? type, Set<String> tags = const {}, KbSort sort = KbSort.usage, String? cursor, int limit = 30}) =>
      _guard(() async {
        final r = await _api.get('kb', query: {
          'type': type?.name,
          if (tags.isNotEmpty) 'tags': tags.join(','),
          'sort': sort.wire,
          'cursor': cursor,
          'limit': limit,
        });
        final m = r.meta;
        return KbListPage(
          items: [for (final j in r.list) KbEntrySummary.fromJson(j)],
          nextCursor: r.nextCursor,
          counts: KbCounts.fromJson(m['counts'] is Map ? Map<String, dynamic>.from(m['counts'] as Map) : const {}),
          unansweredCount: (m['unanswered_count'] as num?)?.toInt() ?? 0,
          draftsPending: (m['drafts_pending'] as num?)?.toInt() ?? 0,
          permissions: KbPermissions.fromJson(m['permissions'] is Map ? Map<String, dynamic>.from(m['permissions'] as Map) : const {}),
        );
      });

  @override
  Future<List<KbEntrySummary>> drafts() => _guard(() async => [for (final j in (await _api.get('kb/drafts')).list) KbEntrySummary.fromJson(j)]);

  @override
  Future<List<KbTag>> tags() => _guard(() async {
        final r = await _api.get('kb/tags');
        return [for (final t in (r.data as List? ?? const [])) KbTag.fromJson(t)];
      });

  @override
  Future<KbQa> fetchQa(String id) => _guard(() async => KbQa.fromJson((await _api.get('kb/$id')).map));

  @override
  Future<void> setEnabled(String id, bool enabled) => _guard(() => _api.patch('kb/$id', body: {'enabled': enabled}));

  @override
  Future<void> delete(String id) => _guard(() => _api.delete('kb/$id'));

  @override
  Future<KbQa> approveDraft(String id) =>
      _guard(() async => KbQa.fromJson((await _api.post('kb/drafts/$id/approve', body: const <String, Object?>{})).map));

  @override
  Future<void> rejectDraft(String id, {String? reason}) => _guard(() => _api.post('kb/drafts/$id/reject', body: {'reason': ?reason}));

  @override
  Future<(List<KbUnanswered>, String?, int)> unanswered({String sort = 'frequency', String? cursor}) => _guard(() async {
        final r = await _api.get('kb/unanswered', query: {'sort': sort, 'cursor': cursor});
        final rows = [for (final j in r.list) KbUnanswered.fromJson(j)];
        return (rows, r.nextCursor, (r.meta['total'] as num?)?.toInt() ?? rows.length);
      });

  @override
  Future<void> dismissUnanswered(String id) => _guard(() => _api.post('kb/unanswered/$id/dismiss', body: const <String, Object?>{}));

  @override
  Future<KbQa> linkUnanswered(String id, String kbId) =>
      _guard(() async => KbQa.fromJson((await _api.post('kb/unanswered/$id/link', body: {'kb_id': kbId})).map));

  @override
  Future<String> uploadFile(KbPickedFile file, {void Function(double)? onProgress, String? replaceId}) => _guard(() async {
        onProgress?.call(0.05);
        final r = await _api.upload(
          replaceId == null ? 'kb/files' : 'kb/files/$replaceId',
          bytes: file.bytes,
          filename: file.name,
          contentType: file.mime,
        );
        onProgress?.call(1);
        return '${r.map['id']}';
      });

  @override
  Future<KbFile> file(String id) => _guard(() async => KbFile.fromJson((await _api.get('kb/files/$id')).map));

  @override
  Future<String?> linkPreviewTitle(String url) => _guard(() async {
        final t = (await _api.get('kb/links/preview', query: {'url': url})).map['title'];
        return t is String && t.isNotEmpty ? t : null;
      });

  @override
  Future<String> addLink(String url, {required bool includeSubpages}) =>
      _guard(() async => '${(await _api.post('kb/links', body: {'url': url, 'include_subpages': includeSubpages})).map['id']}');

  @override
  Future<KbLink> link(String id) => _guard(() async => KbLink.fromJson((await _api.get('kb/links/$id')).map));

  @override
  Future<KbLink> recrawl(String id) => _guard(() async {
        await _api.post('kb/links/$id/recrawl', body: const <String, Object?>{});
        return link(id);
      });

  @override
  Future<KbImportResult> importJson(KbPickedFile file) => _guard(() async {
        final r = await _api.upload('kb/import', bytes: file.bytes, filename: file.name, contentType: 'application/json');
        return KbImportResult.fromJson(r.map);
      });

  @override
  Future<String> importTemplate() => _guard(() async {
        final r = await _api.get('kb/import/template');
        return const JsonEncoder.withIndent('  ').convert(r.data);
      });

  @override
  Future<KbLink> patchLink(String id, {KbRefresh? refresh, List<KbLinkPage>? pages}) => _guard(() async {
        final r = await _api.patch('kb/links/$id', body: {
          'refresh': ?refresh?.name,
          if (pages != null) 'pages': [for (final p in pages) {'id': p.id, 'enabled': p.enabled}],
        });
        return r.map.isEmpty ? link(id) : KbLink.fromJson(r.map);
      });
}
