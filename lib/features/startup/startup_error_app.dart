import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/l10n.dart';
import '../../core/widgets/widgets.dart';
import '../auth/presentation/widgets/app_logo_mark.dart';

/// Shown instead of the app when it cannot start talking to the server
/// (no API URL / key in the build). Users see a calm, branded message with a
/// retry and a support link; the build hint is only shown in debug builds.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => context.l10n.app_name,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _StartupErrorScreen(onRetry: onRetry),
      );
}

class _StartupErrorScreen extends StatefulWidget {
  const _StartupErrorScreen({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<_StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<_StartupErrorScreen> {
  static final _support = Uri(scheme: 'mailto', path: 'support@wavadesk.com');
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    // Let the spinner show before the app restarts (or comes back here).
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await widget.onRetry();
    if (mounted) setState(() => _retrying = false);
  }

  Future<void> _contact() async {
    try {
      await launchUrl(_support, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No mail app: the address is also written on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = context.text;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogoMark(),
                  const SizedBox(height: AppSpacing.xxxl),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: c.warningContainer, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: AppIcon(AppIcons.offline, size: AppIconSize.lg, color: c.warning),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l.startup_unavailable_title,
                    style: t.h3.copyWith(color: c.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l.startup_unavailable_body,
                    style: t.bodyMedium.copyWith(color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppButton(
                    label: l.startup_retry,
                    icon: AppIcons.retry,
                    loading: _retrying,
                    expand: true,
                    onPressed: _retry,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l.startup_contact_support,
                    icon: AppIcons.email,
                    variant: AppButtonVariant.secondary,
                    expand: true,
                    onPressed: _contact,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l.startup_unavailable_help,
                    style: t.caption.copyWith(color: c.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: c.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        l.startup_dev_hint,
                        style: t.caption.copyWith(color: c.textSecondary),
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
