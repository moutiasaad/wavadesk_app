import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../chat/application/messages_controller.dart';
import '../../chat/data/messages_repository.dart';

/// `mark` background for search matches (Search spec §6.1, §13): `#FDF0C4`
/// light (the `searchHighlight` token), `#4A3B0B` dark.
Color searchMarkColor(AppColors c) => c.isDark ? const Color(0xFF4A3B0B) : c.searchHighlight;

@immutable
class InConversationSearchState {
  const InConversationSearchState({
    this.active = false,
    this.query = '',
    this.normalized = '',
    this.matches = const [],
    this.index = -1,
  });

  final bool active;
  final String query;

  /// [query] folded with [ArabicNormalizer] — what bubbles highlight.
  final String normalized;

  /// Matching message ids, oldest → newest.
  final List<String> matches;

  /// Into [matches]; −1 when there are none.
  final int index;

  String? get currentId => index >= 0 && index < matches.length ? matches[index] : null;
  bool get hasPrevious => index > 0;
  bool get hasNext => index >= 0 && index < matches.length - 1;

  InConversationSearchState copyWith({
    bool? active,
    String? query,
    String? normalized,
    List<String>? matches,
    int? index,
  }) => InConversationSearchState(
    active: active ?? this.active,
    query: query ?? this.query,
    normalized: normalized ?? this.normalized,
    matches: matches ?? this.matches,
    index: index ?? this.index,
  );
}

final inConversationSearchProvider = NotifierProvider.autoDispose
    .family<InConversationSearchController, InConversationSearchState, String>(InConversationSearchController.new);

/// "بحث في المحادثة" (Search spec §11): matches over this conversation's
/// locally known messages; ▲ = older, ▼ = newer.
class InConversationSearchController extends AutoDisposeFamilyNotifier<InConversationSearchState, String> {
  Timer? _debounce;
  Timer? _analytics;
  StreamSubscription<void>? _sub;

  /// Real API: server matches (`GET conversations/{id}/search`) for the
  /// current query, id → sent time, so older messages that aren't loaded
  /// yet are still found.
  Map<String, DateTime> _remote = const {};
  String _remoteFor = '';
  int _remoteSeq = 0;

  MessagesRepository get _repo => ref.read(messagesRepositoryProvider);

  @override
  InConversationSearchState build(String conversationId) {
    ref.onDispose(() {
      _debounce?.cancel();
      _analytics?.cancel();
      _sub?.cancel();
    });
    return const InConversationSearchState();
  }

  void open([String query = '']) {
    _sub ??= _repo.changes(arg).listen((_) {
      if (state.active && state.normalized.isNotEmpty) _recompute(keepCurrent: true);
    });
    state = state.copyWith(active: true);
    if (query.isNotEmpty) setQuery(query, immediate: true);
  }

  void close() {
    _debounce?.cancel();
    _analytics?.cancel();
    _sub?.cancel();
    _sub = null;
    _remote = const {};
    _remoteFor = '';
    _remoteSeq++;
    state = const InConversationSearchState();
  }

  void setQuery(String q, {bool immediate = false}) {
    state = state.copyWith(query: q);
    _debounce?.cancel();
    if (immediate) {
      _recompute();
    } else {
      _debounce = Timer(const Duration(milliseconds: 150), _recompute);
    }
  }

  static bool _searchable(Message m) =>
      m.type != MessageBubbleType.system && m.kind != MessageKind.deleted && m.text.trim().isNotEmpty;

  void _recompute({bool keepCurrent = false}) {
    final q = ArabicNormalizer.normalize(state.query);
    final local = q.isEmpty
        ? const <Message>[]
        : [
            for (final m in _repo.current(arg))
              if (_searchable(m) && ArabicNormalizer.matches(m.text, q)) m,
          ];
    final List<String> matches;
    if (!useRealApi || q.isEmpty) {
      matches = [for (final m in local) m.id];
    } else {
      if (_remoteFor != q) {
        _remote = const {};
        _fetchRemote(q);
      }
      final at = <String, DateTime>{for (final m in local) m.id: m.sentAt, ..._remote};
      matches = at.keys.toList()..sort((a, b) => at[a]!.compareTo(at[b]!));
    }
    final keep = keepCurrent ? state.currentId : null;
    final kept = keep == null ? -1 : matches.indexOf(keep);
    // A new query starts at the newest match.
    final index = kept >= 0 ? kept : matches.length - 1;
    final changed = matches.isEmpty ? null : matches[index];
    final before = state.currentId;
    state = state.copyWith(normalized: q, matches: matches, index: index);
    if (changed != null && changed != before) _jump(changed);
    _analytics?.cancel();
    if (q.isNotEmpty && !keepCurrent) {
      // Once per pause; never the query text (§15).
      _analytics = Timer(
        const Duration(milliseconds: 800),
        () => Analytics.log('search_in_conversation', {'matches': matches.length}),
      );
    }
  }

  Future<void> _fetchRemote(String q) async {
    _remoteFor = q;
    final seq = ++_remoteSeq;
    try {
      final api = ref.read(wdApiRequiredProvider);
      final r = await api.get('conversations/$arg/search', query: {'q': state.query.trim(), 'limit': 50});
      if (seq != _remoteSeq || !state.active) return;
      _remote = {
        for (final m in r.list)
          if (m['id'] != null) '${m['id']}': DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime(1970),
      };
      _recompute(keepCurrent: true);
    } catch (_) {
      // Offline / too short / 4xx: local matches only.
    }
  }

  void _jump(String messageId) => ref.read(messagesControllerProvider(arg).notifier).highlight(messageId);

  /// ▲ — the older match.
  void previous() {
    if (!state.hasPrevious) return;
    state = state.copyWith(index: state.index - 1);
    _jump(state.currentId!);
  }

  /// ▼ — the newer match.
  void next() {
    if (!state.hasNext) return;
    state = state.copyWith(index: state.index + 1);
    _jump(state.currentId!);
  }
}
