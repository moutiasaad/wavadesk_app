import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/kb_entry.dart';
import 'knowledge_controller.dart';
import '../../auth/application/auth_session.dart';

enum UnansweredSort {
  frequency('frequency'),
  recent('recent');

  const UnansweredSort(this.wire);
  final String wire;
}

@immutable
class UnansweredState {
  const UnansweredState({
    this.items = const [],
    this.nextCursor,
    this.total = 0,
    this.sort = UnansweredSort.frequency,
    this.loaded = false,
    this.loading = false,
    this.error,
  });

  final List<KbUnanswered> items;
  final String? nextCursor;
  final int total;
  final UnansweredSort sort;
  final bool loaded;
  final bool loading;
  final Object? error;

  UnansweredState copyWith({
    List<KbUnanswered>? items,
    String? Function()? nextCursor,
    int? total,
    UnansweredSort? sort,
    bool? loaded,
    bool? loading,
    Object? Function()? error,
  }) =>
      UnansweredState(
        items: items ?? this.items,
        nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
        total: total ?? this.total,
        sort: sort ?? this.sort,
        loaded: loaded ?? this.loaded,
        loading: loading ?? this.loading,
        error: error != null ? error() : this.error,
      );
}

final unansweredControllerProvider = NotifierProvider<UnansweredController, UnansweredState>(UnansweredController.new);

/// "أسئلة بلا إجابة" (Knowledge Base spec §6.4).
class UnansweredController extends Notifier<UnansweredState> {
  int _seq = 0;
  final _pendingDismiss = <String, (Timer, KbUnanswered, int)>{};

  @override
  UnansweredState build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    ref.onDispose(() {
      for (final p in _pendingDismiss.values) {
        p.$1.cancel();
      }
      _pendingDismiss.clear();
    });
    Future.microtask(refresh);
    return const UnansweredState(loading: true);
  }

  Future<void> refresh() async {
    final seq = ++_seq;
    state = state.copyWith(loading: true, error: () => null);
    try {
      final (rows, next, total) = await ref.read(kbApiProvider).unanswered(sort: state.sort.wire);
      if (seq != _seq) return;
      state = state.copyWith(items: rows, nextCursor: () => next, total: total, loaded: true, loading: false);
    } catch (e) {
      if (seq != _seq) return;
      state = state.copyWith(loading: false, error: () => e);
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loading) return;
    try {
      final (rows, next, total) = await ref.read(kbApiProvider).unanswered(sort: state.sort.wire, cursor: cursor);
      state = state.copyWith(items: [...state.items, ...rows], nextCursor: () => next, total: total);
    } catch (_) {}
  }

  void setSort(UnansweredSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    refresh();
  }

  /// Drop a group locally and decrement the KB banner count (answered or linked).
  void resolved(String id) {
    if (!state.items.any((u) => u.id == id)) return;
    state = state.copyWith(items: state.items.where((u) => u.id != id).toList(), total: (state.total - 1).clamp(0, 1 << 30));
    ref.read(knowledgeControllerProvider.notifier).adjustUnanswered(-1);
  }

  /// "تجاهل" with Undo: removed now, dismissed on the server after [window].
  void dismissWithUndo(String id, {Duration window = const Duration(seconds: 5)}) {
    final i = state.items.indexWhere((u) => u.id == id);
    if (i < 0) return;
    final row = state.items[i];
    resolved(id);
    final timer = Timer(window, () async {
      _pendingDismiss.remove(id);
      try {
        await ref.read(kbApiProvider).dismissUnanswered(id);
      } catch (_) {
        _restore(row, i);
      }
    });
    _pendingDismiss[id] = (timer, row, i);
  }

  void undoDismiss(String id) {
    final p = _pendingDismiss.remove(id);
    if (p == null) return;
    p.$1.cancel();
    _restore(p.$2, p.$3);
  }

  void _restore(KbUnanswered row, int index) {
    if (state.items.any((u) => u.id == row.id)) return;
    state = state.copyWith(items: [...state.items]..insert(index.clamp(0, state.items.length), row), total: state.total + 1);
    ref.read(knowledgeControllerProvider.notifier).adjustUnanswered(1);
  }

  /// "ربط بإجابة موجودة": adds this wording (+ variants) as alt phrasings.
  Future<KbQa?> linkTo(String id, String kbId) async {
    try {
      final qa = await ref.read(kbApiProvider).linkUnanswered(id, kbId);
      resolved(id);
      ref.read(knowledgeControllerProvider.notifier).applySaved(qa);
      return qa;
    } catch (_) {
      return null;
    }
  }
}
