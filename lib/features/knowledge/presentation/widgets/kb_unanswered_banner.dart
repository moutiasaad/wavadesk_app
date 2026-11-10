import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// Amber "{n} أسئلة بلا إجابة · راجعها" card (spec §4.4, dark §11).
/// Hidden by the caller when n = 0.
class KbUnansweredBanner extends StatelessWidget {
  const KbUnansweredBanner({super.key, required this.count, required this.onReview});

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final dark = c.isDark;
    final bg = dark ? const Color(0xFF2A2312) : const Color(0xFFFFFBEB);
    final border = dark ? const Color(0xFF6B5320) : const Color(0xFFF7E2A6);
    final iconBg = dark ? const Color(0xFF3A2E12) : const Color(0xFFFEF3C7);
    final body = dark ? const Color(0xFFF3D79A) : const Color(0xFF92400E);
    final btnBorder = dark ? const Color(0xFF6B5320) : const Color(0xFFF1D58C);

    return Semantics(
      button: true,
      label: l.kb_banner_a11y(count),
      excludeSemantics: true,
      onTap: onReview,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: border)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: AppIcon(AppIcons.ai, color: c.textWarning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    child: Text(
                      l.kb_unanswered_title(count),
                      key: ValueKey(count),
                      style: t.listTitle.copyWith(fontSize: 14, color: dark ? body : c.textPrimary),
                    ),
                  ),
                  Text(l.kb_unanswered_body, style: t.bodySmall.copyWith(fontSize: 12.5, color: body)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: onReview,
                style: OutlinedButton.styleFrom(
                  backgroundColor: dark ? const Color(0xFF151E22) : c.surface,
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: btnBorder),
                  minimumSize: const Size(48, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: t.buttonMedium.copyWith(fontSize: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
                child: Text(l.kb_review),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner placeholder while loading (spec §7).
class KbBannerSkeleton extends StatelessWidget {
  const KbBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
        child: SkeletonBox(height: 64, radius: AppRadius.xl),
      );
}
