import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/l10n.dart';

enum SnackKind { info, success, error }

/// §8.16. Floating ink snackbar, radius 14, high elevation. 3s plain, 5s with
/// an action, persistent for errors that need action. Max one visible —
/// [ScaffoldMessenger] queues the rest.
abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackKind kind = SnackKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    bool persistent = false,
    double bottomOffset = 0,
  }) {
    final c = context.colors;
    final t = context.text;
    final messenger = ScaffoldMessenger.of(context);
    final icon = switch (kind) {
      SnackKind.info => null,
      SnackKind.success => Icon(AppIcons.resolve, size: 18, color: c.snackbarIconSuccess),
      SnackKind.error => Icon(AppIcons.alert, size: 18, color: c.snackbarIconError),
    };
    final hasAction = actionLabel != null && onAction != null;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomOffset),
        duration: persistent
            ? const Duration(days: 1)
            : (hasAction ? const Duration(seconds: 5) : const Duration(seconds: 3)),
        content: Container(
          padding: EdgeInsetsDirectional.only(
            start: AppSpacing.lg,
            end: hasAction ? AppSpacing.xs : AppSpacing.lg,
            top: 14,
            bottom: 14,
          ),
          decoration: BoxDecoration(
            color: c.snackbarBackground,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: context.shadows.high,
          ),
          child: Row(
            children: [
              if (icon != null) ...[icon, const SizedBox(width: 10)],
              Expanded(
                child: Text(message, style: t.bodyMedium.copyWith(color: c.snackbarForeground)),
              ),
              if (hasAction)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: c.isDark ? c.primary : c.accent,
                    textStyle: t.buttonSmall,
                    minimumSize: const Size(48, 36),
                  ),
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(actionLabel),
                ),
              if (persistent && !hasAction)
                IconButton(
                  tooltip: context.l10n.common_close,
                  icon: Icon(AppIcons.close, size: 18, color: c.snackbarForeground),
                  onPressed: messenger.hideCurrentSnackBar,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convenience for reversible actions: message + "تراجع".
  static void undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    double bottomOffset = 0,
  }) => show(
    context,
    message: message,
    kind: SnackKind.success,
    actionLabel: context.l10n.common_undo,
    onAction: onUndo,
    bottomOffset: bottomOffset,
  );
}
