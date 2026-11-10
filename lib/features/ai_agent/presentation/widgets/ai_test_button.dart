import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Dark full-width "اختبر الوكيل بمحادثة تجريبية" (AI Agent spec §4.9).
/// Always enabled — it tests the saved config even with the AI off.
class AiTestButton extends StatelessWidget {
  const AiTestButton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AppButton(
          label: context.l10n.ai_test,
          icon: AppIcons.conversation,
          variant: AppButtonVariant.dark,
          size: AppButtonSize.large,
          expand: true,
          onPressed: () => context.push(Routes.aiAgentTest),
        ),
      );
}
