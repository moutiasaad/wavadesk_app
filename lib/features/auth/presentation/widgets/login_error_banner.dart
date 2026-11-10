import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Login spec §4.12: inline server/auth error above the fields. Error
/// container, radius 14, padding 12/14, rose border, 18 alert icon, text
/// max 3 lines, optional inline action (Retry / Manage subscription).
/// Announced to screen readers as a live region.
class LoginErrorBanner extends StatelessWidget {
  const LoginErrorBanner({super.key, required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: c.isDark ? c.errorContainer : c.metricAlertBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(AppIcons.alertTriangle, size: 18, color: c.error),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: t.bodySmall.copyWith(color: c.textError),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actionLabel != null && onAction != null)
                    Semantics(
                      button: true,
                      child: InkWell(
                        onTap: onAction,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: 1,
                            child: Text(
                              actionLabel!,
                              style: t.buttonSmall.copyWith(color: c.textError, decoration: TextDecoration.underline),
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
