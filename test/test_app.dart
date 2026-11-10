import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wavadesk/app.dart';
import 'package:wavadesk/core/data/data.dart';
import 'package:wavadesk/features/auth/application/auth_session.dart';
import 'package:wavadesk/features/auth/data/auth_api.dart';
import 'package:wavadesk/features/auth/data/auth_repository.dart';

/// Secure-storage values for an already signed-in user.
Map<String, String> signedInStorage() => {
      'access_token': 'sim-access-test',
      'refresh_token': 'sim-refresh-test',
      'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'user': '{"id":"u_1","name":"أحمد"}',
      'workspace': '{"id":"w_1"}',
    };

/// Boots the real app with mocked prefs + secure storage.
Future<ProviderContainer> bootApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Map<String, String> secure = const {},
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await MockData.load();
  SharedPreferences.setMockInitialValues(prefs);
  PackageInfo.setMockInitialValues(
    appName: 'Wavadesk',
    packageName: 'com.wavadesk',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  FlutterSecureStorage.setMockInitialValues(Map.of(secure));
  final sp = await SharedPreferences.getInstance();
  final auth = AuthRepository(api: SimulatedAuthApi());
  await auth.load();

  final container = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(sp),
    authRepositoryProvider.overrideWithValue(auth),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const WavadeskApp()));
  await tester.pump(const Duration(seconds: 1));
  return container;
}

/// Unmounts the app and lets controller timers drain.
Future<void> tearDownApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 15));
}
