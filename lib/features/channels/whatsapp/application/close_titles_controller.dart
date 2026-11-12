import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/wd_api_provider.dart';
import '../../../../core/utils/analytics.dart';
import '../data/close_titles_api.dart';
import '../data/whatsapp_api.dart' show WaApiException;

final closeTitlesApiProvider = Provider<CloseTitlesApi>((ref) => CloseTitlesApi(ref.watch(wdApiRequiredProvider)));

class CloseTitlesState {
  const CloseTitlesState({
    this.items = const [],
    this.canManage = false,
    this.missingDefaults = 0,
    this.max = 100,
    this.loading = false,
    this.loaded = false,
    this.unavailable = false,
    this.error,
  });

  final List<CloseTitleItem> items;
  final bool canManage;
  final int missingDefaults;
  final int max;
  final bool loading;
  final bool loaded;

  /// The server doesn't have the endpoint yet (404): the web page instead.
  final bool unavailable;
  final Object? error;

  CloseTitlesState copyWith({
    List<CloseTitleItem>? items,
    bool? canManage,
    int? missingDefaults,
    int? max,
    bool? loading,
    bool? loaded,
    bool? unavailable,
    Object? error,
    bool clearError = false,
  }) =>
      CloseTitlesState(
        items: items ?? this.items,
        canManage: canManage ?? this.canManage,
        missingDefaults: missingDefaults ?? this.missingDefaults,
        max: max ?? this.max,
        loading: loading ?? this.loading,
        loaded: loaded ?? this.loaded,
        unavailable: unavailable ?? this.unavailable,
        error: clearError ? null : error ?? this.error,
      );

  CloseTitlesState withPage(CloseTitlesPage p) => copyWith(
        items: p.items,
        canManage: p.canManage,
        missingDefaults: p.missingDefaults,
        max: p.max,
        loading: false,
        loaded: true,
        unavailable: false,
        clearError: true,
      );
}

final closeTitlesControllerProvider = NotifierProvider<CloseTitlesController, CloseTitlesState>(CloseTitlesController.new);

/// Closing titles (mirrors the web panel page). Kept alive so the WhatsApp
/// screen row can show the count.
class CloseTitlesController extends Notifier<CloseTitlesState> {
  CloseTitlesApi get _api => ref.read(closeTitlesApiProvider);

  @override
  CloseTitlesState build() {
    scheduleMicrotask(load);
    return const CloseTitlesState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      state = state.withPage(await _api.list());
    } on WaApiException catch (e) {
      state = e.status == 404 ? state.copyWith(loading: false, unavailable: true) : state.copyWith(loading: false, error: e);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Returns the row (an existing one for a duplicate). Throws [WaApiException].
  Future<CloseTitleItem> add(String title) async {
    final row = await _api.add(title);
    if (!state.items.any((x) => x.id == row.id)) state = state.copyWith(items: [...state.items, row]);
    Analytics.log('close_title_add');
    return row;
  }

  Future<CloseTitleItem> rename(String id, String title) async {
    final row = await _api.rename(id, title);
    state = state.copyWith(items: [for (final x in state.items) x.id == id ? row : x]);
    return row;
  }

  Future<bool> delete(String id) async {
    final before = state.items;
    state = state.copyWith(items: [for (final x in before) if (x.id != id) x]);
    try {
      await _api.delete(id);
      // A deleted default can be restored again.
      if (before.any((x) => x.id == id && x.isDefault)) state = state.copyWith(missingDefaults: state.missingDefaults + 1);
      return true;
    } catch (_) {
      state = state.copyWith(items: before);
      return false;
    }
  }

  Future<void> restoreDefaults() async => state = state.withPage(await _api.restoreDefaults());
}
