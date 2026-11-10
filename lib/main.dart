import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/api/wd_api.dart';
import 'core/api/wd_api_provider.dart';
import 'core/data/data.dart';
import 'core/notifications/push_service.dart';
import 'features/auth/application/auth_session.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Push (FCM). Android/iOS only; a failure must never block the app.
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      PushService.firebaseReady = true;
    } catch (e) {
      debugPrint('[push] Firebase init failed: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  // Sample data from assets/fake/*.json (edit those files to test scenarios).
  await MockData.load();

  // Real API when built with --dart-define=WAVADESK_API_URL=… (+ API key and
  // bootstrap secret), otherwise the simulated one (see SimulatedAuthApi).
  WdApi? api;
  if (useRealApi) {
    var version = '1.0.0';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    api = WdApi(baseUrl: apiBaseUrl, apiKey: apiKey, bootstrapSecret: bootstrapSecret, appVersion: version);
  }
  final auth = AuthRepository(api: api == null ? SimulatedAuthApi() : HttpAuthApi(api));
  await auth.load();
  api?.session = auth;

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        wdApiProvider.overrideWithValue(api),
      ],
      child: const WavadeskApp(),
    ),
  );
}
