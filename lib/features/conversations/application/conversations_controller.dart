import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/state/load_state.dart';
import '../../../core/utils/analytics.dart';
import '../data/conversations_api.dart';
import '../data/conversations_repository.dart';
import '../data/conversations_socket.dart';
import '../domain/conversation_filters.dart';
import '../domain/conversation_summary.dart';
import 'conversation_filters_controller.dart';
import '../../auth/application/auth_session.dart';

enum InboxLoadPhase { loading, ready, error }

@immutable
class ConversationsState {
  const ConversationsState({
    this.items = const [],
    this.nextCursor,
    this.counts = const {},
    this.phase = InboxLoadPhase.loading,
    this.loadingMore = false,
    this.pageError = false,
    this.fromCache = false,
    this.inserted = const {},
    this.network = NetworkState.online,
    this.query = const InboxQuery(),
  });

  final List<ConversationSummary> items;
  final String? nextCursor;
  final Map<String, int> counts;
  final InboxLoadPhase phase;
  final bool loadingMore;

  /// Pagination failed → error footer with retry (§4.10).
  final bool pageError;

  /// Showing the persisted copy (offline / before the first refresh).
  final bool fromCache;

  /// Ids that appeared in the last real-time refresh (new-messages pill).
  final Set<String> inserted;
  final NetworkState network;
  final InboxQuery query;

  bool get hasMore => nextCursor != null;

  ConversationsState copyWith({
    List<ConversationSummary>? items,
    String? nextCursor,
    bool clearCursor = false,
    Map<String, int>? counts,
    InboxLoadPhase? phase,
    bool? loadingMore,
    bool? pageError,
    bool? fromCache,
    Set<String>? inserted,
    NetworkState? network,
  }) => ConversationsState(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    counts: counts ?? this.counts,
    phase: phase ?? this.phase,
    loadingMore: loadingMore ?? this.loadingMore,
    pageError: pageError ?? this.pageError,
    fromCache: fromCache ?? this.fromCache,
    inserted: inserted ?? this.inserted,
    network: network ?? this.network,
    query: query,
  );
}

/// Outcome of an optimistic action, for the screen's snackbar.
class InboxActionResult {
  const InboxActionResult({this.undo, this.failed = false, this.claimedBy, this.forbidden = false});

  final Future<void> Function()? undo;
  final bool failed;

  /// Claim lost the race (409).
  final String? claimedBy;

  /// Claim refused (403 not_in_team / role / capacity, 423 resolved / blocked).
  final bool forbidden;
}

final conversationsControllerProvider = NotifierProvider<ConversationsController, ConversationsState>(
  ConversationsController.new,
);

/// Paging, real-time merge and optimistic actions (Inbox spec §4.10, §5, §6).
class ConversationsController extends Notifier<ConversationsState> {
  static const pageSize = 30;

  ConversationsRepository get _repo => ref.read(conversationsRepositoryProvider);
  int _generation = 0;

  @override
  ConversationsState build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    final query = ref.watch(conversationFiltersProvider);
    final socket = ref.read(conversationsSocketProvider);
    final repo = ref.read(conversationsRepositoryProvider);
    final generation = ++_generation;

    final subs = <StreamSubscription<Object?>>[
      repo.changes.listen((_) => _refreshWindow()),
      socket.events.listen((e) {
        if (e is InboxRefreshNeeded) _refreshWindow();
      }),
      socket.status.listen((s) {
        final wasOffline = state.network != NetworkState.online;
        state = state.copyWith(network: s);
        if (wasOffline && s == NetworkState.online) _refreshWindow(); // reconnect refreshes
      }),
    ];
    ref.onDispose(() {
      _retryTimer?.cancel();
      for (final s in subs) {
        s.cancel();
      }
    });

    // Only this exact query's rows: the disk cache holds the unfiltered
    // segment, so it must not stand in for another chip/filter.
    final unfiltered = query.chip == QuickChip.all && !query.advanced.hasActive;
    final cached = MemoryCache.get<ConversationsPage>(_memoryKey(query)) ?? (unfiltered ? repo.cached(query.segment) : null);
    scheduleMicrotask(() => _load(generation));
    return ConversationsState(
      query: query,
      network: socket.currentStatus,
      items: cached?.items ?? const [],
      counts: cached?.counts ?? const {},
      nextCursor: cached?.nextCursor,
      fromCache: cached != null,
      phase: cached != null ? InboxLoadPhase.ready : InboxLoadPhase.loading,
    );
  }

  /// Per-query last page, so switching back to a chip/segment is instant.
  static String _memoryKey(InboxQuery q) => 'inbox:${q.toQueryParameters()}';

  Future<void> _load(int generation) async {
    try {
      final page = await _repo.fetch(state.query, limit: pageSize);
      if (generation != _generation) return;
      state = state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        counts: page.counts,
        phase: InboxLoadPhase.ready,
        fromCache: false,
        pageError: false,
        inserted: const {},
        // A request just succeeded: clear an earlier "no connection" banner.
        network: NetworkState.online,
      );
      _retryDelay = Duration.zero;
      MemoryCache.put(_memoryKey(state.query), page);
      if (state.query.chip == QuickChip.all && !state.query.advanced.hasActive) {
        unawaited(_repo.saveCache(state.query.segment, page));
      }
      Analytics.log('inbox_view', {
        'segment': state.query.segment.name,
        'filter': state.query.chip.name,
        'count': page.items.length,
      });
    } on ConversationsApiException catch (e) {
      if (generation != _generation) return;
      state = state.copyWith(
        phase: state.items.isEmpty ? InboxLoadPhase.error : InboxLoadPhase.ready,
        network: e.isNetwork ? NetworkState.offline : state.network,
      );
      if (e.isNetwork) _scheduleRetry(generation);
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(phase: state.items.isEmpty ? InboxLoadPhase.error : InboxLoadPhase.ready);
    }
  }

  Timer? _retryTimer;
  Duration _retryDelay = Duration.zero;

  /// Network failure (server busy / slow on start, Wi-Fi blip): try again by
  /// itself — 2 s, 4 s, 8 s … up to 30 s — instead of waiting for a pull.
  void _scheduleRetry(int generation) {
    _retryTimer?.cancel();
    final next = _retryDelay == Duration.zero ? const Duration(seconds: 2) : _retryDelay * 2;
    _retryDelay = next > const Duration(seconds: 30) ? const Duration(seconds: 30) : next;
    _retryTimer = Timer(_retryDelay, () {
      if (generation == _generation) _load(generation);
    });
  }

  /// Re-reads the loaded window after a real-time change, keeping the
  /// number of loaded rows. Newly appearing ids feed the "new" pill.
  Future<void> _refreshWindow() async {
    if (state.phase == InboxLoadPhase.loading) return;
    final generation = _generation;
    try {
      final limit = state.items.length < pageSize ? pageSize : state.items.length;
      final page = await _repo.fetch(state.query, limit: limit);
      if (generation != _generation) return;
      MemoryCache.put(_memoryKey(state.query), page);
      final before = {for (final i in state.items) i.id};
      state = state.copyWith(
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        counts: page.counts,
        phase: InboxLoadPhase.ready,
        fromCache: false,
        network: NetworkState.online,
        inserted: {
          for (final i in page.items)
            if (!before.contains(i.id)) i.id,
        },
      );
    } catch (_) {
      // Keep the current rows; the banner explains offline state.
    }
  }

  /// Pull to refresh.
  Future<void> refresh() => _load(_generation);

  /// Retry after a first-load error.
  void retry() {
    state = state.copyWith(phase: InboxLoadPhase.loading);
    _load(_generation);
  }

  /// Cursor pagination, triggered at 80% scroll.
  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.phase != InboxLoadPhase.ready) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, pageError: false);
    try {
      final page = await _repo.fetch(state.query, cursor: state.nextCursor, limit: pageSize);
      if (generation != _generation) return;
      final known = {for (final i in state.items) i.id};
      state = state.copyWith(
        items: [
          ...state.items,
          for (final i in page.items)
            if (!known.contains(i.id)) i,
        ],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        loadingMore: false,
      );
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(loadingMore: false, pageError: true);
    }
  }

  // ---- Optimistic actions ---------------------------------------------------------

  List<ConversationSummary> _pick(Set<String> ids) => [
    for (final i in state.items)
      if (ids.contains(i.id)) i,
  ];

  /// Removes rows immediately, calls the repository, rolls back on failure.
  Future<InboxActionResult> _removing(
    Set<String> ids,
    Future<UndoAction> Function(List<ConversationSummary> items) call,
  ) async {
    final items = _pick(ids);
    final snapshot = state.items;
    state = state.copyWith(
      items: [
        for (final i in state.items)
          if (!ids.contains(i.id)) i,
      ],
    );
    try {
      final undo = await call(items);
      return InboxActionResult(
        undo: () async {
          await undo();
          await _refreshWindow();
        },
      );
    } catch (_) {
      state = state.copyWith(items: snapshot);
      return const InboxActionResult(failed: true);
    }
  }

  /// Closing removes the rows from open lists; in "الكل" (every status)
  /// the refresh brings them back as closed.
  Future<InboxActionResult> resolve(Set<String> ids) async {
    final r = await _removing(ids, _repo.resolve);
    if (!r.failed) unawaited(_refreshWindow().catchError((Object _) {}));
    return r;
  }

  Future<InboxActionResult> reopen(Set<String> ids) => _refreshing(ids, _repo.reopen);

  Future<InboxActionResult> claimMany(Set<String> ids) => _refreshing(ids, _repo.claimBulk);

  /// Server first, then re-read the window (rows move between pills).
  Future<InboxActionResult> _refreshing(
    Set<String> ids,
    Future<UndoAction> Function(List<ConversationSummary> items) call,
  ) async {
    try {
      final undo = await call(_pick(ids));
      await _refreshWindow();
      return InboxActionResult(
        undo: () async {
          await undo();
          await _refreshWindow();
        },
      );
    } catch (_) {
      return const InboxActionResult(failed: true);
    }
  }

  /// Default snooze from a full swipe is 1 hour (§4.5.4).
  Future<InboxActionResult> snooze(Set<String> ids, {Duration duration = const Duration(hours: 1)}) =>
      _removing(ids, (items) => _repo.snooze(items, DateTime.now().add(duration)));

  Future<InboxActionResult> archive(Set<String> ids) => _removing(ids, _repo.archive);

  Future<InboxActionResult> claim(String id) async {
    final item = _pick({id}).firstOrNull;
    if (item != null) {
      Analytics.log('inbox_claim', {
        'wait_seconds': item.waitingSince == null ? 0 : DateTime.now().difference(item.waitingSince!).inSeconds,
      });
    }
    // Never optimistic (Claim spec §6): the row only moves once the server
    // confirms ownership; the window refresh then moves it to "لي".
    final snapshot = state.items;
    try {
      final claimedBy = await _repo.claim(id);
      if (claimedBy != null) {
        // Lost the race: remove the row and tell the agent who has it.
        state = state.copyWith(
          items: [
            for (final i in snapshot)
              if (i.id != id) i,
          ],
        );
        return InboxActionResult(claimedBy: claimedBy);
      }
      // Server confirmed: refresh so the row leaves Unassigned / joins Mine
      // and the segment counts update (Claim spec §7.1).
      unawaited(_refreshWindow().catchError((Object _) {}));
      return const InboxActionResult();
    } on ConversationsApiException catch (e) {
      state = state.copyWith(items: snapshot);
      if (e.statusCode == 403 || e.statusCode == 423) {
        unawaited(_refreshWindow().catchError((Object _) {}));
        return const InboxActionResult(forbidden: true);
      }
      return const InboxActionResult(failed: true);
    } catch (_) {
      state = state.copyWith(items: snapshot);
      return const InboxActionResult(failed: true);
    }
  }

  /// Opening a row marks it read optimistically.
  void markReadOptimistic(String id) {
    final i = state.items.indexWhere((c) => c.id == id);
    if (i < 0 || !state.items[i].isUnread) return;
    unawaited(_repo.setRead(id, read: true).catchError((_) {}));
  }

  Future<InboxActionResult> setRead(Set<String> ids, {required bool read}) async {
    try {
      final undo = await _repo.setReadBulk(_pick(ids), read: read);
      await _refreshWindow();
      return InboxActionResult(
        undo: () async {
          await undo();
          await _refreshWindow();
        },
      );
    } catch (_) {
      return const InboxActionResult(failed: true);
    }
  }

  Future<InboxActionResult> setPriority(Set<String> ids, Priority p) async {
    try {
      final undo = await _repo.setPriority(_pick(ids), p);
      await _refreshWindow();
      return InboxActionResult(undo: undo);
    } catch (_) {
      return const InboxActionResult(failed: true);
    }
  }

  Future<InboxActionResult> addTag(Set<String> ids, String tag) async {
    try {
      final undo = await _repo.addTag(_pick(ids), tag);
      await _refreshWindow();
      return InboxActionResult(undo: undo);
    } catch (_) {
      return const InboxActionResult(failed: true);
    }
  }

  // ---- Multi-select (lives on InboxState so the shell can swap the tab bar) ---

  void toggleSelected(String id) => ref.read(inboxProvider.notifier).toggleSelected(id);

  void selectAll() => ref.read(inboxProvider.notifier).setSelection({for (final i in state.items) i.id});

  void clearSelection() => ref.read(inboxProvider.notifier).clearSelection();
}

/// Tab-bar badge: every unread conversation (Inbox v2 §2), from
/// `counts.total_unread` (falls back to the older `mine_unread`).
final inboxTabBadgeProvider = Provider<int>((ref) {
  final counts = ref.watch(conversationsControllerProvider.select((s) => s.counts));
  return counts['total_unread'] ?? counts['mine_unread'] ?? 0;
});
