import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Login v2 §4.2.6: full-bleed "إنشاء حساب جديد" band. The screen places it
/// outside the sheet's side padding so it reaches both edges; hairlines on
/// top and bottom only, transparent (the sheet gradient shows), mint when
/// pressed.
class LoginRegisterBand extends StatelessWidget {
  const LoginRegisterBand({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = c.isDark;
    final line = dark ? const Color(0xFF243036) : const Color(0xFFE9EEF2);
    final fg = dark ? const Color(0xFF5EEAD4) : const Color(0xFF0A5E5B);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: Border.symmetric(horizontal: BorderSide(color: line)),
        child: InkWell(
          onTap: onTap,
          highlightColor: dark ? const Color(0xFF0F2E2D) : const Color(0xFFECF7F6),
          splashColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(AppIcons.assign, dp: 22, color: c.primary),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: context.text.buttonLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: fg,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
