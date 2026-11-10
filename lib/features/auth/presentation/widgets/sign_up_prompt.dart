import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// Login spec §4.11: "ليس لديك حساب؟ ابدأ تجربة 7 أيام مجانًا" — centered;
/// the link part is 800 `primary` with a ≥ 48dp tap target.
class SignUpPrompt extends StatelessWidget {
  const SignUpPrompt({super.key, required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = context.text.bodySmall.copyWith(fontSize: 13.5, color: c.textSecondary);
    final l = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(l.login_no_account, style: base),
        const SizedBox(width: AppSpacing.xs),
        Semantics(
          link: true,
          enabled: onTap != null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Align(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    l.login_start_trial,
                    style: base.copyWith(fontWeight: FontWeight.w800, color: c.primary),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
