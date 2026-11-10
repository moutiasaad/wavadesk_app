import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/biometric_service.dart';

/// Login spec §4.10: secondary, large, full width, leading 20 icon.
/// Face ID → scan-face + "الدخول ببصمة الوجه"; fingerprint → "الدخول بالبصمة".
class BiometricLoginButton extends StatelessWidget {
  const BiometricLoginButton({super.key, required this.kind, required this.onPressed, this.loading = false});

  final BiometricKind kind;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final face = kind == BiometricKind.face;
    return AppButton(
      label: face ? l.login_biometric_face : l.login_biometric_finger,
      icon: face ? AppIcons.faceId : AppIcons.fingerprint,
      variant: AppButtonVariant.secondary,
      size: AppButtonSize.large,
      expand: true,
      loading: loading,
      onPressed: onPressed,
    );
  }
}
