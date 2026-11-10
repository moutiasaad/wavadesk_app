import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/rewrite_style.dart';

/// "المزيد ▾" menu: 7 extra styles + workspace styles under "أساليب فريقك"
/// (Rewrite spec §5.4.2). Rows are 48.
Future<RewriteStyle?> showRewriteMoreStylesSheet(
  BuildContext context, {
  required RewriteStyle selected,
  required bool sourceIsArabic,
  required List<RewriteStyle> teamStyles,
}) {
  final l = context.l10n;
  return AppBottomSheet.show<RewriteStyle>(
    context,
    title: l.rw_style_more,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in RewriteStyle.more)
          _Row(
            label: s.label(l, sourceIsArabic: sourceIsArabic),
            selected: s == selected,
            onTap: () => Navigator.of(ctx).pop(s),
          ),
        if (teamStyles.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xs),
            child: Semantics(
              header: true,
              child: Text(l.rw_team_styles, style: ctx.text.overline.copyWith(color: ctx.colors.textTertiary)),
            ),
          ),
          for (final s in teamStyles)
            _Row(
              label: s.label(l, sourceIsArabic: sourceIsArabic),
              selected: s == selected,
              onTap: () => Navigator.of(ctx).pop(s),
            ),
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
              if (selected) Icon(AppIcons.check, size: 18, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}
