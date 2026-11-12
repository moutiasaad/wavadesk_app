import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/data.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// The app's languages, each in its own script (Login v2 §4.1 pill).
const loginLanguages = [('ar', 'العربية'), ('en', 'English'), ('fr', 'Français')];

String loginLanguageName(String code) =>
    loginLanguages.firstWhere((l) => l.$1 == code, orElse: () => loginLanguages.first).$2;

/// Radio rows; picking one switches locale + direction at once. The login
/// form keeps its text (the screen state survives the rebuild).
Future<void> showLoginLanguageSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(settingsProvider).locale.languageCode;
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.login_lang_title,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (code, label) in loginLanguages)
            AppRadioRow(
              label: label,
              selected: current == code,
              onTap: () {
                ref.read(settingsProvider.notifier).setLocale(Locale(code));
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    ),
  );
}
