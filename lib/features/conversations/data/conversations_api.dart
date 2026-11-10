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
      if (q.chip == QuickChip.ai || (q.segment == InboxSegment.all && a.assignee == AssigneeFilter.ai)) 'ai': 'true',
      'sort': switch (a.sort) {
        InboxSort.oldest || InboxSort.waiting => 'oldest',
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
    );
  }

  // ---- calls ------------------------------------------------------------------

  Future<ConversationsPage> list(InboxQuery q, {String? cursor, int limit = 30}) => _guard(() async {
        final query = _query(q);
        final res = await _api.get('conversations', query: {...query, 'limit': limit.clamp(1, 50), 'cursor': ?cursor});
        final serverCounts = res.meta['counts'] is Map ? Map<String, dynamic>.from(res.meta['counts'] as Map) : const {};
        final counts = <String, int>{
          for (final e in serverCounts.entries)
            if (e.value is num) e.key: (e.value as num).toInt(),
        };
        // Extra badges only on the first page (they don't change while paging).
        if (cursor == null) {
          final extra = await Future.wait([
            _countRaw({...query, 'unread': 'true'}),
            _countRaw({'segment': 'mine', 'unread': 'true'}),
          ]);
          counts['unread'] = extra[0];
          counts['mine_unread'] = extra[1];
        }
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
