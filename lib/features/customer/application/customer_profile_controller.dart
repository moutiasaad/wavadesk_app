import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/state/load_state.dart';
import '../../../core/utils/analytics.dart';
import '../data/contacts_api.dart';
import '../data/contacts_repository.dart';
import '../domain/contact.dart';

@immutable
class ProfileState {
  const ProfileState({
    this.contact,
    this.loading = false,
    this.error = false,
    this.offline = false,
    this.summaryLoading = false,
    this.gone = false,
  });

  final Contact? contact;

  /// No data yet → skeleton.
  final bool loading;

  /// Nothing to show and the fetch failed → full error state.
  final bool error;

  /// Showing the cached copy without network (banner "تعرض آخر نسخة محفوظة").
  final bool offline;
  final bool summaryLoading;

  /// Erased or merged away.
  final bool gone;

  ProfileState copyWith({
    Contact? contact,
    bool? loading,
    bool? error,
    bool? offline,
    bool? summaryLoading,
    bool? gone,
  }) =>
      ProfileState(
        contact: contact ?? this.contact,
        loading: loading ?? this.loading,
        error: error ?? this.error,
        offline: offline ?? this.offline,
        summaryLoading: summaryLoading ?? this.summaryLoading,
        gone: gone ?? this.gone,
      );
}

final customerProfileControllerProvider =
    NotifierProvider.autoDispose.family<CustomerProfileController, ProfileState, String>(CustomerProfileController.new);

/// Cache-first profile (Profile spec §6, §8, §9): renders the cached copy at
/// once, revalidates silently, and reacts to contact changes.
class CustomerProfileController extends AutoDisposeFamilyNotifier<ProfileState, String> {
  ContactsRepository get _repo => ref.read(contactsRepositoryProvider);

  @override
  ProfileState build(String id) {
    final sub = _repo.changes.where((c) => c == id).listen((_) => _onChanged());
    ref.onDispose(sub.cancel);
    ref.listen(inboxProvider.select((s) => s.network), (_, n) {
      if (n == NetworkState.online && state.offline) refresh();
    });
    final cached = _repo.cached(id);
    scheduleMicrotask(refresh);
    return ProfileState(contact: cached, loading: cached == null);
  }

  void _onChanged() {
    final c = _repo.cached(arg);
    if (c == null) {
      state = state.copyWith(gone: true);
    } else {
      state = state.copyWith(contact: c);
    }
  }

  Future<void> refresh() async {
    try {
      final c = await _repo.fetch(arg);
      state = ProfileState(contact: c, summaryLoading: state.summaryLoading);
    } on ContactsApiException catch (e) {
      state = state.copyWith(
        loading: false,
        error: state.contact == null,
        offline: e.isNetwork && state.contact != null,
      );
    } catch (_) {
      state = state.copyWith(loading: false, error: state.contact == null);
    }
  }

  void retry() {
    state = state.copyWith(loading: true, error: false);
    refresh();
  }

  Future<void> update(ContactEdit edit, {required int fieldsChanged}) async {
    Analytics.log('profile_edit_save', {'fields_changed': fieldsChanged});
    await _repo.update(arg, edit);
    _onChanged();
  }

  /// Returns an undo callback (snackbar "تم حظر العميل" + تراجع).
  Future<Future<void> Function()> block({String? reason}) async {
    Analytics.log('profile_block', {'reason': reason});
    await _repo.block(arg, reason: reason);
    _onChanged();
    return () async {
      await _repo.unblock(arg);
      _onChanged();
    };
  }

  Future<void> unblock() async {
    Analytics.log('profile_unblock', {'reason': null});
    await _repo.unblock(arg);
    _onChanged();
  }

  Future<void> regenerateSummary() async {
    Analytics.log('profile_ai_summary_regenerate');
    state = state.copyWith(summaryLoading: true);
    try {
      await _repo.regenerateSummary(arg);
    } finally {
      state = state.copyWith(summaryLoading: false);
      _onChanged();
    }
  }

  Future<void> merge({required String intoId, required Map<String, String> fieldChoices}) =>
      _repo.merge(arg, intoId: intoId, fieldChoices: fieldChoices);

  Future<void> erase() => _repo.erase(arg);
}

// ---- Previous conversations ---------------------------------------------------------

@immutable
class PastConversationsState {
  const PastConversationsState({
    this.items = const [],
    this.nextCursor,
    this.loading = true,
    this.loadingMore = false,
    this.channel,
    this.error = false,
  });

  final List<PastConversation> items;
  final String? nextCursor;
  final bool loading;
  final bool loadingMore;

  /// Filter from the "كل القنوات ▾" chip or a linked-channel tap.
  final Channel? channel;
  final bool error;

  bool get hasMore => nextCursor != null;
}

/// (contactId, current conversation id to exclude)
typedef PastKey = ({String contactId, String? excludeId});

final pastConversationsProvider =
    NotifierProvider.autoDispose.family<PastConversationsController, PastConversationsState, PastKey>(
  PastConversationsController.new,
);

/// Page size 10, "عرض المزيد", channel filter (Profile spec §5.9).
class PastConversationsController extends AutoDisposeFamilyNotifier<PastConversationsState, PastKey> {
  ContactsRepository get _repo => ref.read(contactsRepositoryProvider);

  String get _cacheKey => 'profile_past:${arg.contactId}:${arg.excludeId}';

  @override
  PastConversationsState build(PastKey key) {
    final sub = _repo.changes.where((c) => c == key.contactId).listen((_) => _load(state.channel));
    ref.onDispose(sub.cancel);
    scheduleMicrotask(() => _load(null));
    // Reopening the profile shows the last list at once, refreshed silently.
    return MemoryCache.get<PastConversationsState>('profile_past:${key.contactId}:${key.excludeId}') ??
        const PastConversationsState();
  }

  Future<void> _load(Channel? channel) async {
    try {
      final page = await _repo.conversations(arg.contactId, channel: channel, excludeId: arg.excludeId);
      state = PastConversationsState(items: page.items, nextCursor: page.nextCursor, loading: false, channel: channel);
      if (channel == null) MemoryCache.put(_cacheKey, state);
    } catch (_) {
      // A failed refresh keeps the rows already on screen.
      state = state.items.isNotEmpty && state.channel == channel
          ? PastConversationsState(items: state.items, nextCursor: state.nextCursor, loading: false, channel: channel)
          : PastConversationsState(loading: false, channel: channel, error: true);
    }
  }

  void setChannel(Channel? channel) {
    state = PastConversationsState(channel: channel);
    _load(channel);
  }

  void retry() => setChannel(state.channel);

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    state = PastConversationsState(
      items: state.items,
      nextCursor: state.nextCursor,
      loading: false,
      loadingMore: true,
      channel: state.channel,
    );
    try {
      final page = await _repo.conversations(
        arg.contactId,
        channel: state.channel,
        excludeId: arg.excludeId,
        cursor: state.nextCursor,
      );
      state = PastConversationsState(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        loading: false,
        channel: state.channel,
      );
    } catch (_) {
      state = PastConversationsState(items: state.items, nextCursor: state.nextCursor, loading: false, channel: state.channel);
    }
  }
}
