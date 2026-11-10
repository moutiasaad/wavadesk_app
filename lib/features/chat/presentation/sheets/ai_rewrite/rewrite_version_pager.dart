import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// "‹ 2/3 ›" (Rewrite spec §5.5, §7). Arrows 28 visual, 48 hit. Mirrors in
/// RTL: the right arrow (›) is "previous", the left (‹) is "next".
class RewriteVersionPager extends StatelessWidget {
  const RewriteVersionPager({
    super.key,
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  /// 0-based.
  final int index;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final hasPrev = index > 0;
    final hasNext = index < count - 1;

    Widget arrow({required IconData icon, required String label, required VoidCallback? onTap}) => Semantics(
      button: true,
      enabled: onTap != null,
      label: '${l.rw_a11y_version(index + 1, count)}، $label',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox(
          width: 36,
          height: AppSpacing.minTouch,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: AppIcon(icon, size: AppIconSize.sm, color: onTap == null ? c.textDisabled : c.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );

    // Row lays out start → end, so the first child sits on the right in RTL.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(
          icon: rtl ? AppIcons.chevronRight : AppIcons.chevronLeft,
          label: l.rw_a11y_prev,
          onTap: hasPrev ? onPrevious : null,
        ),
        ExcludeSemantics(
          child: Text(
            '${index + 1}/$count',
            textDirection: TextDirection.ltr,
            style: context.text.caption.copyWith(fontWeight: FontWeight.w700, color: c.onPrimaryContainer),
          ),
        ),
        arrow(
          icon: rtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
          label: l.rw_a11y_next,
          onTap: hasNext ? onNext : null,
        ),
      ],
    );
  }
}
