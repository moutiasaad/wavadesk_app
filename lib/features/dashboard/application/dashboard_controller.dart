import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api_provider.dart';
import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../../conversations/data/conversations_repository.dart';
import '../data/dashboard_api.dart';
import '../domain/dashboard_snapshot.dart';
import '../../auth/application/auth_session.dart';

final dashboardApiProvider = Provider<DashboardApi>((ref) => HttpDashboardApi(ref.watch(wdApiRequiredProvider)));

/// Spec §6 states the screen draws from this.
@immutable
class DashboardState {
  const DashboardState({
    required this.range,
    required this.scope,
    this.teamId,
    this.snapshot,
    this.loading = false,
    this.error,
    this.offline = false,
    this.fromCache = false,
    this.lastUpdated,
    this.generation = 0,
    this.firstLoad = true,
    this.flashed = const {},
    this.switching = false,
  });

  final DashboardRange range;
  final DashboardScope scope;
  final String? teamId;
  final DashboardSnapshot? snapshot;

  /// A fetch is in flight.
  final bool loading;

  /// Last fetch failed; with no [snapshot] this is the full-error state.
  final Object? error;

  /// The last failure was a network one (cached snapshot + offline banner).
  final bool offline;

  /// Showing the cached copy from a previous session.
  final bool fromCache;
  final DateTime? lastUpdated;

  /// Bumped on scope / range change (content fade, bar regrow).
  final int generation;

  /// True until the first real answer arrived (count-up animation).
  final bool firstLoad;

  /// Metric keys changed by the last live update ('open', 'awaiting') → 300ms flash.
  final Set<String> flashed;

  /// Period changed and the new numbers are on their way: the cards stay
  /// and only their values / bars shimmer ([snapshot] is the old period's).
  final bool switching;

  bool get fullError => snapshot == null && error != null;
  bool get skeleton => snapshot == null && error == null;

  DashboardState copyWith({
    DashboardRange? range,
    DashboardScope? scope,
    String? teamId,
    bool clearTeam = false,
    DashboardSnapshot? snapshot,
    bool clearSnapshot = false,
    bool? loading,
    Object? error,
    bool clearError = false,
    bool? offline,
    bool? fromCache,
    DateTime? lastUpdated,
    int? generation,
    bool? firstLoad,
    Set<String>? flashed,
    bool? switching,
  }) =>
      DashboardState(
        range: range ?? this.range,
        scope: scope ?? this.scope,
        teamId: clearTeam ? null : (teamId ?? this.teamId),
        snapshot: clearSnapshot ? null : (snapshot ?? this.snapshot),
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        offline: offline ?? this.offline,
        fromCache: fromCache ?? this.fromCache,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        generation: generation ?? this.generation,
        firstLoad: firstLoad ?? this.firstLoad,
        flashed: flashed ?? this.flashed,
        switching: switching ?? this.switching,
      );
}

final dashboardControllerProvider = NotifierProvider<DashboardController, DashboardState>(DashboardController.new);

/// Fetch, cache, ETag, 60 s refresh while visible, debounced live deltas
/// (Dashboard spec §2, §6, §8).
class DashboardController extends Notifier<DashboardState> {
  static const refreshEvery = Duration(seconds: 60);
  static const resumeAfter = Duration(seconds: 30);
  static const liveDebounce = Duration(seconds: 2);

  DashboardApi get _api => ref.read(dashboardApiProvider);
  String? _etag;
  Timer? _timer;
  Timer? _liveTimer;
  Timer? _flashTimer;
  bool _visible = false;
  int _req = 0;
  DateTime? _lastFetch;

  String get _uid => ref.read(currentAgentProvider).id;
  String get _kRange => 'dash_range_$_uid';
  String get _kScope => 'dash_scope_$_uid';
  String get _kCache => 'dash_cache_$_uid';

  @override
  DashboardState build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    _etag = null;
    _lastFetch = null;
    final prefs = ref.read(sharedPrefsProvider);
    // v2 offers today / 7 days / 30 days only, always for "me" (the KPIs
    // read "بانتظار ردّك"); an old "yesterday" choice falls back to today.
    final saved = DashboardRange.parse(prefs.getString(_kRange));
    final range = saved == DashboardRange.yesterday ? DashboardRange.today : saved;
    const scope = DashboardScope.me;

    final sub = ref.read(conversationsRepositoryProvider).changes.listen((_) => _scheduleLive());
    ref.onDispose(() {
      sub.cancel();
      _timer?.cancel();
      _liveTimer?.cancel();
      _flashTimer?.cancel();
      _timer = _liveTimer = _flashTimer = null;
    });

    final cached = _readCache(range, scope);
    scheduleMicrotask(refresh);
    return DashboardState(
      range: range,
      scope: scope,
      snapshot: cached?.$1,
      lastUpdated: cached?.$2,
      fromCache: cached != null,
      loading: true,
    );
  }

  // ---- public ----------------------------------------------------------------

  Future<void> refresh({bool silent = false}) async {
    final req = ++_req;
    final s = state;
    // Retry after a first-load failure goes back to the skeleton, not the error.
    if (!silent) state = s.copyWith(loading: true, clearError: s.snapshot == null);
    try {
      final r = await _api.fetch(range: s.range, scope: s.scope, teamId: s.teamId, etag: s.snapshot == null ? null : _etag);
      if (req != _req) return;
      _lastFetch = DateTime.now();
      if (r.notModified && state.snapshot != null) {
        state = state.copyWith(loading: false, switching: false, clearError: true, offline: false, fromCache: false, lastUpdated: DateTime.now());
        return;
      }
      final snap = r.snapshot!;
      _etag = r.etag;
      // The server may narrow a scope we are not allowed (e.g. role changed).
      final scope = snap.permissions.scopes.contains(s.scope) ? s.scope : DashboardScope.me;
      state = state.copyWith(
        snapshot: snap,
        scope: scope,
        loading: false,
        switching: false,
        clearError: true,
        offline: false,
        fromCache: false,
        lastUpdated: DateTime.now(),
        firstLoad: s.snapshot == null || s.fromCache ? true : false,
      );
      _writeCache(snap);
      _syncPresence(snap.myPresence);
      // Count-up only once (§4.4).
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (req == _req && state.firstLoad) state = state.copyWith(firstLoad: false);
      });
    } on DashboardApiException catch (e) {
      if (req != _req) return;
      if (e.code == 'scope_forbidden' && s.scope != DashboardScope.me) {
        state = state.copyWith(scope: DashboardScope.me, clearTeam: true);
        return refresh(silent: silent);
      }
      state = state.copyWith(loading: false, error: e, offline: e.isNetwork, clearSnapshot: state.switching, switching: false);
    } catch (e) {
      if (req != _req) return;
      state = state.copyWith(loading: false, error: e, offline: false, clearSnapshot: state.switching, switching: false);
    }
  }

  void setRange(DashboardRange range) {
    if (range == state.range) return;
    Analytics.log('dash_range_change', {'from': state.range.wire, 'to': range.wire});
    ref.read(sharedPrefsProvider).setString(_kRange, range.wire);
    _switch(state.copyWith(range: range));
  }

  void setScope(DashboardScope scope, {String? teamId}) {
    if (scope == state.scope && teamId == state.teamId) return;
    Analytics.log('dash_scope_change', {'from': state.scope.name, 'to': scope.name});
    ref.read(sharedPrefsProvider).setString(_kScope, scope.name);
    _switch(state.copyWith(scope: scope, teamId: teamId, clearTeam: teamId == null));
  }

  Future<void> dismissAlert(DashboardAlert alert) async {
    Analytics.log('dash_alert_dismiss', {'kind': alert.kind.wire});
    final snap = state.snapshot;
    if (snap == null) return;
    state = state.copyWith(snapshot: snap.copyWith(alerts: [for (final a in snap.alerts) if (a.kind != alert.kind) a]));
    try {
      await _api.dismissAlert(alert.kind, scope: state.scope);
    } catch (_) {
      // Hidden locally either way; it comes back on the next refresh if the server kept it.
    }
  }

  /// The tab became visible / hidden (60 s timer only while visible).
  void setVisible(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    _timer?.cancel();
    if (!visible) return;
    Analytics.log('dash_view', {'scope': state.scope.name, 'range': state.range.wire, 'role': ref.read(currentAgentProvider).role.name});
    _timer = Timer.periodic(refreshEvery, (_) => refresh(silent: true));
    if (_lastFetch != null && DateTime.now().difference(_lastFetch!) > resumeAfter) refresh(silent: true);
  }

  /// App came back to the foreground.
  void onResume() {
    if (!_visible) return;
    if (_lastFetch == null || DateTime.now().difference(_lastFetch!) > resumeAfter) refresh(silent: true);
  }

  // ---- internals ---------------------------------------------------------------

  void _switch(DashboardState next) {
    final cached = _readCache(next.range, next.scope);
    _etag = null;
    // No cached copy for the new period: keep the current cards on screen
    // (values shimmer) instead of swapping the whole page for a skeleton.
    state = next.copyWith(
      snapshot: cached?.$1,
      lastUpdated: cached?.$2,
      fromCache: cached != null,
      clearError: true,
      generation: next.generation + 1,
      firstLoad: true,
      switching: cached == null && next.snapshot != null,
    );
    refresh();
  }

  /// §8: inbox events → debounced lightweight recompute of open / awaiting /
  /// current chart bucket (today only).
  void _scheduleLive() {
    if (!_visible || state.snapshot == null || state.range != DashboardRange.today) return;
    _liveTimer?.cancel();
    _liveTimer = Timer(liveDebounce, _applyLive);
  }

  Future<void> _applyLive() async {
    final snap = state.snapshot;
    if (snap == null) return;
    try {
      final live = await _api.live(scope: state.scope, teamId: state.teamId);
      final cur = state.snapshot;
      if (cur == null || cur.range != DashboardRange.today) return;
      final changed = <String>{
        if (live.open != cur.metrics.open) 'open',
        if (live.awaiting != cur.metrics.awaiting) 'awaiting',
      };
      state = state.copyWith(
        snapshot: cur.copyWith(
          generatedAt: DateTime.now(),
          metrics: cur.metrics.copyWith(open: live.open, awaiting: live.awaiting, oldestWaitSeconds: live.oldestWaitSeconds),
          volume: VolumeSeries(
            hourly: cur.volume.hourly,
            total: cur.volume.total - (cur.volume.series.where((b) => b.isCurrent).firstOrNull?.total ?? 0) + live.currentTotal,
            series: [for (final b in cur.volume.series) b.isCurrent ? b.copyWith(total: live.currentTotal, ai: live.currentAi) : b],
          ),
        ),
        flashed: changed,
      );
      if (changed.isNotEmpty) {
        _flashTimer?.cancel();
        _flashTimer = Timer(const Duration(milliseconds: 300), () => state = state.copyWith(flashed: const {}));
      }
    } catch (_) {
      // Live deltas are best-effort; the 60 s refresh catches up.
    }
  }

  /// The server knows the status set on the web panel too.
  void _syncPresence(String? wire) {
    final p = Presence.values.where((v) => v.name == wire).firstOrNull;
    if (p == null) return;
    if (ref.read(settingsProvider).presence != p) ref.read(settingsProvider.notifier).setPresence(p);
  }

  (DashboardSnapshot, DateTime)? _readCache(DashboardRange range, DashboardScope scope) {
    try {
      final raw = ref.read(sharedPrefsProvider).getString(_kCache);
      if (raw == null) return null;
      final j = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (j['range'] != range.wire || j['scope'] != scope.name) return null;
      final at = DateTime.tryParse('${j['saved_at']}');
      if (at == null) return null;
      _etag = j['etag'] as String?;
      return (DashboardSnapshot.fromJson(Map<String, dynamic>.from(j['snapshot'] as Map)), at);
    } catch (_) {
      return null;
    }
  }

  void _writeCache(DashboardSnapshot s) {
    try {
      ref.read(sharedPrefsProvider).setString(
            _kCache,
            jsonEncode({
              'range': state.range.wire,
              'scope': state.scope.name,
              'saved_at': DateTime.now().toIso8601String(),
              'etag': _etag,
              'snapshot': s.toJson(),
            }),
          );
    } catch (_) {}
  }
}
