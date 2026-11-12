import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum LoginBannerKind { error, info }

/// Login v2 §5.3 banner card above the fields: radius 12, padding 12,
/// 18dp alert icon. Error = rose (`#FFF1F2` / `#FECDD3` / `#E11D48`),
/// info = blue (`#EFF4FF` / `#2563EB`). Optional inline action link.
/// Announced to screen readers as a live region.
class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({
    super.key,
    required this.message,
    this.kind = LoginBannerKind.error,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final LoginBannerKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final dark = context.colors.isDark;
    final info = kind == LoginBannerKind.info;
    final (Color bg, Color border, Color fg) = info
        ? (
            dark ? const Color(0xFF14203A) : const Color(0xFFEFF4FF),
            dark ? const Color(0xFF1E3A8A) : const Color(0xFFBFD3FE),
            dark ? const Color(0xFF93B4FD) : const Color(0xFF2563EB),
          )
        : (
            dark ? const Color(0xFF2E1219) : const Color(0xFFFFF1F2),
            dark ? const Color(0xFF5B1B2A) : const Color(0xFFFECDD3),
            dark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
          );
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AppIcon(AppIcons.warning, dp: 18, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w600, color: fg),
                  ),
                  if (actionLabel != null && onAction != null)
                    Semantics(
                      button: true,
                      child: InkWell(
                        onTap: onAction,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 36),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: 1,
                            child: Text(
                              actionLabel!,
                              style: t.buttonSmall.copyWith(color: fg, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
