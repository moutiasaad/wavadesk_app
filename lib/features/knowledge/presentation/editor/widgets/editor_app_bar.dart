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
    return _StatusBarBleed(
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
                    style: t.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
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

/// The screen puts this header inside a top SafeArea, so the status-bar
/// strip above it would keep the page color: paint the brand gradient there
/// too (outside the header's own bounds; nothing else is drawn there).
class _StatusBarBleed extends StatelessWidget {
  const _StatusBarBleed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).top;
    // Not under a SafeArea (BrandHeader pads itself) or no status bar.
    if (inset == 0 || MediaQuery.paddingOf(context).top > 0) return child;
    final colors = BrandHeader.colorsOf(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -inset,
          left: 0,
          right: 0,
          height: inset + 24,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [colors.first, Color.lerp(colors.first, colors.last, 0.5)!],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
