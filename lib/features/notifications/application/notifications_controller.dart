import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/analytics.dart';
import '../../auth/application/auth_session.dart';
import '../../conversations/application/conversations_controller.dart';
import '../data/notifications_api.dart';
import '../data/notifications_repository.dart';
import '../domain/notification.dart';
import '../domain/notification_type.dart';
import 'unread_badge_controller.dart';

enum NotificationsPhase { loading, ready, error }

/// Inline-action state of one row (§6).
@immutable
class NotificationRowUi {
  const NotificationRowUi({this.busyAction, this.resolution, this.claimedBy, this.stale = false});

  /// Action id currently loading.
  final String? busyAction;

  /// claimed_you | claimed_by | approved | rejected — replaces the subtitle
  /// and removes the action buttons.
  final String? resolution;
  final String? claimedBy;

  /// Target gone → row dims 50% (§6).
  final bool stale;
}

@immutable
class NotificationsState {
  const NotificationsState({
    required this.filter,
    this.phase = NotificationsPhase.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.counts = const {},
    this.unreadCount = 0,
    this.rows = const {},
    this.expanded = const {},
    this.inserted = const {},
  });

  final NotificationFilter filter;
  final NotificationsPhase phase;
  final List<NotificationItem> items;
  final String? nextCursor;
  final bool loadingMore;
  final bool loadMoreFailed;
  final Map<String, int> counts;
  final int unreadCount;
  final Map<String, NotificationRowUi> rows;

  /// Expanded stacked groups (head ids).
  final Set<String> expanded;

  /// Ids inserted by realtime (size + fade in, §14).
  final Set<String> inserted;

  bool get hasMore => nextCursor != null;

  NotificationsState copyWith({
    NotificationFilter? filter,
    NotificationsPhase? phase,
    List<NotificationItem>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    bool? loadMoreFailed,
    Map<String, int>? counts,
    int? unreadCount,
    Map<String, NotificationRowUi>? rows,
    Set<String>? expanded,
    Set<String>? inserted,
  }) =>
      NotificationsState(
        filter: filter ?? this.filter,
        phase: phase ?? this.phase,
        items: items ?? this.items,
        nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
        counts: counts ?? this.counts,
        unreadCount: unreadCount ?? this.unreadCount,
        rows: rows ?? this.rows,
        expanded: expanded ?? this.expanded,
        inserted: inserted ?? this.inserted,
      );
}

/// Outcome of an inline action, for the screen to react (§6).
enum NotificationActionOutcome { navigate, claimedYou, claimedBy, approved, rejected, stale, failed, offline }

/// List, paging, realtime insert, read / unread, delete, undo (§16). Kept
/// alive for the session so reopening renders the last list instantly and
/// async writes never hit a disposed notifier.
final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(NotificationsController.new);

class NotificationsController extends Notifier<NotificationsState> {
  static const pageSize = 30;

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);
  UnreadBadgeController get _badge => ref.read(unreadBadgeProvider.notifier);

  final Map<String, Timer> _pendingDeletes = {};
  int _loadToken = 0;

  @override
  NotificationsState build() {
    // Signing out / in starts from scratch (another user, another cache).
    ref.watch(authProvider);
    final filter = _repo.lastFilter;
    // An empty cached page is not shown as "no notifications" before the
    // network confirms it (core/state/load_state.dart rule 2).
    final cached = _nonEmpty(_repo.cached(filter));
    final sub = _badge.arrivals.listen(_onArrival);
    ref.onDispose(() {
      sub.cancel();
      // Commit pending deletes when the screen goes away.
      for (final e in _pendingDeletes.entries) {
        e.value.cancel();
        unawaited(_repo.api.delete(e.key).catchError((_) {}));
      }
      _pendingDeletes.clear();
    });
    // Load after build (never mutate state during build).
    Future.microtask(() => _load(silent: cached != null));
    return NotificationsState(
      filter: filter,
      // Cached: render instantly, refresh silently (§7).
      phase: cached != null ? NotificationsPhase.ready : NotificationsPhase.loading,
      items: cached?.items ?? const [],
      nextCursor: cached?.nextCursor,
      counts: cached?.counts ?? const {},
      unreadCount: cached?.unreadCount ?? 0,
    );
  }

  Future<void> _load({bool silent = false}) async {
    final token = ++_loadToken;
    final filter = state.filter;
    if (!silent) state = state.copyWith(phase: NotificationsPhase.loading);
    try {
      final page = await _repo.api.fetch(filter: filter, limit: pageSize);
      if (token != _loadToken) return;
      state = state.copyWith(
        phase: NotificationsPhase.ready,
        items: page.items.where((n) => !_pendingDeletes.containsKey(n.id)).toList(),
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        counts: page.counts,
        unreadCount: page.unreadCount,
        loadMoreFailed: false,
      );
      _badge.apply(page);
      unawaited(_repo.cache(filter, page));
    } catch (_) {
      // Any failure (network, server, bad payload) — never stay on the skeleton.
      if (token != _loadToken) return;
      state = state.copyWith(phase: state.items.isEmpty ? NotificationsPhase.error : NotificationsPhase.ready);
    }
  }

  static NotificationsPage? _nonEmpty(NotificationsPage? p) => p == null || p.items.isEmpty ? null : p;

  Future<void> refresh() => _load(silent: state.items.isNotEmpty);

  Future<void> retry() => _load();

  Future<void> setFilter(NotificationFilter f) async {
    if (f == state.filter) return;
    unawaited(_repo.saveFilter(f));
    final cached = _nonEmpty(_repo.cached(f));
    state = state.copyWith(
      filter: f,
      items: cached?.items ?? const [],
      nextCursor: cached?.nextCursor,
      clearCursor: cached?.nextCursor == null,
      phase: cached != null ? NotificationsPhase.ready : NotificationsPhase.loading,
      expanded: const {},
    );
    await _load(silent: cached != null);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    state = state.copyWith(loadingMore: true, loadMoreFailed: false);
    final filter = state.filter;
    try {
      final page = await _repo.api.fetch(filter: filter, cursor: state.nextCursor, limit: pageSize);
      if (filter != state.filter) return;
      final known = {for (final i in state.items) i.id};
      state = state.copyWith(
        items: [...state.items, for (final i in page.items) if (!known.contains(i.id)) i],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        loadingMore: false,
      );
    } on NotificationsApiException {
      state = state.copyWith(loadingMore: false, loadMoreFailed: true);
    }
  }

  /// Realtime insert at the top of اليوم (§14) — stream callback, not build.
  void _onArrival(NotificationItem n) {
    if (state.items.any((i) => i.id == n.id) || !state.filter.matches(n)) return;
    state = state.copyWith(
      items: [n, ...state.items],
      unreadCount: state.unreadCount + 1,
      inserted: {...state.inserted, n.id},
    );
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (state.inserted.contains(n.id)) {
        state = state.copyWith(inserted: {...state.inserted}..remove(n.id));
      }
    });
  }

  NotificationItem? byId(String id) {
    for (final i in state.items) {
      if (i.id == id) return i;
    }
    return null;
  }

  void _replace(NotificationItem n) =>
      state = state.copyWith(items: [for (final i in state.items) i.id == n.id ? n : i]);

  /// Optimistic read / unread (tap, swipe, long-press, action). Reverts on error.
  Future<void> setRead(String id, {required bool read}) async {
    final n = byId(id);
    if (n == null || n.isRead == read) return;
    final updated = read ? n.copyWith(readAt: DateTime.now()) : n.copyWith(clearRead: true);
    _replace(updated);
    final delta = read ? -1 : 1;
    state = state.copyWith(unreadCount: (state.unreadCount + delta).clamp(0, 1 << 30));
    _badge.adjust(delta);
    try {
      read ? await _repo.api.markRead(id) : await _repo.api.markUnread(id);
    } on NotificationsApiException {
      final now = byId(id);
      if (now != null) _replace(n);
      state = state.copyWith(unreadCount: (state.unreadCount - delta).clamp(0, 1 << 30));
      _badge.adjust(-delta);
    }
  }

  Future<void> toggleRead(String id) async {
    final n = byId(id);
    if (n != null) await setRead(id, read: !n.isRead);
  }

  /// قراءة الكل (optimistic). Returns the undo, or null when nothing changed.
  Future<Future<void> Function()?> readAll() async {
    final unread = state.items.where((n) => !n.isRead).toList();
    if (unread.isEmpty && state.unreadCount == 0) return null;
    final before = state.unreadCount;
    final now = DateTime.now();
    state = state.copyWith(
      items: [for (final i in state.items) i.isRead ? i : i.copyWith(readAt: now)],
      unreadCount: 0,
    );
    _badge.setUnread(0);
    Analytics.log('ntf_read_all', {'count': before});
    try {
      await _repo.api.readAll();
    } on NotificationsApiException {
      state = state.copyWith(
        items: [for (final i in state.items) unread.any((u) => u.id == i.id) ? i.copyWith(clearRead: true) : i],
        unreadCount: before,
      );
      _badge.setUnread(before);
      rethrow;
    }
    return () async {
      final ids = {for (final u in unread) u.id};
      state = state.copyWith(
        items: [for (final i in state.items) ids.contains(i.id) ? i.copyWith(clearRead: true) : i],
        unreadCount: before,
      );
      _badge.setUnread(before);
      for (final id in ids) {
        try {
          await _repo.api.markUnread(id);
        } on NotificationsApiException {
          // Server without the unread endpoint: the next refresh corrects it.
        }
      }
    };
  }

  /// Removes the row now and deletes on the server after the Undo window.
  /// Returns the undo.
  Future<void> Function() delete(String id) {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index < 0) return () async {};
    final n = state.items[index];
    state = state.copyWith(
      items: [...state.items]..removeAt(index),
      unreadCount: n.isRead ? state.unreadCount : (state.unreadCount - 1).clamp(0, 1 << 30),
    );
    if (!n.isRead) _badge.adjust(-1);
    Analytics.log('ntf_delete', {'type': n.rawType});
    _pendingDeletes[id]?.cancel();
    _pendingDeletes[id] = Timer(const Duration(seconds: 5), () {
      _pendingDeletes.remove(id);
      unawaited(_repo.api.delete(id).catchError((_) {}));
    });
    return () async {
      _pendingDeletes.remove(id)?.cancel();
      if (state.items.any((i) => i.id == id)) return;
      final list = [...state.items]..insert(index.clamp(0, state.items.length), n);
      state = state.copyWith(items: list, unreadCount: n.isRead ? state.unreadCount : state.unreadCount + 1);
      if (!n.isRead) _badge.adjust(1);
    };
  }

  /// ⋮ → حذف المقروءة.
  Future<void> deleteRead() async {
    final snapshot = state.items;
    state = state.copyWith(items: state.items.where((i) => !i.isRead).toList());
    try {
      await _repo.api.deleteRead();
    } on NotificationsApiException {
      state = state.copyWith(items: snapshot);
      rethrow;
    }
  }

  /// Long-press → كتم هذا النوع.
  Future<void> mute(NotificationItem n) async {
    Analytics.log('ntf_mute_type', {'type': n.rawType});
    await _repo.mute(n.rawType);
    if (!n.isRead) await setRead(n.id, read: true);
  }

  void toggleExpanded(String headId) {
    final next = {...state.expanded};
    next.contains(headId) ? next.remove(headId) : next.add(headId);
    state = state.copyWith(expanded: next);
  }

  void _row(String id, NotificationRowUi ui) => state = state.copyWith(rows: {...state.rows, id: ui});

  void markStale(String id) => _row(id, const NotificationRowUi(stale: true));

  /// Inline actions (§6). Navigation-only actions return [navigate].
  Future<NotificationActionOutcome> runAction(NotificationItem n, String actionId, {required bool online}) async {
    const navigateOnly = {'view', 'reply', 'add_answer', 'review', 'reconnect', 'open', 'plans', 'update'};
    if (navigateOnly.contains(actionId)) {
      unawaited(setRead(n.id, read: true));
      return NotificationActionOutcome.navigate;
    }
    if (!online) return NotificationActionOutcome.offline;
    _row(n.id, NotificationRowUi(busyAction: actionId));
    final started = DateTime.now();
    NotificationActionOutcome outcome;
    try {
      if (actionId == 'claim') {
        final conv = n.conversationId;
        if (conv == null) throw const NotificationsApiException(404, code: 'not_found');
        // Same claim API as the Claim spec §7.1 (sample + real modes).
        final r = await ref.read(conversationsControllerProvider.notifier).claim(conv);
        if (r.claimedBy != null) {
          _row(n.id, NotificationRowUi(resolution: 'claimed_by', claimedBy: r.claimedBy));
          outcome = NotificationActionOutcome.claimedBy;
        } else if (r.forbidden) {
          _row(n.id, const NotificationRowUi(stale: true));
          outcome = NotificationActionOutcome.stale;
        } else if (r.failed) {
          _row(n.id, const NotificationRowUi());
          outcome = NotificationActionOutcome.failed;
        } else {
          _row(n.id, const NotificationRowUi(resolution: 'claimed_you'));
          outcome = NotificationActionOutcome.claimedYou;
        }
      } else {
        final r = await _repo.api.action(n.id, actionId);
        if (r.notification != null) _replace(r.notification!);
        final approved = actionId == 'approve';
        _row(n.id, NotificationRowUi(resolution: approved ? 'approved' : 'rejected'));
        outcome = approved ? NotificationActionOutcome.approved : NotificationActionOutcome.rejected;
      }
      await setRead(n.id, read: true);
    } on NotificationsApiException catch (e) {
      if (e.isStale) {
        _row(n.id, const NotificationRowUi(stale: true));
        outcome = NotificationActionOutcome.stale;
      } else {
        _row(n.id, const NotificationRowUi());
        outcome = e.isNetwork ? NotificationActionOutcome.offline : NotificationActionOutcome.failed;
      }
    }
    Analytics.log('ntf_action', {
      'type': n.rawType,
      'action': actionId,
      'result': outcome.name,
      'latency_ms': DateTime.now().difference(started).inMilliseconds,
    });
    return outcome;
  }
}
