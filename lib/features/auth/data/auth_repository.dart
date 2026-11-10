import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/api/wd_api.dart';
import 'auth_api.dart';

/// Session + login preferences in the platform keychain/keystore (Login spec
/// §7 Storage). Tokens and passwords are never logged.
class AuthRepository implements WdSessionStore {
  AuthRepository({required this.api, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final AuthApi api;
  final FlutterSecureStorage _storage;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kExpires = 'expires_at';
  static const _kUser = 'user';
  static const _kWorkspace = 'workspace';
  static const _kLastIdentifier = 'last_identifier';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kBiometricPrompted = 'biometric_prompted';
  static const _kDeviceId = 'device_id';
  static const _kSigning = 'signing_secret';
  static const _kSessionId = 'session_id';
  static const _kPermissions = 'permissions';

  /// Snapshot loaded at startup so the router can decide synchronously.
  Session? session;

  /// Survives an expired access token (biometric re-login uses it).
  @override
  String? refreshToken;
  String? lastIdentifier;
  bool biometricEnabled = false;
  bool biometricPrompted = false;
  String _deviceId = '';

  // ---- WdSessionStore (tokens for the signed /mobile/v1 client) ----
  @override
  String get deviceId => _deviceId;
  @override
  String? get accessToken => session?.accessToken;
  @override
  DateTime? get accessExpiresAt => session?.expiresAt.toUtc();
  @override
  String? get signingSecret => session?.signingSecret ?? _signingSecret;
  String? _signingSecret;

  @override
  Future<void> saveRefreshedTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessExpiresAt,
  }) async {
    final s = session;
    this.refreshToken = refreshToken;
    if (s != null) {
      session = Session(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: accessExpiresAt,
        user: s.user,
        workspace: s.workspace,
        signingSecret: s.signingSecret,
        sessionId: s.sessionId,
        permissions: s.permissions,
      );
    }
    await Future.wait([
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
      _storage.write(key: _kExpires, value: accessExpiresAt.toIso8601String()),
    ]);
  }

  /// Reads everything once before `runApp`. Storage errors (e.g. a keystore
  /// reset after reinstall) degrade to "signed out" instead of crashing.
  Future<void> load() async {
    try {
      final all = await _storage.readAll();
      _deviceId = all[_kDeviceId] ?? '';
      if (_deviceId.isEmpty) {
        // Never regenerated on logout: the server ties sessions to it.
        _deviceId = _uuid();
        await _storage.write(key: _kDeviceId, value: _deviceId);
      }
      refreshToken = all[_kRefresh];
      _signingSecret = all[_kSigning];
      lastIdentifier = all[_kLastIdentifier];
      biometricEnabled = all[_kBiometricEnabled] == 'true';
      biometricPrompted = all[_kBiometricPrompted] == 'true';
      final access = all[_kAccess];
      final expires = DateTime.tryParse(all[_kExpires] ?? '');
      if (access != null && refreshToken != null && expires != null) {
        session = Session(
          accessToken: access,
          refreshToken: refreshToken!,
          expiresAt: expires,
          user: _decode(all[_kUser]),
          workspace: _decode(all[_kWorkspace]),
          signingSecret: _signingSecret,
          sessionId: all[_kSessionId],
          permissions: _decode(all[_kPermissions]),
        );
      }
    } catch (_) {
      session = null;
    }
  }

  static Map<String, dynamic> _decode(String? raw) {
    if (raw == null) return const {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const {};
    }
  }

  bool get hasValidSession => session?.isValid ?? false;

  /// Signed-in user as returned by `auth/login` (`id` is `usr_…`).
  Map<String, dynamic> get user => session?.user ?? const {};

  Future<void> saveSession(Session s, {String? identifier}) async {
    // A refresh answer has no user / workspace / signing secret: keep ours.
    final prev = session;
    if (prev != null && s.user.isEmpty) {
      s = Session(
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
        expiresAt: s.expiresAt,
        user: prev.user,
        workspace: prev.workspace,
        signingSecret: s.signingSecret ?? prev.signingSecret,
        sessionId: s.sessionId ?? prev.sessionId,
        permissions: prev.permissions,
      );
    } else if (s.signingSecret == null && _signingSecret != null) {
      s = Session(
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
        expiresAt: s.expiresAt,
        user: s.user,
        workspace: s.workspace,
        signingSecret: _signingSecret,
        sessionId: s.sessionId,
        permissions: s.permissions,
      );
    }
    session = s;
    refreshToken = s.refreshToken;
    _signingSecret = s.signingSecret;
    await Future.wait([
      _storage.write(key: _kAccess, value: s.accessToken),
      _storage.write(key: _kRefresh, value: s.refreshToken),
      _storage.write(key: _kExpires, value: s.expiresAt.toIso8601String()),
      _storage.write(key: _kUser, value: jsonEncode(s.user)),
      _storage.write(key: _kWorkspace, value: jsonEncode(s.workspace)),
      _storage.write(key: _kPermissions, value: jsonEncode(s.permissions)),
      if (s.signingSecret != null) _storage.write(key: _kSigning, value: s.signingSecret),
      if (s.sessionId != null) _storage.write(key: _kSessionId, value: s.sessionId),
      // Last identifier is stored only after a successful login.
      if (identifier != null) _storage.write(key: _kLastIdentifier, value: identifier),
    ]);
    if (identifier != null) lastIdentifier = identifier;
  }

  Future<void> setBiometricEnabled(bool value) async {
    biometricEnabled = value;
    await _storage.write(key: _kBiometricEnabled, value: '$value');
  }

  Future<void> setBiometricPrompted() async {
    biometricPrompted = true;
    await _storage.write(key: _kBiometricPrompted, value: 'true');
  }

  /// §13: logout deletes tokens and the biometric flag. The last identifier
  /// and device id are kept so the form can prefill.
  Future<void> clearSession() async {
    session = null;
    refreshToken = null;
    _signingSecret = null;
    biometricEnabled = false;
    await Future.wait([
      for (final k in [_kAccess, _kRefresh, _kExpires, _kUser, _kWorkspace, _kBiometricEnabled, _kSigning, _kSessionId, _kPermissions])
        _storage.delete(key: k),
    ]);
  }

  /// Stable per-install device id (random UUID v4, kept in secure storage).
  Future<DeviceInfo> deviceInfo() async {
    final id = _deviceId;
    var model = 'unknown';
    var version = '1.0.0';
    // Device details are best-effort and capped at 2s: a slow or missing
    // plugin must never block sign-in.
    const cap = Duration(seconds: 2);
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        model = (await plugin.iosInfo.timeout(cap)).utsname.machine;
      } else if (Platform.isAndroid) {
        final a = await plugin.androidInfo.timeout(cap);
        model = '${a.manufacturer} ${a.model}';
      }
    } catch (_) {}
    try {
      version = (await PackageInfo.fromPlatform().timeout(cap)).version;
    } catch (_) {}
    return DeviceInfo(
      id: id,
      platform: kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
      model: model,
      appVersion: version,
    );
  }

  static String _uuid() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
