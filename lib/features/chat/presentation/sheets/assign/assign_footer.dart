import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import 'assign_note_field.dart';

/// Pinned footer: note · primary (dynamic label, 120ms cross-fade) ·
/// "إلغاء الإسناد" · offline helper (Assign spec §5.9, §5.10, §6).
class AssignFooter extends StatelessWidget {
  const AssignFooter({
    super.key,
    required this.note,
    required this.label,
    required this.onPrimary,
    required this.loading,
    required this.offline,
    this.onUnassign,
  });

  final TextEditingController note;
  final String label;
  final VoidCallback? onPrimary;
  final bool loading;
  final bool offline;
  final VoidCallback? onUnassign;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        AssignNoteField(controller: note, enabled: !loading),
        const SizedBox(height: 14),
        if (offline)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(AppIcons.wifiOff, size: 14, color: c.textWarning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(l.as_offline, style: context.text.caption.copyWith(color: c.textWarning)),
                ),
              ],
            ),
          ),
        Semantics(
          liveRegion: true,
          child: AnimatedSwitcher(
            duration: AppMotion.reduced(context) ? Duration.zero : const Duration(milliseconds: 120),
            child: AppButton(
              key: ValueKey(label),
              label: label,
              size: AppButtonSize.large,
              expand: true,
              loading: loading,
              onPressed: offline ? null : onPrimary,
            ),
          ),
        ),
        if (onUnassign != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: AppButton(
              label: l.as_unassign,
              variant: AppButtonVariant.text,
              size: AppButtonSize.medium,
              expand: true,
              textStyle: TextStyle(color: c.textSecondary),
              onPressed: loading || offline ? null : onUnassign,
            ),
          ),
      ],
    );
  }
}
