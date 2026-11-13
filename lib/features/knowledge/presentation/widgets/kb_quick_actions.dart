import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

enum KbQuickAction { aiSettings, tags, import }

/// إعدادات الذكاء الاصطناعي | إدارة الوسوم | استيراد — the shortcuts that
/// used to sit in the ⋮ menu, as cards where the type stats were.
/// Tags and import need edit rights; AI settings is always shown.
class KbQuickActions extends StatelessWidget {
  const KbQuickActions({super.key, required this.canEdit, required this.onAction});

  final bool canEdit;
  final ValueChanged<KbQuickAction> onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final items = <(KbQuickAction, IconData, String, Color, Color)>[
      (KbQuickAction.aiSettings, AppIcons.aiAgent, l.kb_menu_ai_settings, c.primaryContainer, c.primary),
      if (canEdit) (KbQuickAction.tags, AppIcons.tag, l.kb_menu_tags, c.warningContainer, c.warning),
      if (canEdit) (KbQuickAction.import, AppIcons.download, l.kb_menu_import, c.infoContainer, c.info),
    ];
    final cards = [
      for (final (a, icon, label, bg, fg) in items)
        _ActionCard(icon: icon, label: label, background: bg, foreground: fg, onTap: () => onAction(a)),
    ];

    // 200% text: horizontally scrollable (spec §10).
    if (MediaQuery.textScalerOf(context).scale(10) >= 18) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              SizedBox(width: 150, child: cards[i]),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                  child: AppIcon(icon, dp: 18, color: foreground),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: context.text.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: c.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
