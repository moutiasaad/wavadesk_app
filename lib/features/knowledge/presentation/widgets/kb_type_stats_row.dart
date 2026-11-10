import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/kb_entry.dart';
import 'kb_entry_tile.dart';

/// سؤال وجواب 24 | ملفات 3 | روابط 1 — tap = filter toggle (spec §4.3).
class KbTypeStatsRow extends StatelessWidget {
  const KbTypeStatsRow({super.key, required this.counts, required this.selected, required this.onSelect, this.processing = 0});

  final KbCounts counts;
  final KbType? selected;
  final ValueChanged<KbType?> onSelect;

  /// Files/links still processing (spinner + "جارٍ المعالجة").
  final int processing;

  @override
  Widget build(BuildContext context) {
    final big = MediaQuery.textScalerOf(context).scale(10) >= 18;
    final cards = [
      for (final t in KbType.values)
        _StatCard(
          type: t,
          count: counts.of(t),
          selected: selected == t,
          processing: t != KbType.qa && processing > 0,
          onTap: () => onSelect(selected == t ? null : t),
        ),
    ];
    // 200% text: horizontally scrollable (spec §10).
    if (big) {
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.type, required this.count, required this.selected, required this.processing, required this.onTap});

  final KbType type;
  final int count;
  final bool selected;
  final bool processing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final v = KbTypeVisual.of(context, type);
    final label = KbTypeVisual.label(context, type);
    final selBg = c.isDark ? const Color(0xFF0F2E2D) : c.primaryContainer;
    final selBorder = c.isDark ? const Color(0xFF2BB8AD) : c.primary;

    return Semantics(
      button: true,
      toggled: selected,
      label: l.kb_filter_a11y(label, count),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        decoration: BoxDecoration(
          color: selected ? selBg : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: selected ? selBorder : c.border, width: selected ? 1.5 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: v.background, shape: BoxShape.circle),
                    child: AppIcon(v.icon, dp: 18, color: v.foreground),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: Text('$count', key: ValueKey(count), style: t.h4.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                      if (processing) ...[
                        const SizedBox(width: 4),
                        AppSpinner(size: 12, color: c.textInfo, delayed: false),
                      ],
                    ],
                  ),
                  Text(
                    label,
                    style: t.caption.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  if (processing)
                    Text(l.kb_processing, style: t.caption.copyWith(color: c.textInfo), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
