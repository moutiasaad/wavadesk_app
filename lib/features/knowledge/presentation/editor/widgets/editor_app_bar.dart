import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Modal app bar (Add Answer spec §4.1): ✕ · centered title · text save.
class EditorAppBar extends StatelessWidget {
  const EditorAppBar({
    super.key,
    required this.title,
    required this.onClose,
    this.saveLabel,
    this.onSave,
    this.saving = false,
    this.titleFocus,
  });

  final String title;
  final VoidCallback onClose;

  /// null hides the save button (draft review).
  final String? saveLabel;

  /// null = disabled (invalid form).
  final VoidCallback? onSave;
  final bool saving;
  final FocusNode? titleFocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            AppIconButton(
              icon: AppIcons.close,
              variant: AppIconButtonVariant.filled,
              size: 40,
              iconSize: 16,
              semanticLabel: l.kbe_close,
              onPressed: onClose,
            ),
            Expanded(
              child: Focus(
                focusNode: titleFocus,
                child: Semantics(
                  header: true,
                  child: Text(title, style: t.h4, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ),
            SizedBox(
              width: 64,
              child: saveLabel == null
                  ? null
                  : Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: saving
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: AppSpinner(size: 18, delayed: false),
                            )
                          : Semantics(
                              button: true,
                              enabled: onSave != null,
                              hint: onSave == null ? l.kbe_a11y_save_disabled : null,
                              child: TextButton(
                                onPressed: onSave,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(40, 48),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  foregroundColor: c.primary,
                                  disabledForegroundColor: c.textTertiary,
                                ),
                                child: Text(
                                  saveLabel!,
                                  style: t.buttonMedium.copyWith(color: onSave == null ? c.textTertiary : c.primary),
                                ),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
