import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/wd_api_provider.dart';
import '../../../../core/utils/analytics.dart';
import '../data/quick_replies_api.dart';
import '../data/whatsapp_api.dart' show WaApiException;
import 'whatsapp_channel_controller.dart';

final quickRepliesApiProvider = Provider<QuickRepliesApi>((ref) => HttpQuickRepliesApi(ref.watch(wdApiRequiredProvider)));

class QuickRepliesState {
  const QuickRepliesState({this.items = const [], this.loading = false, this.loaded = false, this.error});

  /// Every scope, in display order.
  final List<WaQuickReply> items;
  final bool loading;
  final bool loaded;
  final Object? error;

  List<WaQuickReply> of(QuickReplyScope s) => [for (final r in items) if (r.scope == s) r];

  QuickRepliesState copyWith({List<WaQuickReply>? items, bool? loading, bool? loaded, Object? error, bool clearError = false}) => QuickRepliesState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loaded: loaded ?? this.loaded,
        error: clearError ? null : error ?? this.error,
      );
}

final quickRepliesControllerProvider = NotifierProvider<QuickRepliesController, QuickRepliesState>(QuickRepliesController.new);

/// Saved replies (WhatsApp spec §5.4). Also feeds the chat composer's `/`
/// panel through `quickRepliesProvider`.
class QuickRepliesController extends Notifier<QuickRepliesState> {
  QuickRepliesApi get _api => ref.read(quickRepliesApiProvider);

  @override
  QuickRepliesState build() {
    scheduleMicrotask(load);
    return const QuickRepliesState(loading: true);
  }

  /// Before the first answer the screen shows a skeleton; afterwards a
  /// reload keeps the rows (a failure leaves [QuickRepliesState.error] set).
  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final rows = await _api.list();
      state = state.copyWith(items: rows, loading: false, loaded: true);
      _syncCount();
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  void _syncCount() {
    // The channel row shows the count; keep it in step (without loading the
    // channel just because the composer read the replies).
    if (!ref.exists(whatsAppChannelControllerProvider)) return;
    ref.read(whatsAppChannelControllerProvider.notifier).setQuickRepliesCount(state.items.length);
  }

  /// Create (empty id) or update. Throws [WaApiException] (`shortcut_taken`…).
  Future<WaQuickReply> save(WaQuickReply r) async {
    final isNew = r.id.isEmpty;
    final saved = isNew ? await _api.create(r) : await _api.update(r);
    state = state.copyWith(
      items: isNew ? [saved, ...state.items] : [for (final x in state.items) x.id == saved.id ? saved : x],
    );
    Analytics.log('wa_quick_reply_save', {'scope': saved.scope.name});
    _syncCount();
    return saved;
  }

  Future<bool> delete(String id) async {
    final before = state.items;
    final row = before.where((x) => x.id == id).firstOrNull;
    state = state.copyWith(items: [for (final x in before) if (x.id != id) x]);
    try {
      await _api.delete(id);
      Analytics.log('wa_quick_reply_delete', {'scope': row?.scope.name});
      _syncCount();
      return true;
    } catch (_) {
      state = state.copyWith(items: before);
      return false;
    }
  }

  /// Long-press drag within one scope.
  Future<bool> reorder(QuickReplyScope scope, int oldIndex, int newIndex) async {
    final list = state.of(scope);
    if (oldIndex < 0 || oldIndex >= list.length) return true;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), moved);
    final before = state.items;
    final others = [for (final r in before) if (r.scope != scope) r];
    state = state.copyWith(items: scope == QuickReplyScope.team ? [...list, ...others] : [...others, ...list]);
    try {
      await _api.reorder([for (final r in list) r.id]);
      return true;
    } on WaApiException {
      state = state.copyWith(items: before);
      return false;
    } catch (_) {
      state = state.copyWith(items: before);
      return false;
    }
  }
}
