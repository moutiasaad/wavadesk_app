import 'dart:async';

import '../../../core/api/wd_api.dart';
import '../../../core/models/models.dart';
import '../domain/conversation_filters.dart';
import '../domain/conversation_summary.dart';

class ConversationsPage {
  const ConversationsPage({required this.items, required this.nextCursor, required this.counts});

  final List<ConversationSummary> items;
  final String? nextCursor;

  /// `{ "mine": 5, "unassigned": 3, "all": 12, "unread": 4, "mine_unread": 2 }`
  final Map<String, int> counts;
}

class ConversationsApiException implements Exception {
  const ConversationsApiException(this.statusCode, {this.code, this.claimedBy, this.message});

  /// 0 = transport failure (offline / timeout).
  final int statusCode;
  final String? code;

  /// 409 on claim: who already holds it.
  final String? claimedBy;

  /// Localised server message (show as-is).
  final String? message;

  bool get isNetwork => statusCode == 0;
}

/// Inbox calls on the Laravel mobile API (`/mobile/v1/conversations*`).
///
/// The server contract differs from the original Inbox spec §6 draft; this
/// class is the only place that knows both:
/// - segments are `all|mine|unassigned|team|snoozed|resolved`; the app's
///   snoozed / closed chips become the `snoozed` / `resolved` segment plus an
///   `assignee` filter for "mine" / "unassigned";
/// - rows carry a plain `preview` string instead of a `last_message` object;
/// - statuses are `unassigned|assigned|resolved`, priority `normal` ↔ app `medium`;
/// - channels `whatsapp`/`wacloud` → WhatsApp, `webchat` → web.
class ConversationsApi {
  ConversationsApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      final who = e.details['assignee'];
      throw ConversationsApiException(
        e.status,
        code: e.code,
        message: e.message,
        claimedBy: who is Map ? who['name'] as String? : null,
      );
    }
  }

  // ---- query mapping --------------------------------------------------------

  static const _priorityOut = {
    Priority.urgent: 'urgent',
    Priority.high: 'high',
    Priority.medium: 'normal',
    Priority.low: 'low',
  };

  static Map<String, Object?> _query(InboxQuery q) {
    final a = q.advanced;
    final ownership = switch (q.segment) {
      InboxSegment.mine => 'me',
      InboxSegment.unassigned => 'none',
      InboxSegment.all => null,
    };
    final segment = switch (q.chip) {
      QuickChip.snoozed => 'snoozed',
      QuickChip.closed => 'resolved',
      _ => q.segment.name,
    };
    // The snoozed / resolved segments are not split by owner on the server.
    final segmentOwner = (q.chip == QuickChip.snoozed || q.chip == QuickChip.closed) ? ownership : null;

    String? assignee = segmentOwner;
    if (q.segment == InboxSegment.all) {
      switch (a.assignee) {
        case AssigneeFilter.me:
          assignee = 'me';
        case AssigneeFilter.unassigned:
          assignee = 'none';
        case AssigneeFilter.colleague:
          if (a.colleagueId != null && a.colleagueId!.startsWith('usr_')) assignee = a.colleagueId;
        case AssigneeFilter.ai || AssigneeFilter.all:
          break;
      }
    }

    final channels = <String>{
      for (final c in a.channels)
        ...switch (c) {
          Channel.whatsapp => ['whatsapp', 'wacloud'],
          Channel.web => ['webchat'],
          Channel.messenger => ['messenger'],
          _ => const <String>[],
        },
    };
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final date = switch (a.date) {
      DateRangeFilter.today => 'today',
      DateRangeFilter.last7 => '7d',
      DateRangeFilter.last30 => '30d',
      DateRangeFilter.custom => a.from == null ? null : 'custom',
      DateRangeFilter.any => null,
    };

    return {
      'segment': segment,
      if (channels.isNotEmpty) 'channels': channels.join(','),
      if (a.priorities.isNotEmpty) 'priority': a.priorities.map((p) => _priorityOut[p]).join(','),
      // Only server ids (team_…); sample-data team ids are not sent.
      if (a.teamIds.any((t) => t.startsWith('team_')))
        'team_ids': a.teamIds.where((t) => t.startsWith('team_')).join(','),
      if (a.tags.isNotEmpty) 'tags': a.tags.join(','),
      'date': ?date,
      if (date == 'custom') 'date_from': day(a.from!),
      if (date == 'custom' && a.to != null) 'date_to': day(a.to!),
      'assignee': ?assignee,
      if (q.chip == QuickChip.unread) 'unread': 'true',
      if (q.chip == QuickChip.ai ||
          (q.segment == InboxSegment.all && a.assignee == AssigneeFilter.ai) ||
          a.ai == AiFilter.handled)
        'ai': 'true'
      else if (a.ai == AiFilter.untouched)
        'ai': 'false',
      if (a.ai == AiFilter.escalated) 'escalated': 'true',
      'sort': switch (a.sort) {
        InboxSort.oldest || InboxSort.waiting => 'oldest',
        InboxSort.priority => 'priority',
        InboxSort.smart || InboxSort.newest => 'recent',
      },
    };
  }

  // ---- row mapping ------------------------------------------------------------

  static Channel _channel(Object? raw) => switch (raw) {
        'whatsapp' || 'wacloud' => Channel.whatsapp,
        'messenger' => Channel.messenger,
        'webchat' => Channel.web,
        'instagram' => Channel.instagram,
        'email' => Channel.email,
        _ => Channel.other,
      };

  static Priority? _priority(Object? raw) => switch (raw) {
        'urgent' => Priority.urgent,
        'high' => Priority.high,
        'low' => Priority.low,
        _ => null, // `normal` (the default) shows no badge
      };

  static DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

  /// Server row (`ConversationPresenter::summary`) → app row.
  static ConversationSummary fromServer(Map<String, dynamic> j) {
    final contact = Map<String, dynamic>.from(j['contact'] as Map? ?? const {});
    final assignee = j['assignee'] is Map ? Map<String, dynamic>.from(j['assignee'] as Map) : null;
    final team = j['team'] is Map ? Map<String, dynamic>.from(j['team'] as Map) : null;
    final snoozed = _date(j['snoozed_until']);
    final activity = _date(j['last_activity_at']) ?? DateTime.now();
    final aiHandling = j['ai_handling'] == true;
    final status = switch (j['status']) {
      'assigned' => ConversationStatus.open,
      'resolved' => ConversationStatus.resolved,
      'closed' => ConversationStatus.closed,
      _ when snoozed != null && snoozed.isAfter(DateTime.now()) => ConversationStatus.snoozed,
      _ when aiHandling => ConversationStatus.ai,
      _ => ConversationStatus.pending,
    };
    final preview = j['preview'] as String?;
    final unread = (j['unread_count'] as num?)?.toInt() ?? 0;
    final markedUnread = j['marked_unread'] == true;
    final isClosed = status == ConversationStatus.resolved || status == ConversationStatus.closed;

    return ConversationSummary(
      id: '${j['id']}',
      channel: _channel(j['channel']),
      contact: ContactRef(
        // Web-chat visitors have no contact record (`id: null`, `virtual: true`).
        id: contact['id'] == null ? '' : '${contact['id']}',
        name: (contact['name'] as String?) ?? '',
        avatarUrl: contact['avatar_url'] as String?,
        phone: contact['phone'] as String?,
        email: contact['email'] as String?,
      ),
      status: status,
      priority: _priority(j['priority']),
      assignee: assignee == null
          ? null
          : AssigneeRef(
              id: '${assignee['id']}',
              name: (assignee['name'] as String?) ?? '',
              avatarUrl: assignee['avatar_url'] as String?,
            ),
      handledByAi: aiHandling && assignee == null,
      // The list API has no last-message object: show the preview text as an
      // inbound text line, stamped with the last activity.
      lastMessage: preview == null || preview.isEmpty
          ? null
          : LastMessage(
              id: '${j['id']}:last',
              direction: MessageDirection.incoming,
              senderType: SenderType.contact,
              type: LastMessageType.text,
              text: preview,
              createdAt: activity,
            ),
      unreadCount: unread > 0 ? unread : (markedUnread ? 1 : 0),
      // Unassigned + unread ≈ a customer waiting for a human.
      waitingSince: !isClosed && assignee == null && !aiHandling && unread > 0 ? activity : null,
      snoozedUntil: snoozed,
      lastActivityAt: activity,
      tags: [for (final t in (j['tags'] as List? ?? const [])) '$t'],
      teamIds: [if (team != null) '${team['id']}'],
      closedAt: isClosed ? _date(j['closed_at']) ?? activity : null,
      escalated: j['escalated'] == true,
    );
  }

  // ---- calls ------------------------------------------------------------------

  /// Server segments a query is merged from, or null for a single list.
  /// - "الكل" pill = every conversation: the server's `all` segment is
  ///   open-only and it has no every-status list, so open + snoozed +
  ///   resolved are merged by activity ([_MergedPager]).
  /// - Advanced › الحالة: one source per picked status (open covers pending).
  static List<String>? mergedSegments(InboxQuery q) {
    if (q.chip == QuickChip.closed || q.chip == QuickChip.snoozed) return null;
    final st = q.advanced.statuses;
    if (st.isNotEmpty) {
      return [
        if (st.contains(StatusFilter.open)) 'all' else if (st.contains(StatusFilter.pending)) 'unassigned',
        if (st.contains(StatusFilter.snoozed)) 'snoozed',
        if (st.contains(StatusFilter.closed)) 'resolved',
      ];
    }
    if (q.segment == InboxSegment.all && q.chip == QuickChip.all) return const ['all', 'snoozed', 'resolved'];
    return null;
  }

  /// [_query] plus the pill's ownership when the status filter replaces the
  /// segment ("لي" + مؤجلة → snoozed segment, assignee me).
  static Map<String, Object?> _mergedQuery(InboxQuery q) {
    final query = _query(q);
    if (q.advanced.statuses.isNotEmpty && query['assignee'] == null) {
      switch (q.segment) {
        case InboxSegment.mine:
          query['assignee'] = 'me';
        case InboxSegment.unassigned:
          query['assignee'] = 'none';
        case InboxSegment.all:
          break;
      }
    }
    return query;
  }

  _MergedPager? _merged;

  Future<ConversationsPage> list(InboxQuery q, {String? cursor, int limit = 30}) => mergedSegments(q) == null
      ? _listOne(q, cursor: cursor, limit: limit)
      : _listMerged(q, cursor: cursor, limit: limit);

  /// Pill badges (Inbox v2 §4.2.1) + tab badge, independent of the
  /// selected pill (advanced filters still apply to the pill counts).
  Future<Map<String, int>> _pillCounts(InboxQuery q) async {
    final base = _query(q.copyWith(
      segment: InboxSegment.all,
      chip: QuickChip.all,
      advanced: q.advanced.copyWith(statuses: const {}, assignee: AssigneeFilter.all, clearColleague: true),
    ))
      ..remove('segment')
      ..remove('sort')
      ..remove('assignee');
    final r = await Future.wait([
      _countRaw({...base, 'segment': 'mine'}),
      _countRaw({...base, 'segment': 'all', 'unread': 'true'}),
      _countRaw({...base, 'segment': 'unassigned'}),
      _countRaw({'segment': 'all', 'unread': 'true'}),
      _countRaw({'segment': 'mine', 'unread': 'true'}),
    ]);
    return {'mine': r[0], 'unread': r[1], 'unassigned': r[2], 'total_unread': r[3], 'mine_unread': r[4]};
  }

  Future<ConversationsPage> _listMerged(InboxQuery q, {String? cursor, required int limit}) => _guard(() async {
        final query = _mergedQuery(q);
        final pager = cursor == null ? (_merged = _MergedPager(query, _api, mergedSegments(q)!)) : _merged;
        // A cursor from an older pager (query changed meanwhile): nothing more.
        if (pager == null || (cursor != null && cursor != pager.token)) {
          return const ConversationsPage(items: [], nextCursor: null, counts: {});
        }
        final items = await pager.next(limit.clamp(1, 50));
        final counts = <String, int>{};
        if (cursor == null) {
          final m = pager.firstMeta;
          final server = m['counts'] is Map ? Map<String, dynamic>.from(m['counts'] as Map) : const {};
          for (final e in server.entries) {
            if (e.value is num) counts[e.key] = (e.value as num).toInt();
          }
          counts.addAll(await _pillCounts(q));
        }
        return ConversationsPage(items: items, nextCursor: pager.hasMore ? pager.token : null, counts: counts);
      });

  Future<ConversationsPage> _listOne(InboxQuery q, {String? cursor, required int limit}) => _guard(() async {
        final query = _query(q);
        final res = await _api.get('conversations', query: {...query, 'limit': limit.clamp(1, 50), 'cursor': ?cursor});
        final serverCounts = res.meta['counts'] is Map ? Map<String, dynamic>.from(res.meta['counts'] as Map) : const {};
        final counts = <String, int>{
          for (final e in serverCounts.entries)
            if (e.value is num) e.key: (e.value as num).toInt(),
        };
        // Pill badges only on the first page (they don't change while paging).
        if (cursor == null) counts.addAll(await _pillCounts(q));
        return ConversationsPage(
          items: [for (final item in res.list) fromServer(item)],
          nextCursor: res.nextCursor,
          counts: counts,
        );
      });

  Future<int> _countRaw(Map<String, Object?> query) async {
    try {
      final r = await _api.get('conversations/count', query: query);
      return (r.map['count'] as num?)?.toInt() ?? 0;
    } on WdApiException {
      return 0;
    }
  }

  /// Live count for the Filters sheet button.
  Future<int> count(InboxQuery q) => _guard(() async {
        final segs = mergedSegments(q);
        if (segs != null) {
          final query = _mergedQuery(q);
          final n = await Future.wait([for (final s in segs) _countRaw({...query, 'segment': s})]);
          return n.fold<int>(0, (a, b) => a + b);
        }
        final r = await _api.get('conversations/count', query: _query(q));
        return (r.map['count'] as num?)?.toInt() ?? 0;
      });

  Future<void> _post(String path, [Map<String, Object?>? body]) => _guard(() => _api.post(path, body: body));

  Future<void> read(String id) => _post('conversations/$id/read');
  Future<void> unread(String id) => _post('conversations/$id/unread');
  Future<void> claim(String id) => _post('conversations/$id/claim');

  /// Bulk action (max 50 ids). Throws when every id failed; partial failures
  /// are accepted (the next refresh shows the real state).
  Future<void> bulk(Set<String> ids, String action, [Map<String, Object?> payload = const {}]) => _guard(() async {
        if (ids.isEmpty) return;
        final list = ids.toList();
        for (var i = 0; i < list.length; i += 50) {
          final chunk = list.sublist(i, (i + 50).clamp(0, list.length));
          final r = await _api.post('conversations/bulk', body: {'action': action, 'ids': chunk, ...payload});
          final results = (r.map['results'] as List? ?? const []).whereType<Map>().toList();
          final failed = results.where((x) => x['ok'] != true).toList();
          if (results.isNotEmpty && failed.length == results.length) {
            final err = failed.first['error'];
            throw ConversationsApiException(
              err is Map ? (err['status'] as num?)?.toInt() ?? 422 : 422,
              code: err is Map ? err['code'] as String? : null,
              message: err is Map ? err['message'] as String? : null,
            );
          }
        }
      });

  static String priorityValue(Priority? p) => p == null ? 'normal' : _priorityOut[p]!;
}

/// Keyset merge of several server segments into one list ordered by
/// activity. Every source keeps its own cursor and a buffer; a row is only
/// emitted once every unfinished source has a head to compare with, so the
/// order stays exact across pages.
class _MergedPager {
  _MergedPager(Map<String, Object?> query, this._api, List<String> segments)
      : _oldestFirst = query['sort'] == 'oldest',
        _firstSegment = segments.first,
        _sources = [
          for (final seg in segments) _Source({...query, 'segment': seg}),
        ];

  final String _firstSegment;

  static int _seq = 0;

  final WdApi _api;
  final bool _oldestFirst;
  final List<_Source> _sources;
  final Set<String> _seen = {};
  final String token = 'merged:${++_seq}';
  Map<String, dynamic> firstMeta = const {};

  bool get hasMore => _sources.any((s) => !s.done || s.buffer.isNotEmpty);

  Future<void> _fill(int limit) async {
    final need = [for (final s in _sources) if (!s.done && s.buffer.isEmpty) s];
    if (need.isEmpty) return;
    await Future.wait([
      for (final s in need)
        _api.get('conversations', query: {...s.query, 'limit': limit, 'cursor': ?s.cursor}).then((res) {
          if (s.query['segment'] == _firstSegment && s.cursor == null) firstMeta = res.meta;
          s.buffer.addAll([for (final item in res.list) ConversationsApi.fromServer(item)]);
          s.cursor = res.nextCursor;
          s.done = res.nextCursor == null;
        }),
    ]);
  }

  Future<List<ConversationSummary>> next(int limit) async {
    final out = <ConversationSummary>[];
    while (out.length < limit) {
      await _fill(limit);
      _Source? best;
      for (final s in _sources) {
        if (s.buffer.isEmpty) continue;
        if (best == null) {
          best = s;
          continue;
        }
        final a = s.buffer.first.lastActivityAt;
        final b = best.buffer.first.lastActivityAt;
        if (_oldestFirst ? a.isBefore(b) : a.isAfter(b)) best = s;
      }
      if (best == null) break;
      final row = best.buffer.removeAt(0);
      // A row can move between segments while paging: show it once.
      if (_seen.add(row.id)) out.add(row);
    }
    return out;
  }
}

class _Source {
  _Source(this.query);

  final Map<String, Object?> query;
  String? cursor;
  bool done = false;
  final List<ConversationSummary> buffer = [];
}
