import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// §8.14. Centered column, max width 280: 72dp `primaryContainer` icon circle
/// → title `h5` → body `bodySmall` → optional medium button.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.actionVariant = AppButtonVariant.tonal,
    this.actionIcon,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppButtonVariant actionVariant;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                child: AppIcon(icon, size: AppIconSize.xl, color: c.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: t.h5, textAlign: TextAlign.center),
              if (body != null) ...[
                const SizedBox(height: 6),
                Text(
                  body!,
                  style: t.bodySmall.copyWith(color: c.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: actionLabel!, icon: actionIcon, onPressed: onAction, variant: actionVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
