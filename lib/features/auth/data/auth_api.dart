import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/api/wd_api.dart';

import '../domain/login_state.dart';

export '../../../core/api/wd_api.dart' show apiBaseUrl;

@immutable
class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.platform,
    required this.model,
    required this.appVersion,
    this.pushToken,
  });

  final String id;
  final String platform;
  final String model;
  final String appVersion;
  final String? pushToken;

  /// `device` object of `POST auth/login` (device_id must equal X-Device-Id).
  Map<String, Object?> toJson() => {
    'device_id': id,
    'name': model,
    'model': model,
    'os_version': platform,
    'app_version': appVersion,
  };
}

@immutable
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
    required this.workspace,
    this.signingSecret,
    this.sessionId,
    this.permissions = const {},
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Map<String, dynamic> user;
  final Map<String, dynamic> workspace;

  /// `device_signing_secret` from login; signs every authenticated call.
  final String? signingSecret;
  final String? sessionId;
  final Map<String, dynamic> permissions;

  bool get isValid => expiresAt.isAfter(DateTime.now());

  factory Session.fromResponse(Map<String, dynamic> json) => Session(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresAt: json.containsKey('access_expires_at')
        ? WdApi.expiryOf(json)
        : DateTime.now().add(Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 3600)),
    user: Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
    workspace: Map<String, dynamic>.from(json['workspace'] as Map? ?? const {}),
    signingSecret: json['device_signing_secret'] as String?,
    sessionId: json['session_id'] as String?,
    permissions: Map<String, dynamic>.from(json['permissions'] as Map? ?? const {}),
  );
}

/// Result of a login call that reached the server and returned 200.
sealed class LoginOutcome {
  const LoginOutcome();
}

class LoginSucceeded extends LoginOutcome {
  const LoginSucceeded(this.session);
  final Session session;
}

class LoginNeeds2fa extends LoginOutcome {
  const LoginNeeds2fa(this.tempToken);
  final String tempToken;
}

class LoginNeedsWorkspace extends LoginOutcome {
  const LoginNeedsWorkspace(this.workspaces);
  final List<Map<String, dynamic>> workspaces;
}

/// Any non-200 or transport failure.
class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.retryAfter});

  final LoginErrorCode code;
  final Duration? retryAfter;

  @override
  String toString() => 'AuthFailure($code)'; // never includes credentials
}

abstract interface class AuthApi {
  Future<LoginOutcome> login({
    required String identifier,
    required String password,
    required DeviceInfo device,
    required String locale,
  });

  /// Exchanges a stored refresh token for a new session (biometric login).
  Future<Session> refresh({required String refreshToken, required String locale});
}

/// Real client: Laravel `/mobile/v1/auth/*` (bootstrap-signed).
class HttpAuthApi implements AuthApi {
  HttpAuthApi(this._api);

  final WdApi _api;

  Future<Map<String, dynamic>> _post(String path, Map<String, Object?> body, String locale) async {
    _api.locale = WdApi.supportedLocale(locale);
    try {
      return (await _api.post(path, body: body, bootstrap: true)).map;
    } on WdApiException catch (e) {
      throw switch (e.code) {
        'network' => const AuthFailure(LoginErrorCode.network),
        'invalid_credentials' ||
        'invalid_refresh_token' ||
        'token_reused' ||
        'validation_failed' => const AuthFailure(LoginErrorCode.invalidCredentials),
        'workspace_unavailable' => switch (e.details['reason']) {
          'workspace_blocked' || 'workspace_archived' => const AuthFailure(LoginErrorCode.workspaceBlocked),
          _ => const AuthFailure(LoginErrorCode.workspaceSuspended),
        },
        'account_disabled' ||
        'account_archived' ||
        'role_forbidden' => const AuthFailure(LoginErrorCode.accountDisabled),
        'too_many_attempts' || 'rate_limited' => AuthFailure(
          LoginErrorCode.tooManyAttempts,
          retryAfter: e.retryAfter ?? const Duration(seconds: 60),
        ),
        _ => const AuthFailure(LoginErrorCode.server),
      };
    }
  }

  @override
  Future<LoginOutcome> login({
    required String identifier,
    required String password,
    required DeviceInfo device,
    required String locale,
  }) async {
    final json = await _post('auth/login', {
      'identifier': identifier,
      'password': password,
      'device': device.toJson(),
    }, locale);
    if (json['requires_2fa'] == true) {
      return LoginNeeds2fa((json['challenge_token'] ?? '') as String);
    }
    return LoginSucceeded(Session.fromResponse(json));
  }

  @override
  Future<Session> refresh({required String refreshToken, required String locale}) async {
    final json = await _post('auth/refresh', {'refresh_token': refreshToken}, locale);
    // Refresh never returns the user or a new signing secret: keep the stored ones.
    return Session.fromResponse(json);
  }
}
