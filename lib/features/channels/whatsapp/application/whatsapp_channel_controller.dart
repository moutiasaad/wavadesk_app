import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/wd_api_provider.dart';
import '../../../../core/data/data.dart';
import '../../../../core/models/models.dart';
import '../data/whatsapp_api.dart';
import '../domain/wa_channel.dart';
import '../domain/wa_status.dart';
import '../../../auth/application/auth_session.dart';

final whatsAppApiProvider = Provider<WhatsAppApi>((ref) => HttpWhatsAppApi(ref.watch(wdApiRequiredProvider)));

enum WaSaveResult { saved, failed, forbidden, offline, handledByAi }

class WaChannelState {
  const WaChannelState({this.channel, this.loading = false, this.error, this.offline = false, this.refreshing = false, this.statusFlash = 0});

  final WaChannel? channel;
  final bool loading;
  final Object? error;

  /// The last fetch failed for lack of network: show the cached copy with
  /// "آخر تحديث {t}" (§7 Offline).
  final bool offline;

  /// ⋮ "تحديث الحالة" / "تحقق مجددًا" in flight.
  final bool refreshing;

  /// Bumped when the status changes, so the card can flash its border (§12).
  final int statusFlash;

  WaChannelState copyWith({
    WaChannel? channel,
    bool? loading,
    Object? error,
    bool clearError = false,
    bool? offline,
    bool? refreshing,
    int? statusFlash,
  }) =>
      WaChannelState(
        channel: channel ?? this.channel,
        loading: loading ?? this.loading,
        error: clearError ? null : error ?? this.error,
        offline: offline ?? this.offline,
        refreshing: refreshing ?? this.refreshing,
        statusFlash: statusFlash ?? this.statusFlash,
      );
}

final whatsAppChannelControllerProvider = NotifierProvider<WhatsAppChannelController, WaChannelState>(WhatsAppChannelController.new);

/// Status load + 30 s polling while the screen is visible + optimistic
/// patches of auto messages / advanced toggles (WhatsApp spec §7, §8).
class WhatsAppChannelController extends Notifier<WaChannelState> {
  WhatsAppApi get _api => ref.read(whatsAppApiProvider);
  Timer? _poll;
  int _watchers = 0;

  /// Last server-confirmed channel (what a failed patch reverts to).
  WaChannel? _confirmed;

  @override
  WaChannelState build() {
    // A new sign-in starts over: never show the previous account's data.
    ref.watch(authProvider);
    _confirmed = null;
    ref.onDispose(() {
      _poll?.cancel();
      _poll = null;
    });
    scheduleMicrotask(load);
    return const WaChannelState(loading: true);
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(loading: state.channel == null, clearError: true);
    try {
      _set(await _api.fetch());
      state = state.copyWith(loading: false, clearError: true, offline: false);
    } on WaApiException catch (e) {
      state = state.copyWith(loading: false, error: state.channel == null ? e : null, offline: e.isNetwork);
    } catch (e) {
      state = state.copyWith(loading: false, error: state.channel == null ? e : null);
    }
  }

  void _set(WaChannel c) {
    final prev = state.channel;
    _confirmed = c;
    final changed = prev != null && prev.status != c.status;
    state = state.copyWith(channel: c, statusFlash: changed ? state.statusFlash + 1 : null);
    _syncLegacy(c);
  }

  /// Keeps the old `whatsappProvider` (Account row, Channels screen) in step.
  void _syncLegacy(WaChannel c) {
    ref.read(whatsappProvider.notifier).sync(
          WhatsAppConnection(
            connected: c.status.isHealthy,
            phoneNumber: c.phone == null ? null : formatWaPhone(c.phone),
            displayName: c.displayName,
            connectedSince: c.linkedAt,
            messagesToday: c.statsToday.messages,
          ),
        );
  }

  /// The screen calls these from initState / dispose (poll only while visible).
  void startPolling() {
    _watchers++;
    _poll ??= Timer.periodic(const Duration(seconds: 30), (_) => load(silent: true));
  }

  void stopPolling() {
    _watchers = (_watchers - 1).clamp(0, 1 << 20);
    if (_watchers == 0) {
      _poll?.cancel();
      _poll = null;
    }
  }

  Future<void> refreshStatus() async {
    state = state.copyWith(refreshing: true);
    try {
      _set(await _api.refreshStatus());
      state = state.copyWith(offline: false);
    } on WaApiException catch (e) {
      state = state.copyWith(offline: e.isNetwork);
    } catch (_) {
      // Keep what we have.
    } finally {
      state = state.copyWith(refreshing: false);
    }
  }

  Future<WaSaveResult> _optimistic(WaChannel Function(WaChannel c) edit, Future<WaChannel> Function(WaChannel after) send) async {
    final before = state.channel;
    if (before == null) return WaSaveResult.failed;
    final after = edit(before);
    state = state.copyWith(channel: after);
    try {
      _set(await send(after));
      return WaSaveResult.saved;
    } on WaApiException catch (e) {
      state = state.copyWith(channel: _confirmed ?? before);
      if (e.handledByAi) {
        // The AI took over after-hours meanwhile: show that state.
        unawaited(load(silent: true));
        return WaSaveResult.handledByAi;
      }
      if (e.isNetwork) return WaSaveResult.offline;
      return e.status == 403 ? WaSaveResult.forbidden : WaSaveResult.failed;
    } catch (_) {
      state = state.copyWith(channel: _confirmed ?? before);
      return WaSaveResult.failed;
    }
  }

  Future<WaSaveResult> saveWelcome(WaWelcome w) =>
      _optimistic((c) => c.copyWith(welcome: w), (_) => _api.patchAutoMessages(welcome: w));

  Future<WaSaveResult> saveAway(WaAway a) => _optimistic((c) => c.copyWith(away: a), (_) => _api.patchAutoMessages(away: a));

  Future<WaSaveResult> saveAdvanced(WaAdvanced a) => _optimistic((c) => c.copyWith(advanced: a), (_) => _api.patchAdvanced(a));

  /// Throws [WaApiException] (the dialog shows the error).
  Future<void> disconnect(String last4) async {
    await _api.disconnect(last4);
    final c = state.channel;
    if (c != null) {
      _set(c.copyWith(status: WaStatus.disconnected, statusSince: DateTime.now()));
    }
    unawaited(load(silent: true));
  }

  Future<void> notifyAdmin() => _api.notifyAdmin();

  /// Quick replies changed on their own screen.
  void setQuickRepliesCount(int n) {
    final c = state.channel;
    if (c != null && c.quickRepliesCount != n) state = state.copyWith(channel: c.copyWith(quickRepliesCount: n));
  }
}
