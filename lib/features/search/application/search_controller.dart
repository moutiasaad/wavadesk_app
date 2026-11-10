import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../data/search_api.dart';
import '../domain/search_intent_detector.dart';
import '../domain/search_query.dart';

enum SearchStatus { idle, loading, results, empty, error }

/// Where the screen was opened from (analytics `source`).
enum SearchSource { inbox, dashboard, kb, chat, shortcut }

@immutable
class SearchArgs {
  const SearchArgs({this.initialQuery, this.scope, this.fromConversationId, this.source = SearchSource.inbox});

  final String? initialQuery;
  final SearchScope? scope;

  /// `?fromConversation=` — enables "إدراج في الرد" on KB hits.
  final String? fromConversationId;
  final SearchSource source;

  @override
  bool operator ==(Object other) =>
      other is SearchArgs &&
      other.initialQuery == initialQuery &&
      other.scope == scope &&
      other.fromConversationId == fromConversationId &&
      other.source == source;

  @override
  int get hashCode => Object.hash(initialQuery, scope, fromConversationId, source);
}

@immutable
class SearchState {
  const SearchState({
    this.text = '',
    this.scope = SearchScope.all,
    this.filters = SearchFilters.empty,
    this.status = SearchStatus.idle,
    this.results,
    this.refining = false,
    this.slow = false,
    this.offline = false,
    this.loadingMore = false,
    this.loadingScope = false,
  });

  final String text;
  final SearchScope scope;
  final SearchFilters filters;
  final SearchStatus status;
  final SearchResults? results;

  /// New request in flight while older results stay visible at 50%.
  final bool refining;

  /// > 1.5s → thin progress bar (§8).
  final bool slow;
  final bool offline;
  final bool loadingMore;

  /// Scoped page loading after a chip switch (previews already shown).
  final bool loadingScope;

  SearchState copyWith({
    String? text,
    SearchScope? scope,
    SearchFilters? filters,
    SearchStatus? status,
    SearchResults? results,
    bool clearResults = false,
    bool? refining,
    bool? slow,
    bool? offline,
    bool? loadingMore,
    bool? loadingScope,
  }) => SearchState(
    text: text ?? this.text,
    scope: scope ?? this.scope,
    filters: filters ?? this.filters,
    status: status ?? this.status,
    results: clearResults ? null : (results ?? this.results),
    refining: refining ?? this.refining,
    slow: slow ?? this.slow,
    offline: offline ?? this.offline,
    loadingMore: loadingMore ?? this.loadingMore,
    loadingScope: loadingScope ?? this.loadingScope,
  );
}

final searchControllerProvider = NotifierProvider.autoDispose.family<SearchController, SearchState, SearchArgs>(
  SearchController.new,
);

/// Debounce, stale-response guard, scope, filters, 2-minute result cache,
/// offline local fallback (Search spec §4, §8, §9).
class SearchController extends AutoDisposeFamilyNotifier<SearchState, SearchArgs> {
  static const debounce = Duration(milliseconds: 250);
  static const slowAfter = Duration(milliseconds: 1500);
  static const cacheTtl = Duration(minutes: 2);
  static const cacheSize = 20;
  static const keepQueryFor = Duration(minutes: 5);

  /// Last session, reopened within 5 min (§2 Back).
  static ({String text, SearchScope scope, SearchFilters filters, DateTime at})? _last;
  static final _cache = <String, ({SearchResults r, DateTime at})>{};

  Timer? _debounce;
  Timer? _slow;
  int _seq = 0;
  bool _disposed = false;

  SearchApi get _api => ref.read(searchApiProvider);

  @override
  SearchState build(SearchArgs args) {
    // Keep the api/index alive while the screen is open.
    ref.watch(searchApiProvider);
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      _slow?.cancel();
      _last = (text: state.text, scope: state.scope, filters: state.filters, at: DateTime.now());
    });
    final offline = ref.read(inboxProvider).network == NetworkState.offline;
    ref.listen(inboxProvider.select((s) => s.network), (_, n) {
      final off = n == NetworkState.offline;
      if (off == state.offline) return;
      state = state.copyWith(offline: off);
      if (state.status != SearchStatus.idle) _run(); // re-query with the right source
    });
    Analytics.log('search_open', {'source': args.source.name});

    var text = args.initialQuery ?? '';
    var scope = args.scope ?? SearchScope.all;
    var filters = SearchFilters.empty;
    final last = _last;
    if (args.initialQuery == null && last != null && DateTime.now().difference(last.at) < keepQueryFor) {
      text = last.text;
      if (args.scope == null) scope = last.scope;
      filters = last.filters;
    }
    if (SearchIntentDetector.longEnough(text)) scheduleMicrotask(_run);
    return SearchState(text: text, scope: scope, filters: filters, offline: offline);
  }

  SearchQuery get _query => SearchQuery(text: state.text, scope: state.scope, filters: state.filters);

  void setText(String text) {
    if (text == state.text) return;
    state = state.copyWith(text: text);
    _debounce?.cancel();
    if (!SearchIntentDetector.longEnough(text)) {
      _seq++; // drop anything in flight
      _slow?.cancel();
      state = state.copyWith(status: SearchStatus.idle, clearResults: true, refining: false, slow: false);
      return;
    }
    // While debouncing: dim real results, otherwise show the skeleton — never
    // the previous query's "no results" under the new text (load_state rule 2).
    state = state.status == SearchStatus.results
        ? state.copyWith(refining: true)
        : state.copyWith(status: SearchStatus.loading, clearResults: true);
    _debounce = Timer(debounce, _run);
  }

  /// Submit = search now (no debounce).
  void submit() {
    _debounce?.cancel();
    if (SearchIntentDetector.longEnough(state.text)) _run();
  }

  void setFilters(SearchFilters f) {
    Analytics.log('search_filter_apply', {'filters': f.activeCount});
    state = state.copyWith(filters: f);
    if (SearchIntentDetector.longEnough(state.text)) _run();
  }

  void clearFilters() => setFilters(SearchFilters.empty);

  /// §4.2: "الكل" previews already contain each section's top hits, so the
  /// chip switch shows them at once and fetches the full page behind.
  void setScope(SearchScope s) {
    if (s == state.scope) return;
    final prev = state.results;
    state = state.copyWith(scope: s);
    if (!SearchIntentDetector.longEnough(state.text)) return;
    if (prev != null && prev.query.scope == SearchScope.all && s != SearchScope.all) {
      final total = prev.totals.of(s);
      final shown = switch (s) {
        SearchScope.contacts => prev.contacts.length,
        SearchScope.messages => prev.messages.length,
        SearchScope.kb => prev.kb.length,
        SearchScope.conversations => prev.conversations.length,
        SearchScope.all => 0,
      };
      if (total <= shown) return; // everything is already here
      state = state.copyWith(loadingScope: true);
    }
    _run(keepVisible: true);
  }

  Future<void> _run({bool keepVisible = false}) async {
    _debounce?.cancel();
    final seq = ++_seq;
    final query = _query;
    final key = '${state.offline ? 'L' : 'R'}|${query.cacheKey}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < cacheTtl) {
      _apply(hit.r, query, latencyMs: 0);
      return;
    }
    final hadResults = state.results != null && !state.results!.isEmpty;
    state = state.copyWith(
      status: hadResults || keepVisible ? state.status : SearchStatus.loading,
      refining: hadResults,
      slow: false,
    );
    if (!hadResults) state = state.copyWith(status: SearchStatus.loading);
    _slow?.cancel();
    _slow = Timer(slowAfter, () {
      if (!_disposed && seq == _seq) state = state.copyWith(slow: true);
    });
    final watch = Stopwatch()..start();
    try {
      final SearchResults r;
      if (state.offline) {
        r = ref.read(searchLocalIndexProvider).search(query, local: true);
      } else {
        r = await _api.search(query);
      }
      if (_disposed || seq != _seq) return; // stale
      _cache[key] = (r: r, at: DateTime.now());
      if (_cache.length > cacheSize) _cache.remove(_cache.keys.first);
      _apply(r, query, latencyMs: watch.elapsedMilliseconds);
    } on SearchApiException catch (e) {
      if (_disposed || seq != _seq) return;
      _slow?.cancel();
      if (e.isNetwork) {
        // Fall back to the local index (§8 offline).
        final r = ref.read(searchLocalIndexProvider).search(query, local: true);
        state = state.copyWith(offline: true);
        _apply(r, query, latencyMs: watch.elapsedMilliseconds);
      } else {
        state = state.copyWith(status: SearchStatus.error, refining: false, slow: false, loadingScope: false);
      }
    } catch (_) {
      // Unexpected failure: never stay on the skeleton.
      if (_disposed || seq != _seq) return;
      _slow?.cancel();
      state = state.copyWith(status: SearchStatus.error, refining: false, slow: false, loadingScope: false);
    }
  }

  void _apply(SearchResults r, SearchQuery q, {required int latencyMs}) {
    _slow?.cancel();
    state = state.copyWith(
      results: r,
      status: r.isEmpty ? SearchStatus.empty : SearchStatus.results,
      refining: false,
      slow: false,
      loadingScope: false,
    );
    // Final per pause; never the text (§15).
    Analytics.log('search_query', {
      'len': q.text.trim().length,
      'intent': r.intent.name,
      'scope': q.scope.name,
      'latency_ms': latencyMs,
      'totals': r.totals.all,
      'offline': r.local,
    });
    if (r.isEmpty) Analytics.log('search_zero_results', {'intent': r.intent.name, 'len': q.text.trim().length});
  }

  /// Scoped lists: next page at 80% scroll (§6.7).
  Future<void> loadMore() async {
    final r = state.results;
    if (r == null || r.nextCursor == null || state.loadingMore || state.scope == SearchScope.all) return;
    final seq = _seq;
    state = state.copyWith(loadingMore: true);
    try {
      final next = state.offline
          ? ref.read(searchLocalIndexProvider).search(_query, cursor: r.nextCursor, local: true)
          : await _api.search(_query, cursor: r.nextCursor);
      if (_disposed || seq != _seq) return;
      state = state.copyWith(results: r.appendPage(next), loadingMore: false);
    } on SearchApiException {
      if (!_disposed) state = state.copyWith(loadingMore: false);
    }
  }

  void retry() => _run();

  /// Filters sheet live count.
  Future<int> countFor(SearchFilters f) async {
    final q = SearchQuery(text: state.text, scope: state.scope, filters: f);
    if (state.offline) return ref.read(searchLocalIndexProvider).search(q, local: true).totals.of(q.scope);
    try {
      return await _api.count(q);
    } on SearchApiException {
      return ref.read(searchLocalIndexProvider).search(q, local: true).totals.of(q.scope);
    }
  }

  List<Agent> get teammates => [ref.read(currentAgentProvider), ...ref.read(colleaguesProvider)];
}
