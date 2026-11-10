import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Empty KB onboarding (spec §7): book icon, title, body, "أضف أول سؤال",
/// "رفع ملف", tip.
class KbEmptyState extends StatelessWidget {
  const KbEmptyState({super.key, required this.canEdit, required this.onAddQa, required this.onUpload});

  final bool canEdit;
  final VoidCallback onAddQa;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
                child: AppIcon(AppIcons.kb, size: AppIconSize.xl, color: c.primary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(l.kb_empty_title, style: t.h5, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(l.kb_empty_body, style: t.bodySmall.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
              if (canEdit) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: l.kb_empty_cta, icon: AppIcons.add, expand: true, onPressed: onAddQa),
                const SizedBox(height: AppSpacing.sm),
                AppButton(label: l.kb_add_file, icon: AppIcons.file, variant: AppButtonVariant.secondary, expand: true, onPressed: onUpload),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(l.kb_empty_tip, style: t.caption.copyWith(color: c.textTertiary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
