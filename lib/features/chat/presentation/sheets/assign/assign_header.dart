import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// "إسناد المحادثة" / "إسناد {n} محادثات" + "المسؤول الحالي: {name}" + ✕
/// (Assign spec §5.1).
class AssignHeader extends StatelessWidget {
  const AssignHeader({super.key, required this.title, this.subtitle, required this.onClose, this.focusNode});

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  /// Initial focus on the title (§11).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              focusNode: focusNode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title, style: t.h3.copyWith(fontSize: 18, color: c.textPrimary)),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: t.bodySmall.copyWith(color: c.textSecondary), maxLines: 1),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: AppIcons.close,
            iconSize: 16,
            variant: AppIconButtonVariant.filled,
            semanticLabel: context.l10n.common_close,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
