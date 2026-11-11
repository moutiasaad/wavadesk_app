import 'package:flutter/foundation.dart';

/// Knowledge base wire models (Knowledge Base spec §8, Add Answer spec §8).

enum KbType {
  qa,
  file,
  link;

  static KbType parse(Object? v) => values.asNameMap()['$v'] ?? qa;
}

enum KbStatus {
  active,
  disabled,
  draft,
  processing,
  failed;

  static KbStatus parse(Object? v) => values.asNameMap()['$v'] ?? active;
}

enum KbSort {
  usage('usage'),
  updatedDesc('updated_desc'),
  updatedAsc('updated_asc'),
  alpha('alpha'),
  usageAsc('usage_asc');

  const KbSort(this.wire);
  final String wire;
}

enum KbDraftSource {
  agent('agent'),
  aiFromConversation('ai_from_conversation');

  const KbDraftSource(this.wire);
  final String wire;

  static KbDraftSource? parse(Object? v) {
    for (final s in values) {
      if (s.wire == v) return s;
    }
    return null;
  }
}

DateTime? _date(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;
int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
List<String> _strings(Object? v) => v is List ? [for (final s in v) '$s'] : const [];
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};

@immutable
class KbTag {
  const KbTag({required this.id, required this.name, this.count = 0});

  factory KbTag.fromJson(Object? j) {
    if (j is String) return KbTag(id: j, name: j);
    final m = _map(j);
    return KbTag(id: '${m['id'] ?? m['name']}', name: '${m['name'] ?? m['id']}', count: _int(m['count']));
  }

  final String id;
  final String name;
  final int count;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is KbTag && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

@immutable
class KbPerson {
  const KbPerson({required this.id, required this.name, this.avatarUrl});

  static KbPerson? fromJson(Object? j) {
    if (j is! Map) return null;
    return KbPerson(id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}', avatarUrl: j['avatar_url'] as String?);
  }

  final String id;
  final String name;
  final String? avatarUrl;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'avatar_url': avatarUrl};
}

@immutable
class KbFileInfo {
  const KbFileInfo({required this.pages, required this.sizeBytes, required this.mime});

  factory KbFileInfo.fromJson(Map<String, dynamic> m) =>
      KbFileInfo(pages: _int(m['pages']), sizeBytes: _int(m['size_bytes']), mime: '${m['mime'] ?? ''}');

  final int pages;
  final int sizeBytes;
  final String mime;
}

@immutable
class KbLinkInfo {
  const KbLinkInfo({required this.domain, required this.pagesCount});

  factory KbLinkInfo.fromJson(Map<String, dynamic> m) => KbLinkInfo(domain: '${m['domain'] ?? ''}', pagesCount: _int(m['pages_count']));

  final String domain;
  final int pagesCount;
}

/// A list row (`KbEntrySummary`).
@immutable
class KbEntrySummary {
  const KbEntrySummary({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.usage30d,
    required this.updatedAt,
    this.isStale = false,
    this.file,
    this.link,
    this.tags = const [],
    this.draftedBy,
    this.draftSource,
    this.draftedAt,
    this.mediaCount = 0,
  });

  factory KbEntrySummary.fromJson(Map<String, dynamic> j) => KbEntrySummary(
        id: '${j['id']}',
        type: KbType.parse(j['type']),
        title: '${j['title'] ?? j['question'] ?? ''}',
        status: KbStatus.parse(j['status']),
        usage30d: _int(j['usage_30d']),
        updatedAt: _date(j['updated_at']) ?? DateTime.now(),
        isStale: j['is_stale'] == true,
        file: j['file'] is Map ? KbFileInfo.fromJson(_map(j['file'])) : null,
        link: j['link'] is Map ? KbLinkInfo.fromJson(_map(j['link'])) : null,
        tags: [for (final t in (j['tags'] as List? ?? const [])) KbTag.fromJson(t)],
        draftedBy: KbPerson.fromJson(j['drafted_by']),
        draftSource: KbDraftSource.parse(j['draft_source']),
        draftedAt: _date(j['drafted_at']),
        mediaCount: _int(j['media_count']),
      );

  final String id;
  final KbType type;
  final String title;
  final KbStatus status;
  final int usage30d;
  final DateTime updatedAt;
  final bool isStale;
  final KbFileInfo? file;
  final KbLinkInfo? link;
  final List<KbTag> tags;
  final KbPerson? draftedBy;
  final KbDraftSource? draftSource;
  final DateTime? draftedAt;

  /// Images / voice notes attached to a Q&A (`media_count`).
  final int mediaCount;

  bool get enabled => status != KbStatus.disabled;

  KbEntrySummary copyWith({String? title, KbStatus? status, DateTime? updatedAt, List<KbTag>? tags, KbFileInfo? file, KbLinkInfo? link, int? mediaCount}) =>
      KbEntrySummary(
        id: id,
        type: type,
        title: title ?? this.title,
        status: status ?? this.status,
        usage30d: usage30d,
        updatedAt: updatedAt ?? this.updatedAt,
        isStale: isStale,
        file: file ?? this.file,
        link: link ?? this.link,
        tags: tags ?? this.tags,
        draftedBy: draftedBy,
        draftSource: draftSource,
        draftedAt: draftedAt,
        mediaCount: mediaCount ?? this.mediaCount,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'status': status.name,
        'usage_30d': usage30d,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'is_stale': isStale,
        if (file != null) 'file': {'pages': file!.pages, 'size_bytes': file!.sizeBytes, 'mime': file!.mime},
        if (link != null) 'link': {'domain': link!.domain, 'pages_count': link!.pagesCount},
        'tags': [for (final t in tags) t.toJson()],
        'drafted_by': draftedBy?.toJson(),
        'draft_source': draftSource?.wire,
        'drafted_at': draftedAt?.toUtc().toIso8601String(),
        'media_count': mediaCount,
      };
}

@immutable
class KbPermissions {
  const KbPermissions({this.canEdit = false, this.canDelete = false, this.canReviewDrafts = false, this.canUploadMedia = false});

  factory KbPermissions.fromJson(Map<String, dynamic> m) => KbPermissions(
        canEdit: m['can_edit'] == true,
        canDelete: m['can_delete'] == true,
        canReviewDrafts: m['can_review_drafts'] == true,
        // Older servers don't send it: follow edit rights (402 explains a plan gap).
        canUploadMedia: m.containsKey('can_upload_media') ? m['can_upload_media'] == true : m['can_edit'] == true,
      );

  final bool canEdit;
  final bool canDelete;
  final bool canReviewDrafts;

  /// Images / voice notes on answers (paid plans, like the web form).
  final bool canUploadMedia;
}

@immutable
class KbCounts {
  const KbCounts({this.total = 0, this.qa = 0, this.file = 0, this.link = 0, this.processing = 0});

  factory KbCounts.fromJson(Map<String, dynamic> m) => KbCounts(
        total: _int(m['total']),
        qa: _int(m['qa']),
        file: _int(m['file']),
        link: _int(m['link']),
        processing: _int(m['processing']),
      );

  final int total;
  final int qa;
  final int file;
  final int link;
  final int processing;

  int of(KbType t) => switch (t) { KbType.qa => qa, KbType.file => file, KbType.link => link };
}

/// One page of `GET kb`.
@immutable
class KbListPage {
  const KbListPage({
    required this.items,
    this.nextCursor,
    this.counts = const KbCounts(),
    this.unansweredCount = 0,
    this.draftsPending = 0,
    this.permissions = const KbPermissions(),
  });

  final List<KbEntrySummary> items;
  final String? nextCursor;
  final KbCounts counts;
  final int unansweredCount;
  final int draftsPending;
  final KbPermissions permissions;
}

@immutable
class KbUsage {
  const KbUsage({this.month = 0, this.thumbsUpRate, this.lastUsedAt, this.daily = const []});

  factory KbUsage.fromJson(Map<String, dynamic> m) => KbUsage(
        month: _int(m['month']),
        thumbsUpRate: (m['thumbs_up_rate'] as num?)?.toDouble(),
        lastUsedAt: _date(m['last_used_at']),
        daily: [for (final v in (m['daily'] as List? ?? const [])) _int(v)],
      );

  final int month;

  /// 0–1, null when not tracked.
  final double? thumbsUpRate;
  final DateTime? lastUsedAt;

  /// 30 values, oldest first.
  final List<int> daily;
}

@immutable
class KbRecentUse {
  const KbRecentUse({required this.conversationId, this.messageId, required this.customerName, required this.question, required this.at});

  factory KbRecentUse.fromJson(Map<String, dynamic> m) => KbRecentUse(
        conversationId: '${m['conversation_id']}',
        messageId: m['message_id'] as String?,
        customerName: '${m['customer_name'] ?? ''}',
        question: '${m['question'] ?? ''}',
        at: _date(m['at']) ?? DateTime.now(),
      );

  final String conversationId;
  final String? messageId;
  final String customerName;
  final String question;
  final DateTime at;
}

/// Full Q&A (`GET kb/{id}`, also drafts).
@immutable
class KbQa {
  const KbQa({
    required this.id,
    required this.question,
    required this.answer,
    this.altPhrasings = const [],
    this.tags = const [],
    this.enabled = true,
    this.status = KbStatus.active,
    this.version = 1,
    this.channels,
    this.expiresAt,
    this.verbatim = false,
    this.handoffAfter = false,
    this.internalNotes,
    this.usage = const KbUsage(),
    this.recentUses = const [],
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.draftedBy,
    this.draftSource,
    this.media = const [],
  });

  factory KbQa.fromJson(Map<String, dynamic> j) => KbQa(
        id: '${j['id']}',
        question: '${j['question'] ?? j['title'] ?? ''}',
        answer: '${j['answer'] ?? ''}',
        altPhrasings: _strings(j['alt_phrasings']),
        tags: [for (final t in (j['tags'] as List? ?? const [])) KbTag.fromJson(t)],
        enabled: j['enabled'] ?? j['is_active'] ?? true,
        status: KbStatus.parse(j['status']),
        version: j['version'] == null ? 1 : _int(j['version']),
        channels: j['channels'] is List ? _strings(j['channels']) : null,
        expiresAt: _date(j['expires_at']),
        verbatim: j['verbatim'] == true,
        handoffAfter: j['handoff_after'] == true,
        internalNotes: j['internal_notes'] as String?,
        usage: KbUsage.fromJson(_map(j['usage'])),
        recentUses: [for (final r in (j['recent_uses'] as List? ?? const [])) KbRecentUse.fromJson(_map(r))],
        createdBy: KbPerson.fromJson(j['created_by']),
        updatedBy: KbPerson.fromJson(j['updated_by']),
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
        draftedBy: KbPerson.fromJson(j['drafted_by']),
        draftSource: KbDraftSource.parse(j['draft_source']),
        media: [
          for (final m in (j['media'] as List? ?? const []))
            if (m is Map) KbMedia.fromJson(Map<String, dynamic>.from(m)),
        ],
      );

  final String id;
  final String question;
  final String answer;
  final List<String> altPhrasings;
  final List<KbTag> tags;
  final bool enabled;
  final KbStatus status;
  final int version;

  /// null = all channels.
  final List<String>? channels;
  final DateTime? expiresAt;
  final bool verbatim;
  final bool handoffAfter;
  final String? internalNotes;
  final KbUsage usage;
  final List<KbRecentUse> recentUses;
  final KbPerson? createdBy;
  final KbPerson? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final KbPerson? draftedBy;
  final KbDraftSource? draftSource;

  /// Images / voice notes sent with the answer (web "المرفقات").
  final List<KbMedia> media;

  bool get isDraft => status == KbStatus.draft;

  KbQa copyWith({
    String? question,
    String? answer,
    List<String>? altPhrasings,
    List<KbTag>? tags,
    bool? enabled,
    KbStatus? status,
    int? version,
    List<String>? Function()? channels,
    DateTime? Function()? expiresAt,
    bool? verbatim,
    bool? handoffAfter,
    String? Function()? internalNotes,
    KbPerson? updatedBy,
    DateTime? updatedAt,
    List<KbMedia>? media,
  }) =>
      KbQa(
        id: id,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        altPhrasings: altPhrasings ?? this.altPhrasings,
        tags: tags ?? this.tags,
        enabled: enabled ?? this.enabled,
        status: status ?? this.status,
        version: version ?? this.version,
        channels: channels != null ? channels() : this.channels,
        expiresAt: expiresAt != null ? expiresAt() : this.expiresAt,
        verbatim: verbatim ?? this.verbatim,
        handoffAfter: handoffAfter ?? this.handoffAfter,
        internalNotes: internalNotes != null ? internalNotes() : this.internalNotes,
        usage: usage,
        recentUses: recentUses,
        createdBy: createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        draftedBy: draftedBy,
        draftSource: draftSource,
        media: media ?? this.media,
      );

  /// The write body of `POST kb` / `PATCH kb/{id}` (Add Answer spec §8).
  Map<String, Object?> toWriteJson() => {
        'question': question,
        'alt_phrasings': altPhrasings,
        'answer': answer,
        'tag_ids': [for (final t in tags) t.id],
        'enabled': enabled,
        'channels': channels,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'verbatim': verbatim,
        'handoff_after': handoffAfter,
        'internal_notes': internalNotes,
      };

  KbEntrySummary toSummary() => KbEntrySummary(
        id: id,
        type: KbType.qa,
        title: question,
        status: status == KbStatus.active && !enabled ? KbStatus.disabled : status,
        usage30d: usage.month,
        updatedAt: updatedAt ?? DateTime.now(),
        tags: tags,
        draftedBy: draftedBy,
        draftSource: draftSource,
        mediaCount: media.length,
      );
}

enum KbMediaKind {
  image,
  voice;

  static KbMediaKind parse(Object? v) => v == 'voice' ? voice : image;
}

/// How a media item goes out with the AI's reply (web `send_mode`).
enum KbMediaSendMode {
  /// Sent alongside the answer text.
  withText('with_text'),

  /// Sent on its own, without the text.
  fileOnly('file_only');

  const KbMediaSendMode(this.wire);
  final String wire;

  static KbMediaSendMode parse(Object? v) => v == 'file_only' ? fileOnly : withText;
}

/// An image or voice note attached to a Q&A (`POST kb/{id}/media`).
@immutable
class KbMedia {
  const KbMedia({
    required this.id,
    required this.kind,
    required this.title,
    this.url,
    this.mime = '',
    this.sizeBytes = 0,
    this.durationSeconds,
    this.sendMode = KbMediaSendMode.withText,
    this.isActive = true,
  });

  factory KbMedia.fromJson(Map<String, dynamic> j) => KbMedia(
        id: '${j['id']}',
        kind: KbMediaKind.parse(j['kind']),
        title: '${j['title'] ?? ''}',
        url: j['url'] as String?,
        mime: '${j['mime'] ?? ''}',
        sizeBytes: _int(j['size'] ?? j['size_bytes']),
        durationSeconds: j['duration'] == null ? null : _int(j['duration']),
        sendMode: KbMediaSendMode.parse(j['send_mode']),
        isActive: j['is_active'] != false,
      );

  final String id;
  final KbMediaKind kind;
  final String title;
  final String? url;
  final String mime;
  final int sizeBytes;
  final int? durationSeconds;
  final KbMediaSendMode sendMode;
  final bool isActive;

  KbMedia copyWith({String? title, KbMediaSendMode? sendMode, bool? isActive}) => KbMedia(
        id: id,
        kind: kind,
        title: title ?? this.title,
        url: url,
        mime: mime,
        sizeBytes: sizeBytes,
        durationSeconds: durationSeconds,
        sendMode: sendMode ?? this.sendMode,
        isActive: isActive ?? this.isActive,
      );
}

/// Result of `POST kb/import` (web JSON import).
@immutable
class KbImportResult {
  const KbImportResult({this.imported = 0, this.skipped = 0, this.errors = const []});

  factory KbImportResult.fromJson(Map<String, dynamic> j) => KbImportResult(
        imported: _int(j['imported']),
        skipped: _int(j['skipped']),
        errors: [
          for (final e in (j['errors'] as List? ?? const []))
            if (e is Map) (row: _int(e['row']), message: '${e['message'] ?? ''}'),
        ],
      );

  final int imported;
  final int skipped;
  final List<({int row, String message})> errors;
}

/// `GET kb/unanswered` row (grouped by similarity server-side).
@immutable
class KbUnanswered {
  const KbUnanswered({
    required this.id,
    required this.question,
    this.variants = const [],
    this.count = 1,
    required this.lastAskedAt,
    this.channels = const [],
    this.draftAnswer,
    this.conversationIds = const [],
  });

  factory KbUnanswered.fromJson(Map<String, dynamic> j) => KbUnanswered(
        id: '${j['id']}',
        question: '${j['question'] ?? ''}',
        variants: _strings(j['variants']),
        count: j['count'] == null ? 1 : _int(j['count']),
        lastAskedAt: _date(j['last_asked_at']) ?? DateTime.now(),
        channels: _strings(j['channels']),
        draftAnswer: j['draft_answer'] as String?,
        conversationIds: _strings(j['conversation_ids']),
      );

  final String id;
  final String question;
  final List<String> variants;
  final int count;
  final DateTime lastAskedAt;
  final List<String> channels;
  final String? draftAnswer;
  final List<String> conversationIds;
}

enum KbFileError {
  encrypted,
  imagesOnly,
  corrupt,

  /// The AI read the document but found nothing a customer would ask.
  noAnswers,

  /// The AI could not be reached; trying again later may work.
  aiUnavailable;

  static KbFileError? parse(Object? v) => switch (v) {
        'encrypted' => encrypted,
        'images_only' => imagesOnly,
        'corrupt' => corrupt,
        'no_answers' => noAnswers,
        'ai_unavailable' => aiUnavailable,
        _ => null,
      };
}

@immutable
class KbChunk {
  const KbChunk({required this.id, required this.title, required this.preview});

  factory KbChunk.fromJson(Map<String, dynamic> m) => KbChunk(id: '${m['id']}', title: '${m['title'] ?? ''}', preview: '${m['preview'] ?? ''}');

  final String id;
  final String title;
  final String preview;
}

/// `GET kb/files/{id}`.
@immutable
class KbFile {
  const KbFile({
    required this.id,
    required this.name,
    required this.sizeBytes,
    this.pages = 0,
    this.mime = '',
    this.status = KbStatus.processing,
    this.error,
    this.chunks = const [],
    this.enabled = true,
    this.downloadUrl,
    this.uploadedBy,
    this.uploadedAt,
    this.draftsCount = 0,
    this.canApprove = false,
  });

  factory KbFile.fromJson(Map<String, dynamic> j) => KbFile(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        sizeBytes: _int(j['size'] ?? j['size_bytes']),
        pages: _int(j['pages']),
        mime: '${j['mime'] ?? ''}',
        status: KbStatus.parse(j['status']),
        error: KbFileError.parse(j['error_code']),
        chunks: [for (final c in (j['chunks'] as List? ?? const [])) KbChunk.fromJson(_map(c))],
        enabled: j['enabled'] != false,
        downloadUrl: j['download_url'] as String?,
        uploadedBy: KbPerson.fromJson(j['uploaded_by']),
        uploadedAt: _date(j['uploaded_at'] ?? j['created_at']),
        draftsCount: _int(j['drafts_count']),
        canApprove: j['can_approve'] == true,
      );

  final String id;
  final String name;
  final int sizeBytes;
  final int pages;
  final String mime;
  final KbStatus status;
  final KbFileError? error;
  final List<KbChunk> chunks;
  final bool enabled;
  final String? downloadUrl;
  final KbPerson? uploadedBy;
  final DateTime? uploadedAt;

  /// Answers the AI drafted from this document (all of them; [chunks] are
  /// the ones still waiting for review).
  final int draftsCount;

  /// The viewer may publish drafts (admins); others' drafts wait for one.
  final bool canApprove;
}

enum KbRefresh {
  weekly,
  monthly,
  manual;

  static KbRefresh parse(Object? v) => values.asNameMap()['$v'] ?? manual;
}

@immutable
class KbLinkPage {
  const KbLinkPage({required this.id, required this.title, required this.path, this.enabled = true});

  factory KbLinkPage.fromJson(Map<String, dynamic> m) =>
      KbLinkPage(id: '${m['id']}', title: '${m['title'] ?? ''}', path: '${m['path'] ?? ''}', enabled: m['enabled'] != false);

  final String id;
  final String title;
  final String path;
  final bool enabled;

  KbLinkPage copyWith({bool? enabled}) => KbLinkPage(id: id, title: title, path: path, enabled: enabled ?? this.enabled);
}

/// `GET kb/links/{id}`.
@immutable
class KbLink {
  const KbLink({
    required this.id,
    required this.url,
    required this.title,
    this.lastCrawledAt,
    this.refresh = KbRefresh.manual,
    this.pages = const [],
    this.status = KbStatus.active,
    this.enabled = true,
  });

  factory KbLink.fromJson(Map<String, dynamic> j) => KbLink(
        id: '${j['id']}',
        url: '${j['url'] ?? ''}',
        title: '${j['title'] ?? ''}',
        lastCrawledAt: _date(j['last_crawled_at']),
        refresh: KbRefresh.parse(j['refresh']),
        pages: [for (final p in (j['pages'] as List? ?? const [])) KbLinkPage.fromJson(_map(p))],
        status: KbStatus.parse(j['status']),
        enabled: j['enabled'] != false,
      );

  final String id;
  final String url;
  final String title;
  final DateTime? lastCrawledAt;
  final KbRefresh refresh;
  final List<KbLinkPage> pages;
  final KbStatus status;
  final bool enabled;

  String get domain => Uri.tryParse(url)?.host ?? url;

  KbLink copyWith({KbRefresh? refresh, List<KbLinkPage>? pages, DateTime? lastCrawledAt, KbStatus? status, bool? enabled}) => KbLink(
        id: id,
        url: url,
        title: title,
        lastCrawledAt: lastCrawledAt ?? this.lastCrawledAt,
        refresh: refresh ?? this.refresh,
        pages: pages ?? this.pages,
        status: status ?? this.status,
        enabled: enabled ?? this.enabled,
      );
}
