import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/api/wd_api.dart';
import '../domain/notification.dart';
import '../domain/notification_type.dart';

/// One page of `GET notifications` (Notifications spec §10).
@immutable
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    this.nextCursor,
    this.unreadCount = 0,
    this.counts = const {},
  });

  final List<NotificationItem> items;
  final String? nextCursor;
  final int unreadCount;

  /// Per-filter unread counts (`meta.counts`): unread, mentions, assignments,
  /// ai, system. Missing on older servers.
  final Map<String, int> counts;

  Map<String, Object?> toJson() => {
        'items': [for (final i in items) i.toJson()],
        'next_cursor': nextCursor,
        'unread_count': unreadCount,
        'counts': counts,
      };

  factory NotificationsPage.fromJson(Map<String, dynamic> j) => NotificationsPage(
        items: [
          for (final i in (j['items'] as List? ?? const []))
            if (i is Map) NotificationItem.fromJson(Map<String, dynamic>.from(i)),
        ],
        nextCursor: j['next_cursor'] as String?,
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
        counts: {
          for (final e in ((j['counts'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num?)?.toInt() ?? 0,
        },
      );
}

class NotificationsApiException implements Exception {
  const NotificationsApiException(this.status, {this.code, this.message, this.details = const {}});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;
  final Map<String, dynamic> details;

  bool get isNetwork => status == 0;

  /// Target gone (conversation deleted, request withdrawn) — §6 "Stale action".
  bool get isStale => status == 404 || status == 410 || code == 'not_found' || code == 'expired';

  @override
  String toString() => 'NotificationsApiException($status $code)';
}

/// Result of an inline action (`POST notifications/{id}/actions/{actionId}`).
@immutable
class NotificationActionResult {
  const NotificationActionResult({this.notification, this.result = const {}});

  final NotificationItem? notification;
  final Map<String, dynamic> result;
}

abstract interface class NotificationsApi {
  Future<NotificationsPage> fetch({required NotificationFilter filter, String? cursor, int limit = 30});
  Future<void> markRead(String id);
  Future<void> markUnread(String id);
  Future<int> readAll({NotificationFilter? filter});
  Future<void> delete(String id);
  Future<void> deleteRead();
  Future<NotificationActionResult> action(String id, String actionId);
  Future<void> muteType(String type, {DateTime? until});

  /// New rows since the last poll (in-app banner + realtime insert, §9.2/§14).
  Future<NotificationsPage> latest({int limit = 10});
}

/// Real client for `/mobile/v1/notifications*` (§10).
class HttpNotificationsApi implements NotificationsApi {
  HttpNotificationsApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw NotificationsApiException(e.status, code: e.code, message: e.message, details: e.details);
    }
  }

  NotificationsPage _page(WdResponse r) => NotificationsPage(
        items: [for (final j in r.list) NotificationItem.fromJson(j)],
        nextCursor: r.nextCursor,
        unreadCount: (r.meta['unread_count'] as num?)?.toInt() ?? 0,
        counts: {
          for (final e in ((r.meta['counts'] as Map?) ?? const {}).entries) '${e.key}': (e.value as num?)?.toInt() ?? 0,
        },
      );

  @override
  Future<NotificationsPage> fetch({required NotificationFilter filter, String? cursor, int limit = 30}) =>
      _guard(() async => _page(await _api.get('notifications', query: {
            'filter': filter.name,
            // Older servers only understand `unread=1`.
            if (filter == NotificationFilter.unread) 'unread': 1,
            'cursor': cursor,
            'limit': limit,
          })));

  @override
  Future<NotificationsPage> latest({int limit = 10}) =>
      _guard(() async => _page(await _api.get('notifications', query: {'filter': 'all', 'limit': limit})));

  @override
  Future<void> markRead(String id) => _guard(() => _api.post('notifications/$id/read'));

  @override
  Future<void> markUnread(String id) => _guard(() => _api.post('notifications/$id/unread'));

  @override
  Future<int> readAll({NotificationFilter? filter}) => _guard(() async {
        final r = await _api.post('notifications/read-all', body: {
          if (filter != null && filter != NotificationFilter.all) 'filter': filter.name,
        });
        return (r.map['updated'] as num?)?.toInt() ?? (r.map['marked'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<void> delete(String id) => _guard(() => _api.delete('notifications/$id'));

  @override
  Future<void> deleteRead() => _guard(() => _api.delete('notifications', query: {'read': 'true'}));

  @override
  Future<NotificationActionResult> action(String id, String actionId) => _guard(() async {
        final r = await _api.post('notifications/$id/actions/$actionId');
        final m = r.map;
        final n = m['notification'];
        return NotificationActionResult(
          notification: n is Map ? NotificationItem.fromJson(Map<String, dynamic>.from(n)) : null,
          result: m['result'] is Map ? Map<String, dynamic>.from(m['result'] as Map) : const {},
        );
      });

  @override
  Future<void> muteType(String type, {DateTime? until}) => _guard(() => _api.post(
        'notification-types/$type/mute',
        body: {if (until != null) 'until': until.toUtc().toIso8601String()},
      ));
}

/// Offline stand-in fed by `assets/fake/notifications.json`.
class SampleNotificationsApi implements NotificationsApi {
  SampleNotificationsApi({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<NotificationItem>? _rows;
  Map<String, dynamic>? _live;
  DateTime? _loadedAt;
  bool _liveAdded = false;
  bool _rejectFailedOnce = false;

  Future<List<NotificationItem>> _all() async {
    if (_rows != null) {
      _maybeAddLive();
      return _rows!;
    }
    final raw = jsonDecode(await _bundle.loadString('assets/fake/notifications.json')) as Map<String, dynamic>;
    final now = DateTime.now();
    _loadedAt = now;
    Map<String, dynamic> withTimes(Map<String, dynamic> j) {
      final ago = (j['ago_minutes'] as num?)?.toInt() ?? 0;
      final created = now.subtract(Duration(minutes: ago));
      return {
        ...j,
        'created_at': created.toUtc().toIso8601String(),
        'read_at': j['read'] == true ? created.toUtc().toIso8601String() : null,
      };
    }

    _rows = [
      for (final j in (raw['notifications'] as List? ?? const []))
        if (j is Map) NotificationItem.fromJson(withTimes(Map<String, dynamic>.from(j))),
    ];
    _live = raw['live'] is Map ? Map<String, dynamic>.from(raw['live'] as Map) : null;
    return _rows!;
  }

  void _maybeAddLive() {
    final live = _live;
    if (_liveAdded || live == null || _loadedAt == null) return;
    final after = Duration(seconds: (live['after_seconds'] as num?)?.toInt() ?? 40);
    if (DateTime.now().difference(_loadedAt!) < after) return;
    _liveAdded = true;
    _rows!.insert(
      0,
      NotificationItem.fromJson({...live, 'created_at': DateTime.now().toUtc().toIso8601String(), 'read_at': null}),
    );
  }

  Future<void> _latency([int ms = 450]) => Future<void>.delayed(Duration(milliseconds: ms));

  NotificationItem _byId(String id) => _rows!.firstWhere(
        (n) => n.id == id,
        orElse: () => throw const NotificationsApiException(404, code: 'not_found'),
      );

  void _replace(NotificationItem n) {
    final i = _rows!.indexWhere((r) => r.id == n.id);
    if (i >= 0) _rows![i] = n;
  }

  Map<String, int> _counts(List<NotificationItem> rows) {
    final unread = rows.where((n) => !n.isRead).toList();
    return {
      'unread': unread.length,
      for (final f in [
        NotificationFilter.mentions,
        NotificationFilter.assignments,
        NotificationFilter.ai,
        NotificationFilter.system,
      ])
        f.name: unread.where((n) => f.includes(n.type)).length,
    };
  }

  @override
  Future<NotificationsPage> fetch({required NotificationFilter filter, String? cursor, int limit = 30}) async {
    await _latency();
    final rows = await _all();
    final matching = rows.where(filter.matches).toList();
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, matching.length);
    return NotificationsPage(
      items: matching.sublist(start.clamp(0, matching.length), end),
      nextCursor: end < matching.length ? '$end' : null,
      unreadCount: rows.where((n) => !n.isRead).length,
      counts: _counts(rows),
    );
  }

  @override
  Future<NotificationsPage> latest({int limit = 10}) async {
    final rows = await _all();
    return NotificationsPage(
      items: rows.take(limit).toList(),
      unreadCount: rows.where((n) => !n.isRead).length,
      counts: _counts(rows),
    );
  }

  @override
  Future<void> markRead(String id) async {
    await _latency(150);
    await _all();
    final n = _byId(id);
    if (!n.isRead) _replace(n.copyWith(readAt: DateTime.now()));
  }

  @override
  Future<void> markUnread(String id) async {
    await _latency(150);
    await _all();
    _replace(_byId(id).copyWith(clearRead: true));
  }

  @override
  Future<int> readAll({NotificationFilter? filter}) async {
    await _latency(250);
    final rows = await _all();
    var updated = 0;
    for (var i = 0; i < rows.length; i++) {
      if (!rows[i].isRead && (filter ?? NotificationFilter.all).matches(rows[i])) {
        rows[i] = rows[i].copyWith(readAt: DateTime.now());
        updated++;
      }
    }
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _latency(200);
    (await _all()).removeWhere((n) => n.id == id);
  }

  @override
  Future<void> deleteRead() async {
    await _latency(250);
    (await _all()).removeWhere((n) => n.isRead);
  }

  @override
  Future<NotificationActionResult> action(String id, String actionId) async {
    await _latency(700);
    await _all();
    final n = _byId(id);
    if (actionId == 'reject' && !_rejectFailedOnce) {
      _rejectFailedOnce = true;
      throw const NotificationsApiException(410, code: 'expired');
    }
    final updated = n.copyWith(
      readAt: DateTime.now(),
      actions: [
        for (final a in (n.actions.isEmpty ? NotificationTemplates.defaultActions(n.type) : n.actions))
          NotificationAction(id: a.id, label: a.label, style: a.style, state: NotificationActionState.done),
      ],
    );
    _replace(updated);
    return NotificationActionResult(notification: updated, result: {'action': actionId, 'ok': true});
  }

  @override
  Future<void> muteType(String type, {DateTime? until}) => _latency(150);
}
