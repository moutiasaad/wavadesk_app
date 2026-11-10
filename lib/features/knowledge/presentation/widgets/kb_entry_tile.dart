import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';
import '../../domain/kb_subtitle_formatter.dart';

/// Icon tile colors per type (Knowledge Base spec §4.3 / §4.6, dark §11).
class KbTypeVisual {
  const KbTypeVisual(this.icon, this.background, this.foreground);

  final IconData icon;
  final Color background;
  final Color foreground;

  static KbTypeVisual of(BuildContext context, KbType type, {bool draft = false}) {
    final c = context.colors;
    final dark = c.isDark;
    if (draft) return KbTypeVisual(AppIcons.edit, c.surfaceVariant, c.textSecondary);
    return switch (type) {
      KbType.qa => KbTypeVisual(AppIcons.kb, dark ? const Color(0xFF0F2E2D) : c.primaryContainer, dark ? const Color(0xFF2BB8AD) : c.primary),
      KbType.file => KbTypeVisual(AppIcons.file, dark ? const Color(0xFF13203A) : const Color(0xFFEFF4FF), dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
      KbType.link => KbTypeVisual(AppIcons.link, dark ? const Color(0xFF2E2110) : const Color(0xFFFEF3E2), dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
    };
  }

  static String label(BuildContext context, KbType type) {
    final l = context.l10n;
    return switch (type) { KbType.qa => l.kb_qa, KbType.file => l.kb_files, KbType.link => l.kb_links };
  }
}

/// A row of the "الأكثر استخدامًا" group (Knowledge Base spec §4.6).
class KbEntryTile extends StatelessWidget {
  const KbEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.onToggle,
    this.onDelete,
    this.onLongPress,
  });

  final KbEntrySummary entry;
  final VoidCallback onTap;

  /// Swipe toward end: تعطيل / تفعيل. Null = read-only.
  final VoidCallback? onToggle;

  /// Swipe toward start: حذف.
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  static const _actionWidth = 88.0;

  List<Widget> _badges(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    Widget neutral(String s) => StatusBadge(label: s, foreground: c.textSecondary, background: c.surfaceVariant, compact: true);
    return [
      if (entry.status == KbStatus.draft) neutral(l.kb_badge_draft),
      if (entry.status == KbStatus.disabled) neutral(l.kb_badge_disabled),
      if (entry.isStale && entry.status == KbStatus.active)
        StatusBadge(label: l.kb_badge_stale, foreground: c.textWarning, background: c.warningContainer, compact: true),
      if (entry.status == KbStatus.processing)
        StatusBadge(
          label: l.kb_processing,
          foreground: c.textInfo,
          background: c.infoContainer,
          compact: true,
          leading: AppSpinner(size: 11, color: c.textInfo, delayed: false),
        ),
      if (entry.status == KbStatus.failed)
        StatusBadge(label: l.kb_badge_failed, foreground: c.textError, background: c.errorContainer, compact: true, icon: AppIcons.error),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final v = KbTypeVisual.of(context, entry.type, draft: entry.status == KbStatus.draft);
    final subtitle = KbSubtitleFormatter.format(l, entry);
    final badges = _badges(context);
    final dim = entry.status == KbStatus.disabled;

    final row = Semantics(
      button: true,
      label: '${KbTypeVisual.label(context, entry.type)}: ${entry.title}، $subtitle'
          '${entry.status == KbStatus.draft ? '، ${l.kb_badge_draft}' : ''}${dim ? '، ${l.kb_badge_disabled}' : ''}',
      excludeSemantics: true,
      customSemanticsActions: {
        if (onToggle != null)
          CustomSemanticsAction(label: entry.enabled ? l.kb_disable : l.kb_enable): onToggle!,
        if (onDelete != null) CustomSemanticsAction(label: l.kb_delete): onDelete!,
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: v.background, borderRadius: BorderRadius.circular(10)),
                child: AppIcon(v.icon, dp: 18, color: v.foreground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Opacity(
                  opacity: dim ? 0.6 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.title,
                              style: t.listTitle.copyWith(fontSize: 14.5),
                              maxLines: MediaQuery.textScalerOf(context).scale(10) >= 18 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          for (final b in badges) ...[const SizedBox(width: 6), b],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: t.bodySmall.copyWith(fontSize: 12.5, color: c.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIcon(AppIcons.chevronForward, size: AppIconSize.sm, color: c.borderStrong),
            ],
          ),
        ),
      ),
    );

    if (onToggle == null && onDelete == null) return row;

    // Width from MediaQuery, never a LayoutBuilder inside list rows.
    final width = (MediaQuery.sizeOf(context).width - 2 * AppSpacing.lg).clamp(1.0, 720.0);
    final ratio = (_actionWidth / width).clamp(0.1, 0.9);
    final onAction = c.isDark ? c.background : Colors.white;

    Widget action(IconData icon, String text, Color bg, VoidCallback onPressed) => CustomSlidableAction(
          backgroundColor: bg,
          foregroundColor: onAction,
          padding: EdgeInsets.zero,
          onPressed: (_) => onPressed(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, color: onAction),
              const SizedBox(height: AppSpacing.xs),
              Text(text, style: t.caption.copyWith(color: onAction), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        );

    return Slidable(
      key: ValueKey('kb-${entry.id}'),
      groupTag: 'kb',
      // Swipe toward the end edge → تعطيل / تفعيل (neutral).
      startActionPane: onToggle == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: ratio,
              children: [
                action(entry.enabled ? AppIcons.hidePassword : AppIcons.preview, entry.enabled ? l.kb_disable : l.kb_enable, c.textSecondary, onToggle!),
              ],
            ),
      // Swipe toward the start edge → حذف (error).
      endActionPane: onDelete == null
          ? null
          : ActionPane(
              motion: const DrawerMotion(),
              extentRatio: ratio,
              children: [action(AppIcons.delete, l.kb_delete, c.error, onDelete!)],
            ),
      child: row,
    );
  }
}
