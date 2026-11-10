import 'dart:async';

import 'package:flutter/foundation.dart';

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
