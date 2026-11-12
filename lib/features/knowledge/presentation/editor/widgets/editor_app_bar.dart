import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';

/// Modal app bar (Add Answer spec §4.1) on the brand header: glassy ✕ ·
/// centered white title · light save pill.
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
    final t = context.text;
    final l = context.l10n;
    return BrandStatusBarBleed(
      child: BrandHeader(
        padding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.md, AppSpacing.xxs, AppSpacing.sm, AppSpacing.md),
        child: SizedBox(
          height: 48,
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
                  child: Text(
                    title,
                    style: t.h5.copyWith(color: context.colors.textPrimary, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 88,
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
                              enabled: onSave != null,
                              hint: onSave == null ? l.kbe_a11y_save_disabled : null,
                              // Light pill on the brand header.
                              child: AppBarTextAction(label: saveLabel!, onPressed: onSave),
                            ),
                    ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
