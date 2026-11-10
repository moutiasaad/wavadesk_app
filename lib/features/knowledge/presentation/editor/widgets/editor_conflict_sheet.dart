import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

enum KbeConflictChoice { viewTheirs, overwrite }

/// 409 (Add Answer spec §5): "عدّل {name} هذه الإجابة للتو" with
/// عرض نسختهم / حفظ نسختي فوقها (admins) / إلغاء.
Future<KbeConflictChoice?> showEditorConflictSheet(BuildContext context, {required String name, required bool canOverwrite}) {
  final l = context.l10n;
  return AppBottomSheet.show<KbeConflictChoice>(
    context,
    title: l.kbe_conflict_title(name),
    dismissible: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: l.kbe_view_theirs,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(KbeConflictChoice.viewTheirs),
          ),
          if (canOverwrite) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l.kbe_overwrite,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.of(ctx).pop(KbeConflictChoice.overwrite),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: l.kbe_cancel,
            variant: AppButtonVariant.text,
            size: AppButtonSize.large,
            expand: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}
