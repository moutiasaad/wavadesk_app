import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// "استلمها {name} للتو" — `warning` container, slides down 8dp + fades
/// in 200ms (Assign spec §6, §13).
class AssignLiveBanner extends StatelessWidget {
  const AssignLiveBanner({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduced = AppMotion.reduced(context);
    final banner = Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: c.warningContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.warning, size: AppIconSize.sm, color: c.textWarning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.as_taken_live(name),
                style: context.text.bodySmall.copyWith(color: c.textWarning, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (reduced) return banner;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, -8 * (1 - v)), child: child),
      ),
      child: banner,
    );
  }
}
