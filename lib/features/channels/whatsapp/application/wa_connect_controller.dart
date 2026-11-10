import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/analytics.dart';
import '../data/whatsapp_api.dart';
import '../domain/wa_channel.dart';
import 'whatsapp_channel_controller.dart';

enum WaConnectStep { enterPhone, code, qr, success }

class WaConnectState {
  const WaConnectState({
    this.method = WaConnectMethod.phone,
    this.step = WaConnectStep.enterPhone,
    this.session,
    this.remaining = Duration.zero,
    this.loading = false,
    this.errorCode,
    this.expired = false,
    this.backlogSynced = false,
    this.qrVersion = 0,
  });

  final WaConnectMethod method;
  final WaConnectStep step;
  final WaConnectSession? session;

  /// Countdown to [WaConnectSession.expiresAt].
  final Duration remaining;
  final bool loading;

  /// `number_taken` | `rate_limited` | `multi_device_unsupported` | `network` | other.
  final String? errorCode;
  final bool expired;
  final bool backlogSynced;

  /// Bumped on each new QR (cross-fade key).
  final int qrVersion;

  WaConnectState copyWith({
    WaConnectMethod? method,
    WaConnectStep? step,
    WaConnectSession? session,
    bool clearSession = false,
    Duration? remaining,
    bool? loading,
    String? errorCode,
    bool clearError = false,
    bool? expired,
    bool? backlogSynced,
    int? qrVersion,
  }) =>
      WaConnectState(
        method: method ?? this.method,
        step: step ?? this.step,
        session: clearSession ? null : session ?? this.session,
        remaining: remaining ?? this.remaining,
        loading: loading ?? this.loading,
        errorCode: clearError ? null : errorCode ?? this.errorCode,
        expired: expired ?? this.expired,
        backlogSynced: backlogSynced ?? this.backlogSynced,
        qrVersion: qrVersion ?? this.qrVersion,
      );
}

final waConnectControllerProvider = NotifierProvider.autoDispose<WaConnectController, WaConnectState>(WaConnectController.new);

/// Connect / reconnect (WhatsApp spec §5.1): pairing code or QR, session
/// polling every 2 s, countdowns, QR auto-refresh every 20 s.
class WaConnectController extends AutoDisposeNotifier<WaConnectState> {
  WhatsAppApi get _api => ref.read(whatsAppApiProvider);
  Timer? _tick;
  Timer? _poll;
  DateTime? _startedAt;
  bool _polling = false;

  @override
  WaConnectState build() {
    ref.onDispose(_stopTimers);
    return const WaConnectState();
  }

  void _stopTimers() {
    _tick?.cancel();
    _poll?.cancel();
    _tick = null;
    _poll = null;
  }

  void selectMethod(WaConnectMethod m) {
    if (m == state.method) return;
    _stopTimers();
    state = WaConnectState(method: m, step: m == WaConnectMethod.qr ? WaConnectStep.qr : WaConnectStep.enterPhone);
    if (m == WaConnectMethod.qr) requestQr();
  }

  void start({required String source}) {
    _startedAt = DateTime.now();
    Analytics.log('wa_reconnect_start', {'method': state.method.name, 'source': source});
  }

  /// Back from the code view to the phone field.
  void editPhone() {
    _stopTimers();
    state = state.copyWith(step: WaConnectStep.enterPhone, clearSession: true, clearError: true, expired: false);
  }

  Future<void> requestPairingCode(String phone) async {
    _stopTimers();
    state = state.copyWith(loading: true, clearError: true, expired: false);
    try {
      final s = await _api.pairingCode(phone);
      state = state.copyWith(step: WaConnectStep.code, session: s, loading: false, remaining: s.expiresAt.difference(DateTime.now()));
      _startTimers();
    } on WaApiException catch (e) {
      // 409 invalid_state = already linked; 422 = bad phone; 503 = no code.
      final code = e.isNetwork ? 'network' : (e.status == 422 ? 'invalid_phone' : (e.code ?? 'failed'));
      state = state.copyWith(loading: false, errorCode: code);
      _logResult('failed', e.code);
    }
  }

  Future<void> requestQr() async {
    _poll?.cancel();
    state = state.copyWith(loading: true, clearError: true, expired: false, step: WaConnectStep.qr);
    try {
      final s = await _api.qr();
      state = state.copyWith(session: s, loading: false, remaining: s.expiresAt.difference(DateTime.now()), qrVersion: state.qrVersion + 1);
      _startTimers();
    } on WaApiException catch (e) {
      state = state.copyWith(loading: false, errorCode: e.isNetwork ? 'network' : (e.code ?? 'failed'));
    }
  }

  void _startTimers() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkSession());
  }

  void _onTick() {
    final s = state.session;
    if (s == null) return;
    final left = s.expiresAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      if (state.method == WaConnectMethod.qr) {
        // QR refreshes itself every 20 s (§5.1).
        requestQr();
      } else {
        _stopTimers();
        state = state.copyWith(remaining: Duration.zero, expired: true, errorCode: 'code_expired');
      }
      return;
    }
    state = state.copyWith(remaining: left);
  }

  Future<void> _checkSession() async {
    final s = state.session;
    if (s == null || _polling) return;
    _polling = true;
    try {
      final r = await _api.session(s.sessionId);
      if (state.session?.sessionId != s.sessionId) return;
      switch (r.status) {
        case WaSessionStatus.waiting:
          // The gateway's QR arrives (and rotates) through the poll.
          final qr = r.qrPayload;
          if (qr != null && qr.isNotEmpty && qr != state.session?.qrPayload) {
            state = state.copyWith(session: s.withQr(qr), qrVersion: state.qrVersion + 1);
          }
        case WaSessionStatus.linked:
          _stopTimers();
          state = state.copyWith(step: WaConnectStep.success, backlogSynced: r.backlogSynced);
          _logResult('linked', null);
          unawaited(ref.read(whatsAppChannelControllerProvider.notifier).load(silent: true));
        case WaSessionStatus.expired:
          if (state.method == WaConnectMethod.qr) {
            unawaited(requestQr());
          } else {
            _stopTimers();
            state = state.copyWith(expired: true, errorCode: 'code_expired');
          }
        case WaSessionStatus.failed:
          _stopTimers();
          state = state.copyWith(errorCode: r.errorCode ?? 'failed');
          _logResult('failed', r.errorCode);
      }
    } catch (_) {
      // Transient; the next poll retries.
    } finally {
      _polling = false;
    }
  }

  void _logResult(String result, String? code) => Analytics.log('wa_reconnect_result', {
        'result': result,
        'duration_s': _startedAt == null ? null : DateTime.now().difference(_startedAt!).inSeconds,
        'error_code': ?code,
      });
}
