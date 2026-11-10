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
import 'core/data/settings_controller.dart' show sharedPrefsProvider;
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

  // API only: without the build config there is nothing to talk to, so say
  // so instead of starting on fake data. Run with
  // --dart-define-from-file=dart_defines/<env>.json or ship assets/config/api.json.
  await loadApiConfig();
  if (apiBaseUrl.isEmpty || apiKey.isEmpty) {
    runApp(const ApiNotConfiguredApp());
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  var version = '1.0.0';
  try {
    version = (await PackageInfo.fromPlatform()).version;
  } catch (_) {}
  final api = WdApi(baseUrl: apiBaseUrl, apiKey: apiKey, bootstrapSecret: bootstrapSecret, appVersion: version);
  final auth = AuthRepository(api: HttpAuthApi(api));
  await auth.load();
  api.session = auth;

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

/// Shown when the app was built without WAVADESK_API_URL / WAVADESK_API_KEY.
class ApiNotConfiguredApp extends StatelessWidget {
  const ApiNotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لم يتم إعداد الاتصال بالخادم.\nشغّل التطبيق مع dart_defines/<env>.json\n\n'
                  'API is not configured.\nRun with --dart-define-from-file=dart_defines/<env>.json',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
}
