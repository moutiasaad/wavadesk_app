import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';
import 'app_button.dart';

enum DialogSeverity { destructive, warning, info }

/// §8.19 — only for destructive or irreversible actions (block customer,
/// disconnect WhatsApp, delete KB entry, log out). Reversible actions use an
/// Undo snackbar instead.
abstract final class AppDialog {
  /// Returns true when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    IconData? icon,
    DialogSeverity severity = DialogSeverity.destructive,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (ctx) =>
          _ConfirmDialog(
            title: title,
            body: body,
            confirmLabel: confirmLabel,
            icon: icon,
            severity: severity,
            cancelLabel: cancelLabel,
          ),
    );
    return result ?? false;
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.severity,
    this.cancelLabel,
    this.icon,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final IconData? icon;
  final DialogSeverity severity;

  /// Defaults to "إلغاء".
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final width = MediaQuery.sizeOf(context).width - 48;
    final (Color iconBg, Color iconFg) = switch (severity) {
      DialogSeverity.destructive => (c.errorContainer, c.textError),
      DialogSeverity.warning => (c.warningContainer, c.textWarning),
      DialogSeverity.info => (c.primaryContainer, c.primary),
    };

    return Dialog(
      backgroundColor: c.surfaceElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.clamp(0, 360)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, size: 22, color: iconFg),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Semantics(
                header: true,
                child: Text(title, style: t.h4, textAlign: TextAlign.center),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: t.bodyMedium.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: confirmLabel,
                expand: true,
                size: AppButtonSize.large,
                variant: severity == DialogSeverity.destructive
                    ? AppButtonVariant.destructiveFilled
                    : AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: cancelLabel ?? context.l10n.common_cancel,
                expand: true,
                size: AppButtonSize.large,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
