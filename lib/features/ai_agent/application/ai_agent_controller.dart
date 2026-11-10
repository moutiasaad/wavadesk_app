import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/wd_api_provider.dart';
import '../data/ai_agent_api.dart';
import '../domain/ai_agent_config.dart';

final aiAgentApiProvider = Provider<AiAgentApi>((ref) => HttpAiAgentApi(ref.watch(wdApiRequiredProvider)));

/// Outcome of one auto-saved change (the UI picks the snackbar).
enum AiSaveResult { saved, failed, conflict, offline, forbidden }

@immutable
class AiAgentState {
  const AiAgentState({this.config, this.loading = false, this.error, this.saving = 0, this.revertTick = 0, this.conflictBy});

  final AiAgentConfig? config;
  final bool loading;

  /// Load failure (full-screen error when there's no config).
  final Object? error;

  /// Patches in flight.
  final int saving;

  /// Bumped when a failed change is reverted (200ms shake, §12).
  final int revertTick;

  /// Name from the last 409 ("عدّل {name} الإعدادات للتو").
  final String? conflictBy;

  bool get offline => error is AiAgentApiException && (error! as AiAgentApiException).isNetwork;

  AiAgentState copyWith({
    AiAgentConfig? config,
    bool? loading,
    Object? error,
    bool clearError = false,
    int? saving,
    int? revertTick,
    String? conflictBy,
  }) =>
      AiAgentState(
        config: config ?? this.config,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        saving: saving ?? this.saving,
        revertTick: revertTick ?? this.revertTick,
        conflictBy: conflictBy ?? this.conflictBy,
      );
}

final aiAgentControllerProvider = NotifierProvider<AiAgentController, AiAgentState>(AiAgentController.new);

/// Load, optimistic auto-save with `version`, undo, revert, 409 handling
/// (AI Agent spec §2, §7). Writes run one after another so each PATCH
/// carries the version the previous one returned.
class AiAgentController extends Notifier<AiAgentState> {
  AiAgentApi get _api => ref.read(aiAgentApiProvider);
  Future<void> _queue = Future.value();

  /// Last server-confirmed config (what a failed change reverts to).
  AiAgentConfig? _confirmed;

  @override
  AiAgentState build() {
    scheduleMicrotask(load);
    return const AiAgentState(loading: true);
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final c = await _api.fetch();
      _confirmed = c;
      state = state.copyWith(config: c, loading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Apply [edit] at once and save the fields that changed.
  Future<AiSaveResult> apply(AiAgentConfig Function(AiAgentConfig c) edit) {
    final before = state.config;
    if (before == null) return Future.value(AiSaveResult.failed);
    final after = edit(before);
    final changes = _diff(before.editable(), after.editable());
    if (changes.isEmpty) return Future.value(AiSaveResult.saved);
    state = state.copyWith(config: after, saving: state.saving + 1);

    final done = Completer<AiSaveResult>();
    _queue = _queue.then((_) async {
      final base = _confirmed ?? before;
      try {
        final saved = await _api.patch(base.version, changes);
        _confirmed = saved;
        // Keep later optimistic edits still in flight; take server facts.
        final pending = state.saving > 1;
        state = state.copyWith(config: pending ? state.config!.copyWith(version: saved.version) : saved, saving: state.saving - 1);
        done.complete(AiSaveResult.saved);
      } on AiAgentApiException catch (e) {
        if (e.isConflict && e.current != null) {
          _confirmed = e.current;
          state = state.copyWith(config: e.current, saving: state.saving - 1, conflictBy: e.changedBy ?? '');
          done.complete(AiSaveResult.conflict);
          return;
        }
        state = state.copyWith(config: _confirmed ?? before, saving: state.saving - 1, revertTick: state.revertTick + 1);
        done.complete(e.isNetwork ? AiSaveResult.offline : (e.status == 403 ? AiSaveResult.forbidden : AiSaveResult.failed));
      } catch (_) {
        state = state.copyWith(config: _confirmed ?? before, saving: state.saving - 1, revertTick: state.revertTick + 1);
        done.complete(AiSaveResult.failed);
      }
    });
    return done.future;
  }

  /// Undo = save the previous values again (§2 "تراجع").
  Future<AiSaveResult> restore(AiAgentConfig previous) => apply(
        (c) => c.copyWith(
          enabled: previous.enabled,
          mode: previous.mode,
          tone: previous.tone,
          useCustomerName: previous.useCustomerName,
          language: previous.language,
          arabicStyle: previous.arabicStyle,
          autoReplyDelaySeconds: previous.autoReplyDelaySeconds,
          hours: previous.hours,
          handoff: previous.handoff,
          channels: previous.channels,
          customInstructions: previous.customInstructions,
          allowOutsideKb: previous.allowOutsideKb,
          confidence: previous.confidence,
        ),
      );

  /// Test chat answered once: readiness item 4 ticks locally (§5.5).
  void markTested() {
    final c = state.config;
    if (c == null || c.readiness.tested) return;
    state = state.copyWith(config: c.copyWith(readiness: c.readiness.copyWith(tested: true)));
  }

  /// Rewrite styles live on their own endpoints (spec 06 §5.4.2).
  Future<bool> addStyle(String name, String instruction) async {
    try {
      final s = await _api.createStyle(name, instruction);
      final c = state.config;
      if (c != null) state = state.copyWith(config: c.copyWith(rewriteStyles: [...c.rewriteStyles, s]));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeStyle(String id) async {
    final c = state.config;
    if (c == null) return false;
    state = state.copyWith(config: c.copyWith(rewriteStyles: [for (final s in c.rewriteStyles) if (s.id != id) s]));
    try {
      await _api.deleteStyle(id);
      return true;
    } catch (_) {
      state = state.copyWith(config: state.config!.copyWith(rewriteStyles: c.rewriteStyles));
      return false;
    }
  }

  static Map<String, Object?> _diff(Map<String, Object?> a, Map<String, Object?> b) => {
        for (final k in b.keys)
          if (jsonEncode(a[k]) != jsonEncode(b[k])) k: b[k],
      };
}
