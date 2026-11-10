import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Shown while the OS notification permission is denied / not determined
/// (Notifications spec §4.3). ✕ hides it for 7 days.
class PushDisabledBanner extends StatelessWidget {
  const PushDisabledBanner({super.key, required this.onEnable, required this.onDismiss});

  final VoidCallback onEnable;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      padding: const EdgeInsetsDirectional.fromSTEB(14, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
      decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(AppRadius.lg + 2)),
      child: Row(
        children: [
          AppIcon(AppIcons.mute, color: c.info),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.ntf_push_off_title, style: t.listTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(l.ntf_push_off_body, style: t.bodySmall.copyWith(color: c.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton(label: l.ntf_enable, size: AppButtonSize.small, onPressed: onEnable),
          AppIconButton(
            icon: AppIcons.close,
            iconSize: 18,
            size: 36,
            iconColor: c.textSecondary,
            semanticLabel: l.ntf_dismiss,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
