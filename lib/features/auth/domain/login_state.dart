import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'identifier.dart';

/// Server / transport failures shown in the ErrorBanner (Login spec §7).
enum LoginErrorCode {
  invalidCredentials,
  accountDisabled,

  /// Trial ended / subscription expired: paying on the web reopens it.
  workspaceSuspended,

  /// Blocked or archived by Wavadesk: only support can reopen it.
  workspaceBlocked,
  tooManyAttempts,
  server,
  network,
}

enum LoginStatus { idle, submitting, error, success }

/// Where to go after a 200 that isn't a plain success.
enum LoginNextStep { conversations, twoFactor, workspacePicker }

@immutable
class LoginState {
  const LoginState({
    this.status = LoginStatus.idle,
    this.errorCode,
    this.lockedUntil,
    this.identifierError,
    this.passwordError,
    this.cooldown = false,
    this.errorSeq = 0,
  });

  final LoginStatus status;
  final LoginErrorCode? errorCode;

  /// Set while the account is locked (423/429); the button stays disabled
  /// and the banner counts down until this moment.
  final DateTime? lockedUntil;
  final IdentifierError? identifierError;
  final PasswordError? passwordError;

  /// Client-side rate limit: submit disabled for 1s after each attempt (§13).
  final bool cooldown;

  /// Bumped on every auth error so the form shake replays (§11).
  final int errorSeq;

  bool get submitting => status == LoginStatus.submitting;
  bool get locked => lockedUntil != null && lockedUntil!.isAfter(clock.now());
  bool get showBanner => status == LoginStatus.error && errorCode != null;

  LoginState copyWith({
    LoginStatus? status,
    LoginErrorCode? errorCode,
    bool clearError = false,
    DateTime? lockedUntil,
    bool clearLock = false,
    IdentifierError? identifierError,
    PasswordError? passwordError,
    bool clearFieldErrors = false,
    bool clearIdentifierError = false,
    bool clearPasswordError = false,
    bool? cooldown,
    int? errorSeq,
  }) => LoginState(
    status: status ?? this.status,
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
    identifierError: clearFieldErrors || clearIdentifierError ? null : (identifierError ?? this.identifierError),
    passwordError: clearFieldErrors || clearPasswordError ? null : (passwordError ?? this.passwordError),
    cooldown: cooldown ?? this.cooldown,
    errorSeq: errorSeq ?? this.errorSeq,
  );
}
