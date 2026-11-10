import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// [ استخدم هذا الرد (flex) ] [ ↻ 52 ] (Rewrite spec §5.6).
class RewriteFooter extends StatelessWidget {
  const RewriteFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    required this.showRegenerate,
    required this.onRegenerate,
    this.atMaxVersions = false,
  });

  final String primaryLabel;

  /// `null` = disabled (loading / error / over limit).
  final VoidCallback? onPrimary;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;

  /// 5 versions reached → disabled with "وصلت للحد الأقصى من المحاولات".
  final bool atMaxVersions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(
          child: AppButton(label: primaryLabel, size: AppButtonSize.large, expand: true, onPressed: onPrimary),
        ),
        if (showRegenerate) ...[
          const SizedBox(width: AppSpacing.sm),
          _RegenerateButton(onPressed: onRegenerate, tooltip: atMaxVersions ? l.rw_max_versions : l.rw_regenerate),
        ],
      ],
    );
  }
}

/// `AppButton.secondary` square 52×52, radius 14, redo 20.
class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({required this.onPressed, required this.tooltip});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      // Disabled buttons still explain why on tap (§5.6).
      triggerMode: enabled ? TooltipTriggerMode.longPress : TooltipTriggerMode.tap,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        excludeSemantics: true,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(color: c.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(dimension: 52, child: AppIcon(AppIcons.redo, color: c.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
