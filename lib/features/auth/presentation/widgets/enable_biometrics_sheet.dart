import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/biometric_service.dart';

/// Login spec §8: shown once after the first password login. Not
/// dismissible by swipe — the agent must choose, and both choices continue.
/// Returns true when the agent tapped "Enable".
Future<bool> showEnableBiometricsSheet(BuildContext context, {required BiometricKind kind}) async {
  final result = await AppBottomSheet.show<bool>(
    context,
    dismissible: false,
    showClose: false,
    builder: (ctx) => _EnableBiometricsContent(kind: kind),
  );
  return result ?? false;
}

class _EnableBiometricsContent extends StatelessWidget {
  const _EnableBiometricsContent({required this.kind});

  final BiometricKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final face = kind == BiometricKind.face;
    return PopScope(
      canPop: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
              child: Icon(face ? AppIcons.scanFace : AppIcons.fingerprint, size: 28, color: c.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(l.login_bio_sheet_title, style: t.h3, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              face ? l.login_bio_sheet_body : l.login_bio_sheet_body_finger,
              style: t.bodyMedium.copyWith(color: c.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: face ? l.login_bio_sheet_enable : l.login_bio_sheet_enable_finger,
              icon: face ? AppIcons.scanFace : AppIcons.fingerprint,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: l.login_bio_sheet_later,
              variant: AppButtonVariant.text,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
