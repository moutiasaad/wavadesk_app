import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api_provider.dart';
import '../data/kb_api.dart';
import '../data/kb_repository.dart';
import '../domain/kb_entry.dart';
import '../domain/stale_rule.dart';
import '../../auth/application/auth_session.dart';

final kbApiProvider = Provider<KbApi>((ref) {
  return HttpKbApi(ref.watch(wdApiRequiredProvider));
});

final kbRepositoryProvider = Provider<KbRepository>(
  (ref) {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    return KbRepository(ref.watch(kbApiProvider), cacheKey: 'kb_list_cache_v1_api');
  },
);

@immutable
class KnowledgeState {
  const KnowledgeState({
    this.items = const [],
    this.drafts = const [],
    this.nextCursor,
    this.counts = const KbCounts(),
    this.unansweredCount = 0,
    this.draftsPending = 0,
    this.permissions = const KbPermissions(),
    this.type,
    this.sort = KbSort.usage,
    this.tags = const {},
    this.loaded = false,
    this.loading = false,
    this.loadingMore = false,
    this.refetching = false,
    this.error,
  });

  final List<KbEntrySummary> items;

  /// Pending suggestions (admins, §4.7).
  final List<KbEntrySummary> drafts;
  final String? nextCursor;
  final KbCounts counts;
  final int unansweredCount;
  final int draftsPending;
  final KbPermissions permissions;

  /// Stats-card filter (§4.3); null = all.
  final KbType? type;
  final KbSort sort;
  final Set<String> tags;

  /// Has data (cache or network) at least once.
  final bool loaded;
  final bool loading;
  final bool loadingMore;

  /// Type / sort / tag filter changed and its fetch hasn't answered yet:
  /// [items] still belong to the previous filter, so show row skeletons
  /// (never the old rows nor "no results").
  final bool refetching;
  final Object? error;

  bool get hasMore => nextCursor != null;
  bool get isEmptyKb => loaded && counts.total == 0 && drafts.isEmpty;

  KnowledgeState copyWith({
    List<KbEntrySummary>? items,
    List<KbEntrySummary>? drafts,
    String? Function()? nextCursor,
    KbCounts? counts,
    int? unansweredCount,
    int? draftsPending,
    KbPermissions? permissions,
    KbType? Function()? type,
    KbSort? sort,
    Set<String>? tags,
    bool? loaded,
    bool? loading,
    bool? loadingMore,
    bool? refetching,
    Object? Function()? error,
  }) =>
      KnowledgeState(
        items: items ?? this.items,
        drafts: drafts ?? this.drafts,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        counts: counts ?? this.counts,
        unansweredCount: unansweredCount ?? this.unansweredCount,
        draftsPending: draftsPending ?? this.draftsPending,
        permissions: permissions ?? this.permissions,
        type: type != null ? type() : this.type,
        sort: sort ?? this.sort,
        tags: tags ?? this.tags,
        loaded: loaded ?? this.loaded,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        refetching: refetching ?? this.refetching,
        error: error != null ? error() : this.error,
      );
}

final knowledgeControllerProvider = NotifierProvider<KbListController, KnowledgeState>(KbListController.new);

/// Knowledge Base list (spec §4): counts, filters, paging, drafts, row actions.
class KbListController extends Notifier<KnowledgeState> {
  KbApi get _api => ref.read(kbApiProvider);
  KbRepository get _repo => ref.read(kbRepositoryProvider);

  int _loadSeq = 0;
  Timer? _poll;

  /// Row id → pending delete (Undo window, §12).
  final _pendingDeletes = <String, (Timer, KbEntrySummary, int)>{};

  @override
  KnowledgeState build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    ref.onDispose(() {
      _poll?.cancel();
      _poll = null;
      for (final p in _pendingDeletes.values) {
        p.$1.cancel();
      }
      _pendingDeletes.clear();
    });
    Future.microtask(_boot);
    return const KnowledgeState(loading: true);
  }

  Future<void> _boot() async {
    final cached = await _repo.cached();
    // Rule 2 (core/state/load_state.dart): an empty cached page must not
    // show the onboarding before the network has confirmed it.
    if (cached != null && !state.loaded && (cached.items.isNotEmpty || cached.counts.total > 0)) {
      state = _fromPage(state, cached).copyWith(loaded: true);
    }
    await load();
  }

  KnowledgeState _fromPage(KnowledgeState s, KbListPage p, {bool append = false}) => s.copyWith(
        items: append ? [...s.items, ...p.items] : p.items,
        nextCursor: () => p.nextCursor,
        counts: p.counts,
        unansweredCount: p.unansweredCount,
        draftsPending: p.draftsPending,
        permissions: p.permissions,
      );

  /// (Re)loads the first page for the current filters; silent when cached.
  Future<void> load() async {
    final seq = ++_loadSeq;
    final s0 = state;
    state = state.copyWith(loading: true, error: () => null);
    try {
      final page = await _api.list(type: s0.type, sort: s0.sort, tags: s0.tags);
      if (seq != _loadSeq) return;
      var next = _fromPage(state, page).copyWith(loaded: true, loading: false, refetching: false);
      if (page.permissions.canReviewDrafts && page.draftsPending > 0) {
        next = next.copyWith(drafts: await _api.drafts().catchError((_) => <KbEntrySummary>[]));
      } else {
        next = next.copyWith(drafts: const []);
      }
      if (seq != _loadSeq) return;
      state = next;
      if (s0.type == null && s0.tags.isEmpty && s0.sort == KbSort.usage) unawaited(_repo.save(page));
      _schedulePoll();
    } catch (e) {
      if (seq != _loadSeq) return;
      state = state.copyWith(loading: false, refetching: false, error: () => e);
    }
  }

  Future<void> refresh() => load();

  /// While a file/link is processing, poll so its badge flips to ready
  /// (stands in for the `kb.file.processed` realtime event).
  void _schedulePoll() {
    _poll?.cancel();
    if (state.counts.processing == 0 && !state.items.any((e) => e.status == KbStatus.processing)) return;
    _poll = Timer(const Duration(seconds: 4), () {
      if (_pendingDeletes.isEmpty) load();
    });
  }

  Future<void> loadMore() async {
    final s = state;
    if (!s.hasMore || s.loadingMore || s.loading) return;
    state = s.copyWith(loadingMore: true);
    try {
      final page = await _api.list(type: s.type, sort: s.sort, tags: s.tags, cursor: s.nextCursor);
      state = _fromPage(state, page, append: true).copyWith(loadingMore: false);
    } catch (_) {
      state = state.copyWith(loadingMore: false);
    }
  }

  void setType(KbType? type) {
    if (type == state.type) return;
    state = state.copyWith(type: () => type, refetching: true);
    load();
  }

  void setSort(KbSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort, refetching: true);
    load();
  }

  void setTags(Set<String> tags) {
    state = state.copyWith(tags: tags, refetching: true);
    load();
  }

  /// Upsert a row from a Q&A saved in the editor (spec 13).
  void applySaved(KbQa qa) {
    final row = qa.toSummary();
    if (qa.isDraft) {
      final exists = state.drafts.any((d) => d.id == qa.id);
      state = state.copyWith(
        drafts: exists ? [for (final d in state.drafts) d.id == qa.id ? row : d] : [row, ...state.drafts],
        draftsPending: exists ? state.draftsPending : state.draftsPending + 1,
      );
      return;
    }
    final wasDraft = state.drafts.any((d) => d.id == qa.id);
    final exists = state.items.any((e) => e.id == qa.id);
    final fresh = KbEntrySummary(
      id: row.id,
      type: row.type,
      title: row.title,
      status: row.status,
      usage30d: row.usage30d,
      updatedAt: row.updatedAt,
      isStale: StaleRule.isStale(row.updatedAt),
      tags: row.tags,
      mediaCount: row.mediaCount,
    );
    final c = state.counts;
    state = state.copyWith(
      items: exists ? [for (final e in state.items) e.id == qa.id ? fresh : e] : [fresh, ...state.items],
      drafts: wasDraft ? state.drafts.where((d) => d.id != qa.id).toList() : null,
      draftsPending: wasDraft ? (state.draftsPending - 1).clamp(0, 1 << 30) : null,
      counts: exists ? null : KbCounts(total: c.total + 1, qa: c.qa + 1, file: c.file, link: c.link, processing: c.processing),
    );
  }

  /// Drop a row locally (deleted in the editor).
  /// Attachments added / removed in the editor (row subtitle shows them).
  void setMediaCount(String id, int n) {
    if (!state.items.any((e) => e.id == id)) return;
    state = state.copyWith(items: [for (final e in state.items) e.id == id ? e.copyWith(mediaCount: n) : e]);
  }

  void removeLocal(String id) {
    final row = state.items.where((e) => e.id == id).firstOrNull;
    final wasDraft = state.drafts.any((d) => d.id == id);
    state = state.copyWith(
      items: state.items.where((e) => e.id != id).toList(),
      drafts: state.drafts.where((d) => d.id != id).toList(),
      draftsPending: wasDraft ? (state.draftsPending - 1).clamp(0, 1 << 30) : null,
      counts: row == null ? null : _countsMinus(row),
    );
  }

  KbCounts _countsMinus(KbEntrySummary row, [int d = -1]) {
    final c = state.counts;
    return KbCounts(
      total: c.total + d,
      qa: c.qa + (row.type == KbType.qa ? d : 0),
      file: c.file + (row.type == KbType.file ? d : 0),
      link: c.link + (row.type == KbType.link ? d : 0),
      processing: c.processing,
    );
  }

  /// Banner count changes from the unanswered screen.
  void adjustUnanswered(int delta) => state = state.copyWith(unansweredCount: (state.unansweredCount + delta).clamp(0, 1 << 30));

  void _patchRow(String id, KbEntrySummary Function(KbEntrySummary) f) =>
      state = state.copyWith(items: [for (final e in state.items) e.id == id ? f(e) : e]);

  /// Swipe / long-press "تعطيل للذكاء" / "تفعيل". Returns false on failure (reverted).
  Future<bool> setEnabled(String id, bool enabled) async {
    final before = state.items.where((e) => e.id == id).firstOrNull;
    if (before == null) return false;
    _patchRow(id, (e) => e.copyWith(status: enabled ? KbStatus.active : KbStatus.disabled));
    try {
      await _api.setEnabled(id, enabled);
      return true;
    } catch (_) {
      _patchRow(id, (_) => before);
      return false;
    }
  }

  /// Removes the row now and deletes on the server after the Undo window.
  void deleteWithUndo(String id, {Duration window = const Duration(seconds: 5), void Function(Object error)? onError}) {
    final i = state.items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final row = state.items[i];
    state = state.copyWith(items: [...state.items]..removeAt(i), counts: _countsMinus(row));
    final timer = Timer(window, () async {
      _pendingDeletes.remove(id);
      try {
        await _api.delete(id);
      } catch (e) {
        _restore(row, i);
        onError?.call(e);
      }
    });
    _pendingDeletes[id] = (timer, row, i);
  }

  void undoDelete(String id) {
    final p = _pendingDeletes.remove(id);
    if (p == null) return;
    p.$1.cancel();
    _restore(p.$2, p.$3);
  }

  void _restore(KbEntrySummary row, int index) {
    if (state.items.any((e) => e.id == row.id)) return;
    final list = [...state.items]..insert(index.clamp(0, state.items.length), row);
    state = state.copyWith(items: list, counts: _countsMinus(row, 1));
  }

  Future<bool> approveDraft(String id) async {
    try {
      applySaved(await _api.approveDraft(id));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectDraft(String id) async {
    try {
      await _api.rejectDraft(id);
      removeLocal(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// A file/link was just created (upload / link sheet): reload to show it.
  void entryCreated() => load();
}
