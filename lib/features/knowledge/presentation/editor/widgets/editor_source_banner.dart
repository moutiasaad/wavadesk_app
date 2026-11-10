import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// Where the answer comes from (Add Answer spec §4.2): unanswered, chat or
/// draft. `surfaceVariant`, radius 14, padding 10/12, icon 16 + bodySmall.
class EditorSourceBanner extends StatelessWidget {
  const EditorSourceBanner({super.key, required this.icon, required this.text, this.iconColor, this.linkLabel, this.onLink});

  final IconData icon;
  final String text;
  final Color? iconColor;
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(color: c.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          AppIcon(icon, size: AppIconSize.sm, color: iconColor ?? c.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: t.bodySmall.copyWith(color: c.textPrimary))),
          if (linkLabel != null && onLink != null)
            TextButton(
              onPressed: onLink,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(linkLabel!, style: t.bodySmall.copyWith(color: c.textLink, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// "لديك مسودة غير محفوظة — استعادتها؟" (§5 autosave): استعادة / تجاهل.
class EditorRestoreDraftBanner extends StatelessWidget {
  const EditorRestoreDraftBanner({super.key, required this.onRestore, required this.onIgnore});

  final VoidCallback onRestore;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.xs, top: AppSpacing.xs, bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: c.infoContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.history, size: AppIconSize.sm, color: c.textInfo),
            const SizedBox(width: 10),
            Expanded(child: Text(l.kbe_restore_draft, style: t.bodySmall.copyWith(color: c.textPrimary))),
            TextButton(onPressed: onIgnore, child: Text(l.kbe_restore_ignore, style: t.bodySmall.copyWith(color: c.textSecondary))),
            TextButton(
              onPressed: onRestore,
              child: Text(l.kbe_restore_btn, style: t.bodySmall.copyWith(color: c.textLink, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
