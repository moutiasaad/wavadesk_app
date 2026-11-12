import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricKind { face, fingerprint }

enum BiometricResult { success, cancelled, lockedOut, unavailable }

/// Thin wrapper over `local_auth` so the UI never touches platform details.
class BiometricService {
  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Face on iOS devices with Face ID; fingerprint otherwise. Null when the
  /// device can't do biometrics (or the plugin is missing, e.g. in tests).
  Future<BiometricKind?> availableKind() async {
    if (kIsWeb) return null;
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return null;
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return null;
      if (Platform.isIOS && types.contains(BiometricType.face)) return BiometricKind.face;
      return BiometricKind.fingerprint;
    } catch (_) {
      return null;
    }
  }

  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(localizedReason: reason, biometricOnly: true);
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.temporaryLockout || LocalAuthExceptionCode.biometricLockout => BiometricResult.lockedOut,
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable => BiometricResult.unavailable,
        _ => BiometricResult.cancelled,
      };
    } catch (_) {
      return BiometricResult.unavailable;
    }
  }
}
