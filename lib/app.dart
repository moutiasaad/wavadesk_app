import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/wd_api.dart';
import 'core/api/wd_api_provider.dart';
import 'core/data/data.dart';
import 'core/notifications/in_app_banner.dart';
import 'core/notifications/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/l10n.dart';
import 'features/auth/application/workspace_block.dart';
import 'features/auth/presentation/workspace_blocked_screen.dart';

class WavadeskApp extends ConsumerWidget {
  const WavadeskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Server messages (errors, AI replies) follow the app language.
    ref.read(wdApiProvider)?.locale = WdApi.supportedLocale(settings.locale.languageCode);
    final router = ref.watch(routerProvider);
    // Starts FCM (permission state, token sync, taps, foreground banner).
    ref.watch(pushServiceProvider);
    // Trial ended / subscription expired while signed in: one clear screen
    // instead of every request failing with 403 workspace_unavailable.
    final blocked = ref.watch(workspaceBlockProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.app_name,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        // Support up to 200% text scale (§11), never beyond.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 2.0)),
          // Foreground notification banners (Notifications spec §9.2).
          child: Stack(
            children: [
              // Kept mounted under the notice so navigation survives a re-check.
              InAppBannerHost(child: child!),
              if (blocked != null) Positioned.fill(child: WorkspaceBlockedScreen(reason: blocked)),
            ],
          ),
        );
      },
    );
  }
}
