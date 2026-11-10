import 'dart:async';
import 'dart:math' as math;

import '../../../core/api/wd_api.dart';
import '../domain/kb_entry.dart';
import '../domain/stale_rule.dart';
import 'kb_sample_store.dart';

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
  Future<KbLink> patchLink(String id, {KbRefresh? refresh, List<KbLinkPage>? pages}) => _guard(() async {
        final r = await _api.patch('kb/links/$id', body: {
          'refresh': ?refresh?.name,
          if (pages != null) 'pages': [for (final p in pages) {'id': p.id, 'enabled': p.enabled}],
        });
        return r.map.isEmpty ? link(id) : KbLink.fromJson(r.map);
      });
}

/// Offline sample backend on [KbSampleStore] with simulated latency.
class SampleKbApi implements KbApi {
  SampleKbApi({required this.isAdmin});

  final bool isAdmin;
  final _s = KbSampleStore.instance;

  /// File id → finishes processing at.
  static final _processingUntil = <String, DateTime>{};
  static final _filePages = <String, int>{};
  static final _links = <String, KbLink>{};

  static Future<void> _wait([int ms = 350]) => Future<void>.delayed(Duration(milliseconds: ms));

  KbEntrySummary _summaryOf(KbQa q) => q.toSummary();

  void _settleProcessing() {
    final now = DateTime.now();
    for (var i = 0; i < _s.files.length; i++) {
      final f = _s.files[i];
      final until = _processingUntil[f.id];
      if (f.status == KbStatus.processing && until != null && now.isAfter(until)) {
        // Names containing "تالف" / "corrupt" fail, to demo the error card.
        final failed = f.title.contains('تالف') || f.title.toLowerCase().contains('corrupt');
        _s.files[i] = f.copyWith(
          status: failed ? KbStatus.failed : KbStatus.active,
          file: KbFileInfo(pages: _filePages[f.id] ?? 6, sizeBytes: f.file?.sizeBytes ?? 0, mime: f.file?.mime ?? ''),
        );
      }
    }
  }

  @override
  Future<KbListPage> list({KbType? type, Set<String> tags = const {}, KbSort sort = KbSort.usage, String? cursor, int limit = 30}) async {
    await _wait();
    _settleProcessing();
    var all = <KbEntrySummary>[for (final q in _s.qa) _summaryOf(q), ..._s.files, ..._s.links];
    final counts = KbCounts(
      total: all.length,
      qa: _s.qa.length,
      file: _s.files.length,
      link: _s.links.length,
      processing: all.where((e) => e.status == KbStatus.processing).length,
    );
    if (type != null) all = all.where((e) => e.type == type).toList();
    if (tags.isNotEmpty) all = all.where((e) => e.tags.any((t) => tags.contains(t.id))).toList();
    int byUsage(KbEntrySummary a, KbEntrySummary b) => b.usage30d.compareTo(a.usage30d);
    switch (sort) {
      case KbSort.usage:
        all.sort(byUsage);
      case KbSort.usageAsc:
        all.sort((a, b) => -byUsage(a, b));
      case KbSort.updatedDesc:
        all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case KbSort.updatedAsc:
        all.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case KbSort.alpha:
        all.sort((a, b) => a.title.compareTo(b.title));
    }
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = math.min(start + limit, all.length);
    return KbListPage(
      items: [
        for (final e in all.sublist(math.min(start, all.length), end))
          KbEntrySummary(
            id: e.id,
            type: e.type,
            title: e.title,
            status: e.status,
            usage30d: e.usage30d,
            updatedAt: e.updatedAt,
            isStale: StaleRule.isStale(e.updatedAt),
            file: e.file,
            link: e.link,
            tags: e.tags,
          ),
      ],
      nextCursor: end < all.length ? '$end' : null,
      counts: counts,
      unansweredCount: _s.unanswered.length,
      draftsPending: isAdmin ? _s.drafts.length : 0,
      permissions: KbPermissions(canEdit: isAdmin, canDelete: isAdmin, canReviewDrafts: isAdmin),
    );
  }

  @override
  Future<List<KbEntrySummary>> drafts() async {
    await _wait(250);
    return isAdmin ? [for (final d in _s.drafts) _summaryOf(d)] : const [];
  }

  @override
  Future<List<KbTag>> tags() async {
    await _wait(150);
    final counts = <String, int>{};
    for (final q in _s.qa) {
      for (final t in q.tags) {
        counts[t.id] = (counts[t.id] ?? 0) + 1;
      }
    }
    return [for (final e in counts.entries) KbTag(id: e.key, name: e.key, count: e.value)];
  }

  @override
  Future<KbQa> fetchQa(String id) async {
    await _wait();
    final q = _s.qaById(id);
    if (q == null) throw const KbApiException(404, code: 'not_found');
    return q;
  }

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    await _wait(250);
    final q = _s.qaById(id);
    if (q != null) {
      _s.upsertQa(q.copyWith(enabled: enabled, status: enabled ? KbStatus.active : KbStatus.disabled, version: q.version + 1));
      return;
    }
    for (final list in [_s.files, _s.links]) {
      final i = list.indexWhere((e) => e.id == id);
      if (i >= 0) list[i] = list[i].copyWith(status: enabled ? KbStatus.active : KbStatus.disabled);
    }
  }

  @override
  Future<void> delete(String id) async {
    await _wait(250);
    _s.qa.removeWhere((e) => e.id == id);
    _s.drafts.removeWhere((e) => e.id == id);
    _s.files.removeWhere((e) => e.id == id);
    _s.links.removeWhere((e) => e.id == id);
  }

  @override
  Future<KbQa> approveDraft(String id) async {
    await _wait();
    final d = _s.drafts.firstWhere((e) => e.id == id, orElse: () => throw const KbApiException(404, code: 'not_found'));
    _s.drafts.remove(d);
    final live = d.copyWith(status: KbStatus.active, enabled: true, updatedAt: DateTime.now());
    _s.upsertQa(live);
    return live;
  }

  @override
  Future<void> rejectDraft(String id, {String? reason}) async {
    await _wait(250);
    _s.drafts.removeWhere((e) => e.id == id);
  }

  @override
  Future<(List<KbUnanswered>, String?, int)> unanswered({String sort = 'frequency', String? cursor}) async {
    await _wait();
    final rows = [..._s.unanswered];
    sort == 'recent' ? rows.sort((a, b) => b.lastAskedAt.compareTo(a.lastAskedAt)) : rows.sort((a, b) => b.count.compareTo(a.count));
    return (rows, null, rows.length);
  }

  @override
  Future<void> dismissUnanswered(String id) async {
    await _wait(200);
    _s.unanswered.removeWhere((u) => u.id == id);
  }

  @override
  Future<KbQa> linkUnanswered(String id, String kbId) async {
    await _wait();
    final u = _s.unansweredById(id);
    final q = _s.qaById(kbId);
    if (u == null || q == null) throw const KbApiException(404, code: 'not_found');
    final alts = [...q.altPhrasings];
    for (final v in [u.question, ...u.variants]) {
      if (!alts.contains(v) && v != q.question) alts.add(v);
    }
    final next = q.copyWith(altPhrasings: alts, version: q.version + 1, updatedAt: DateTime.now());
    _s.upsertQa(next);
    _s.unanswered.removeWhere((x) => x.id == id);
    return next;
  }

  @override
  Future<String> uploadFile(KbPickedFile file, {void Function(double)? onProgress, String? replaceId}) async {
    for (var p = 0; p <= 10; p++) {
      await _wait(120);
      onProgress?.call(p / 10);
    }
    final id = replaceId ?? _s.nextId('kb_f');
    final row = KbEntrySummary(
      id: id,
      type: KbType.file,
      title: file.name,
      status: KbStatus.processing,
      usage30d: 0,
      updatedAt: DateTime.now(),
      file: KbFileInfo(pages: 0, sizeBytes: file.sizeBytes, mime: file.mime),
    );
    final i = _s.files.indexWhere((e) => e.id == id);
    i < 0 ? _s.files.insert(0, row) : _s.files[i] = row;
    _processingUntil[id] = DateTime.now().add(const Duration(seconds: 5));
    _filePages[id] = 3 + file.name.length % 9;
    return id;
  }

  @override
  Future<KbFile> file(String id) async {
    await _wait();
    _settleProcessing();
    final f = _s.files.firstWhere((e) => e.id == id, orElse: () => throw const KbApiException(404, code: 'not_found'));
    final ready = f.status == KbStatus.active || f.status == KbStatus.disabled;
    return KbFile(
      id: f.id,
      name: f.title,
      sizeBytes: f.file?.sizeBytes ?? 0,
      pages: f.file?.pages ?? 0,
      mime: f.file?.mime ?? '',
      status: f.status,
      error: f.status == KbStatus.failed ? KbFileError.corrupt : null,
      enabled: f.status != KbStatus.disabled,
      uploadedBy: const KbPerson(id: 'a1', name: 'نورة'),
      uploadedAt: f.updatedAt,
      chunks: ready
          ? const [
              KbChunk(id: 'ch1', title: 'مدة الاسترجاع', preview: 'يحق للعميل استرجاع المنتج خلال 30 يومًا من تاريخ الاستلام بشرط أن يكون بحالته الأصلية مع الفاتورة.'),
              KbChunk(id: 'ch2', title: 'المنتجات المستثناة', preview: 'لا يمكن استرجاع الملابس الداخلية ومنتجات العناية الشخصية بعد فتح العبوة لأسباب صحية.'),
              KbChunk(id: 'ch3', title: 'طريقة الاسترداد', preview: 'يُعاد المبلغ إلى وسيلة الدفع الأصلية خلال 5–10 أيام عمل من استلام المنتج في المستودع.'),
              KbChunk(id: 'ch4', title: 'الاستبدال', preview: 'يمكن استبدال المقاس أو اللون مجانًا مرة واحدة لكل طلب خلال 14 يومًا.'),
            ]
          : const [],
    );
  }

  @override
  Future<String?> linkPreviewTitle(String url) async {
    await _wait(500);
    final host = Uri.tryParse(url)?.host ?? '';
    return host.isEmpty ? null : 'الصفحة الرئيسية — $host';
  }

  @override
  Future<String> addLink(String url, {required bool includeSubpages}) async {
    await _wait(600);
    final id = _s.nextId('kb_l');
    final uri = Uri.parse(url);
    final pages = includeSubpages ? 1 + url.length % 7 : 1;
    _s.links.insert(
      0,
      KbEntrySummary(
        id: id,
        type: KbType.link,
        title: uri.host,
        status: KbStatus.processing,
        usage30d: 0,
        updatedAt: DateTime.now(),
        link: KbLinkInfo(domain: uri.host, pagesCount: pages),
      ),
    );
    _processingUntil[id] = DateTime.now().add(const Duration(seconds: 4));
    _links[id] = KbLink(
      id: id,
      url: url,
      title: uri.host,
      refresh: KbRefresh.weekly,
      pages: [
        for (var i = 0; i < pages; i++)
          KbLinkPage(id: 'p$i', title: i == 0 ? 'الصفحة الرئيسية' : 'صفحة ${i + 1}', path: i == 0 ? '/' : '/page-${i + 1}'),
      ],
    );
    return id;
  }

  void _settleLinks() {
    final now = DateTime.now();
    for (var i = 0; i < _s.links.length; i++) {
      final l = _s.links[i];
      final until = _processingUntil[l.id];
      if (l.status == KbStatus.processing && until != null && now.isAfter(until)) {
        _s.links[i] = l.copyWith(status: KbStatus.active, updatedAt: now);
        final d = _links[l.id];
        if (d != null) _links[l.id] = d.copyWith(lastCrawledAt: now, status: KbStatus.active);
      }
    }
  }

  @override
  Future<KbLink> link(String id) async {
    await _wait();
    _settleLinks();
    final row = _s.links.firstWhere((e) => e.id == id, orElse: () => throw const KbApiException(404, code: 'not_found'));
    return _links[id] ??= KbLink(
      id: id,
      url: 'https://${row.link?.domain ?? 'example.com'}/faq',
      title: row.title,
      lastCrawledAt: row.updatedAt,
      refresh: KbRefresh.weekly,
      status: row.status,
      pages: const [
        KbLinkPage(id: 'p1', title: 'الأسئلة الشائعة', path: '/faq'),
        KbLinkPage(id: 'p2', title: 'الشحن والتوصيل', path: '/faq/shipping'),
        KbLinkPage(id: 'p3', title: 'الاسترجاع', path: '/faq/returns'),
        KbLinkPage(id: 'p4', title: 'طرق الدفع', path: '/faq/payment'),
        KbLinkPage(id: 'p5', title: 'الضمان', path: '/faq/warranty', enabled: false),
      ],
    );
  }

  @override
  Future<KbLink> recrawl(String id) async {
    await _wait(700);
    final l = await link(id);
    return _links[id] = l.copyWith(lastCrawledAt: DateTime.now());
  }

  @override
  Future<KbLink> patchLink(String id, {KbRefresh? refresh, List<KbLinkPage>? pages}) async {
    await _wait(200);
    final l = await link(id);
    return _links[id] = l.copyWith(refresh: refresh, pages: pages);
  }
}
