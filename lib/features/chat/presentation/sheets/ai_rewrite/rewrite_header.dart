import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// ✦ tile 40 + "حسّن الرد" / subtitle + ✕ (Rewrite spec §5.1).
class RewriteHeader extends StatelessWidget {
  const RewriteHeader({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.primaryContainer, shape: BoxShape.circle),
            child: AppIcon(AppIcons.ai, color: c.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(l.rw_title, style: t.h3.copyWith(fontSize: 18, color: c.textPrimary)),
              ),
              Text(l.rw_subtitle, style: t.bodySmall.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppIconButton(
          icon: AppIcons.close,
          iconSize: 16,
          variant: AppIconButtonVariant.filled,
          semanticLabel: l.common_close,
          onPressed: onClose,
        ),
      ],
    );
  }
}
