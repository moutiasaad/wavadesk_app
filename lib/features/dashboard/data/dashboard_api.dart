import 'dart:async';

import '../../../core/api/wd_api.dart';
import '../domain/dashboard_snapshot.dart';

/// Result of a conditional `GET dashboard`.
class DashboardFetch {
  const DashboardFetch({this.snapshot, this.etag, this.notModified = false});

  final DashboardSnapshot? snapshot;
  final String? etag;

  /// 304: the cached snapshot is still current.
  final bool notModified;
}

class DashboardApiException implements Exception {
  const DashboardApiException(this.status, {this.code, this.message});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;

  bool get isNetwork => status == 0;

  @override
  String toString() => 'DashboardApiException($status $code)';
}

/// Dashboard spec §9.
abstract interface class DashboardApi {
  Future<DashboardFetch> fetch({required DashboardRange range, required DashboardScope scope, String? teamId, String? etag});
  Future<DashboardLive> live({required DashboardScope scope, String? teamId});
  Future<void> setPresence(String status, {DateTime? until});
  Future<void> dismissAlert(DashboardAlertKind kind, {required DashboardScope scope});
}

class HttpDashboardApi implements DashboardApi {
  HttpDashboardApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw DashboardApiException(e.status, code: e.code, message: e.message);
    }
  }

  @override
  Future<DashboardFetch> fetch({required DashboardRange range, required DashboardScope scope, String? teamId, String? etag}) =>
      _guard(() async {
        final r = await _api.get(
          'dashboard',
          query: {'range': range.wire, 'scope': scope.name, 'team_id': teamId},
          ifNoneMatch: etag,
        );
        if (r.notModified) return DashboardFetch(etag: r.etag ?? etag, notModified: true);
        return DashboardFetch(snapshot: DashboardSnapshot.fromJson(r.map), etag: r.etag);
      });

  @override
  Future<DashboardLive> live({required DashboardScope scope, String? teamId}) => _guard(() async {
        final r = await _api.get('dashboard/live', query: {'scope': scope.name, 'team_id': teamId});
        return DashboardLive.fromJson(r.map);
      });

  @override
  Future<void> setPresence(String status, {DateTime? until}) =>
      _guard(() => _api.put('me/presence', body: {'status': status, if (until != null) 'until': until.toUtc().toIso8601String()}));

  @override
  Future<void> dismissAlert(DashboardAlertKind kind, {required DashboardScope scope}) =>
      _guard(() => _api.post('dashboard/alerts/${kind.wire}/dismiss?scope=${scope.name}', body: const <String, Object?>{}));
}
