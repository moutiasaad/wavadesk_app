import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/data/data.dart';
import '../../../core/utils/analytics.dart';
import '../../auth/application/auth_session.dart';

@immutable
class SearchHistory {
  const SearchHistory({this.recents = const [], this.openedConversations = const [], this.loaded = false});

  /// Newest first, max 8 (Search spec §5).
  final List<String> recents;

  /// Last 10 opened conversation ids, newest first ("آخر من تواصلت معهم").
  final List<String> openedConversations;
  final bool loaded;

  SearchHistory copyWith({List<String>? recents, List<String>? openedConversations, bool? loaded}) => SearchHistory(
    recents: recents ?? this.recents,
    openedConversations: openedConversations ?? this.openedConversations,
    loaded: loaded ?? this.loaded,
  );
}

final searchHistoryProvider = NotifierProvider<SearchHistoryController, SearchHistory>(SearchHistoryController.new);

/// Recent searches in secure storage, per signed-in user (they can hold
/// phone numbers). Opened conversations live in prefs (ids only).
class SearchHistoryController extends Notifier<SearchHistory> {
  static const maxRecents = 8;
  static const maxOpened = 10;
  static const _storage = FlutterSecureStorage();

  String get _user => ref.read(currentAgentProvider).id;
  String get _recentKey => 'search_recent_$_user';
  String get _openedKey => 'search_opened_$_user';

  @override
  SearchHistory build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    final opened = ref.read(sharedPrefsProvider).getStringList(_openedKey) ?? const [];
    scheduleMicrotask(_load);
    return SearchHistory(openedConversations: opened);
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _recentKey);
      final list = raw == null ? const <String>[] : [for (final s in (jsonDecode(raw) as List)) '$s'];
      state = state.copyWith(recents: list, loaded: true);
    } catch (_) {
      state = state.copyWith(loaded: true);
    }
  }

  void _save() {
    unawaited(_storage.write(key: _recentKey, value: jsonEncode(state.recents)).catchError((_) {}));
  }

  /// On submit / result tap.
  void add(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    state = state.copyWith(recents: [q, ...state.recents.where((s) => s != q)].take(maxRecents).toList());
    _save();
  }

  void remove(String query) {
    state = state.copyWith(
      recents: [
        for (final s in state.recents)
          if (s != query) s,
      ],
    );
    _save();
  }

  /// "مسح" (no confirm) — returns the list for Undo.
  List<String> clear() {
    final before = state.recents;
    Analytics.log('search_recent_clear');
    state = state.copyWith(recents: const []);
    _save();
    return before;
  }

  void restore(List<String> recents) {
    state = state.copyWith(recents: recents);
    _save();
  }

  /// ChatScreen calls this on open.
  void recordOpened(String conversationId) {
    final next = [
      conversationId,
      ...state.openedConversations.where((id) => id != conversationId),
    ].take(maxOpened).toList();
    state = state.copyWith(openedConversations: next);
    ref.read(sharedPrefsProvider).setStringList(_openedKey, next);
  }
}
