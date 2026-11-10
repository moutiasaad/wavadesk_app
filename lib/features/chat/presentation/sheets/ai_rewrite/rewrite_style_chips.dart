import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/rewrite_style.dart';

/// Single-select style chips, Wrap 6/6 (Rewrite spec §5.4). A tiny
/// `accent` dot marks styles with cached results (§7) and the translate
/// chip when the customer prefers the other language (§5.4.1).
class RewriteStyleChips extends StatelessWidget {
  const RewriteStyleChips({
    super.key,
    required this.chips,
    required this.selected,
    required this.sourceIsArabic,
    required this.cachedIds,
    required this.onSelect,
    required this.enabled,
    this.highlightTranslate = false,
    this.onMore,
  });

  final List<RewriteStyle> chips;
  final RewriteStyle selected;
  final bool sourceIsArabic;
  final Set<String> cachedIds;
  final ValueChanged<RewriteStyle> onSelect;

  /// Offline → 40% and not tappable.
  final bool enabled;
  final bool highlightTranslate;

  /// `null` hides "المزيد ▾" (note mode).
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Wrap(
          spacing: 6,
          // Each chip is 32 visual inside a 48 hit box (8 above/below):
          // −10 gives the mockup's 6dp visual gap while hit boxes overlap.
          runSpacing: -10,
          children: [
            for (final s in chips)
              _StyleChip(
                style: s,
                label: s.label(l, sourceIsArabic: sourceIsArabic),
                selected: s == selected,
                dot: (cachedIds.contains(s.id) && s != selected) || (s.isTranslate && highlightTranslate),
                cached: cachedIds.contains(s.id),
                onTap: () {
                  if (s == selected) return; // ↻ regenerates instead
                  HapticFeedback.selectionClick();
                  onSelect(s);
                },
              ),
            if (onMore != null)
              AppFilterChip(label: l.rw_style_more, selected: false, trailingIcon: AppIcons.chevronDown, onTap: onMore),
          ],
        ),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.label,
    required this.selected,
    required this.dot,
    required this.cached,
    required this.onTap,
  });

  final RewriteStyle style;
  final String label;
  final bool selected;
  final bool dot;
  final bool cached;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onSecondary : c.textSecondary;
    return MergeSemantics(
      child: Semantics(
        hint: cached ? context.l10n.rw_a11y_cached : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppFilterChip(
              label: label,
              selected: selected,
              leading: style.icon == null ? null : Icon(style.icon, size: 12, color: fg),
              onTap: onTap,
            ),
            if (dot)
              PositionedDirectional(
                top: 8,
                end: 2,
                child: ExcludeSemantics(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surfaceElevated, width: 1.5),
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

/// "العميل يفضّل {language}" under the chips (§5.4.1).
class RewriteLanguageHint extends StatelessWidget {
  const RewriteLanguageHint({super.key, required this.language});

  /// "ar" | "en"
  final String language;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final name = language == 'ar' ? l.rw_lang_ar : l.rw_lang_en;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(AppIcons.language, size: 12, color: c.textInfo),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(l.rw_customer_prefers(name), style: context.text.caption.copyWith(color: c.textInfo)),
          ),
        ],
      ),
    );
  }
}
