import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
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
import 'features/startup/startup_error_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Transparent navigation bar (3-button or gesture): the tab bar / page
  // shows behind it instead of a black strip. Headers refine it per screen.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  // Western digits everywhere (times, dates): intl uses Arabic-Indic digits
  // for `ar` dates by default ("١٣:٣٥"); numbers already use 0-9.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);

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

  await _start();
}

/// Loads the API settings and starts the app. Re-run by "Try again" on the
/// startup error screen.
Future<void> _start() async {
  // API only: without the build config there is nothing to talk to, so show
  // the startup error screen instead of starting on fake data. Run with
  // --dart-define-from-file=dart_defines/<env>.json or ship assets/config/api.json.
  await loadApiConfig();
  if (apiBaseUrl.isEmpty || apiKey.isEmpty) {
    runApp(const StartupErrorApp(onRetry: _start));
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
