import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../data/kb_editor_api.dart';

/// Similar / conflicting entry (Add Answer spec §4.7). Warning container,
/// radius 14, padding 10/12. Dismissible; never blocks save.
class DuplicateWarning extends StatelessWidget {
  const DuplicateWarning({
    super.key,
    this.similar,
    this.conflict,
    required this.onOpen,
    required this.onMerge,
    required this.onDismiss,
  });

  final KbSimilar? similar;
  final KbConflict? conflict;
  final ValueChanged<String> onOpen;

  /// null hides "دمج كصيغة أخرى" (e.g. no edit permission).
  final ValueChanged<String>? onMerge;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final conflict = this.conflict;
    final similar = this.similar;

    Widget link(String label, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(label, style: t.bodySmall.copyWith(color: c.textWarning, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
        );

    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.md, end: AppSpacing.xs, top: 10, bottom: AppSpacing.xs),
        decoration: BoxDecoration(color: c.warningContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AppIcon(AppIcons.warning, size: AppIconSize.sm, color: c.textWarning),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conflict != null) ...[
                    Text(l.kbe_conflict(conflict.title, conflict.reason), style: t.bodySmall.copyWith(color: c.textPrimary)),
                    Wrap(children: [link(l.kbe_view, () => onOpen(conflict.id))]),
                  ],
                  if (similar != null && similar.id != conflict?.id) ...[
                    Text(l.kbe_similar(similar.title), style: t.bodySmall.copyWith(color: c.textPrimary)),
                    Wrap(
                      children: [
                        link(l.kbe_open_it, () => onOpen(similar.id)),
                        if (onMerge != null) link(l.kbe_merge_alt, () => onMerge!(similar.id)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: l.kbe_a11y_dismiss,
              iconSize: 14,
              visualDensity: VisualDensity.compact,
              icon: AppIcon(AppIcons.close, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
