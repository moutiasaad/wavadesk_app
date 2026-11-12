import 'package:clock/clock.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../data/auth_api.dart';
import '../data/biometric_service.dart';
import '../domain/identifier.dart';
import '../domain/login_state.dart';
import 'auth_session.dart';

/// Outcome handed back to the screen after a successful API call. The
/// session is NOT committed yet: the screen may show the Enable-biometrics
/// sheet first (Login spec §5 Success, §8).
sealed class LoginNext {
  const LoginNext();
}

class LoginNextSession extends LoginNext {
  const LoginNextSession(this.session, this.identifier);
  final Session session;
  final String identifier;
}

class LoginNextRoute extends LoginNext {
  const LoginNextRoute(this.step);
  final LoginNextStep step;
}

final loginControllerProvider = NotifierProvider.autoDispose<LoginController, LoginState>(LoginController.new);

class LoginController extends AutoDisposeNotifier<LoginState> {
  Timer? _lockTicker;
  Timer? _cooldown;

  @override
  LoginState build() {
    ref.onDispose(() {
      _lockTicker?.cancel();
      _cooldown?.cancel();
    });
    return const LoginState();
  }

  String get _locale => ref.read(settingsProvider).locale.languageCode;

  /// Login v2 §5.1: email only (the server rejects phone numbers), trimmed
  /// and lower-cased; the password just has to be filled in.
  static IdentifierError? emailError(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return IdentifierError.required;
    final parsed = Identifier.parse(v.toLowerCase());
    return parsed.identifier?.type == IdentifierType.email ? null : IdentifierError.invalidEmail;
  }

  static PasswordError? passwordError(String password) => password.isEmpty ? PasswordError.required : null;

  /// Validates on submit (then live, see [onIdentifierEdited]), calls the API,
  /// and maps failures to the banner states. Returns null when the screen
  /// should stay put.
  Future<LoginNext?> submit(String identifierRaw, String password) async {
    if (state.submitting || state.cooldown || state.locked) return null;

    final emailErr = emailError(identifierRaw);
    final parsed = emailErr == null
        ? Identifier.parse(identifierRaw.trim().toLowerCase())
        : (identifier: null, error: emailErr);
    final pwError = passwordError(password);
    if (parsed.error != null || pwError != null) {
      // Fresh state: drops any banner, keeps the shake counter and cooldown.
      state = LoginState(
        identifierError: parsed.error,
        passwordError: pwError,
        cooldown: state.cooldown,
        errorSeq: state.errorSeq,
      );
      return null;
    }
    final identifier = parsed.identifier!;

    Analytics.log('login_submit', {'identifier_type': identifier.type.name});
    final started = clock.now();
    state = state.copyWith(status: LoginStatus.submitting, clearError: true, clearFieldErrors: true, cooldown: true);
    _cooldown?.cancel();
    _cooldown = Timer(const Duration(seconds: 1), () => state = state.copyWith(cooldown: false));

    final repo = ref.read(authRepositoryProvider);
    try {
      final device = await repo.deviceInfo();
      final outcome = await repo.api.login(
        identifier: identifier.value,
        password: password,
        device: device,
        locale: _locale,
      );
      switch (outcome) {
        case LoginSucceeded(:final session):
          Analytics.log('login_success', {
            'method': 'password',
            'duration_ms': clock.now().difference(started).inMilliseconds,
          });
          state = state.copyWith(status: LoginStatus.success);
          return LoginNextSession(session, identifier.value);
        case LoginNeeds2fa():
          state = state.copyWith(status: LoginStatus.idle);
          return const LoginNextRoute(LoginNextStep.twoFactor);
        case LoginNeedsWorkspace():
          state = state.copyWith(status: LoginStatus.idle);
          return const LoginNextRoute(LoginNextStep.workspacePicker);
      }
    } on AuthFailure catch (f) {
      _fail(f.code, retryAfter: f.retryAfter);
      return null;
    } catch (_) {
      _fail(LoginErrorCode.server);
      return null;
    }
  }

  void _fail(LoginErrorCode code, {Duration? retryAfter}) {
    Analytics.log('login_error', {'code': code.name});
    final lockedUntil = code == LoginErrorCode.tooManyAttempts
        ? clock.now().add(retryAfter ?? const Duration(seconds: 60))
        : null;
    state = state.copyWith(
      status: LoginStatus.error,
      errorCode: code,
      lockedUntil: lockedUntil,
      errorSeq: state.errorSeq + 1,
    );
    if (lockedUntil != null) _startLockTicker();
  }

  /// Rebuilds once a second for the live countdown, then unlocks at 0.
  void _startLockTicker() {
    _lockTicker?.cancel();
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.locked) {
        state = state.copyWith(); // new instance → countdown text refreshes
      } else {
        t.cancel();
        state = state.copyWith(status: LoginStatus.idle, clearError: true, clearLock: true);
      }
    });
  }

  /// Any edit hides the banner (§5.3) — except while locked, where the
  /// countdown must stay visible. A field error shown after a submit is
  /// re-checked live and clears once the value is valid (§5.1).
  void onIdentifierEdited(String value) {
    final err = state.identifierError == null ? null : emailError(value);
    if (state.identifierError != null || (state.showBanner && !state.locked)) {
      state = state.copyWith(
        identifierError: err,
        clearIdentifierError: err == null,
        clearError: !state.locked,
        status: state.locked ? null : LoginStatus.idle,
      );
    }
  }

  void onPasswordEdited(String value) {
    final err = state.passwordError == null ? null : passwordError(value);
    if (state.passwordError != null || (state.showBanner && !state.locked)) {
      state = state.copyWith(
        passwordError: err,
        clearPasswordError: err == null,
        clearError: !state.locked,
        status: state.locked ? null : LoginStatus.idle,
      );
    }
  }

  /// Biometric login: unlock the stored refresh token, exchange it for a
  /// fresh session and sign in directly (§4.10).
  Future<BiometricResult> biometricLogin(String reason) async {
    final repo = ref.read(authRepositoryProvider);
    final token = repo.refreshToken;
    if (token == null) return BiometricResult.unavailable;
    final result = await ref.read(biometricServiceProvider).authenticate(reason);
    if (result != BiometricResult.success) return result;

    final started = clock.now();
    state = state.copyWith(status: LoginStatus.submitting, clearError: true);
    try {
      final session = await repo.api.refresh(refreshToken: token, locale: _locale);
      Analytics.log('login_success', {
        'method': 'biometric',
        'duration_ms': clock.now().difference(started).inMilliseconds,
      });
      ref.read(inboxProvider.notifier).setSegment(InboxSegment.mine);
      await ref.read(authProvider.notifier).establish(session);
      return BiometricResult.success;
    } on AuthFailure catch (f) {
      _fail(f.code, retryAfter: f.retryAfter);
      return BiometricResult.cancelled;
    }
  }

  /// Final step of a password login: lands on Conversations → لي (§1).
  Future<void> commit(LoginNextSession next) async {
    ref.read(inboxProvider.notifier).setSegment(InboxSegment.mine);
    await ref.read(authProvider.notifier).establish(next.session, identifier: next.identifier);
  }
}
