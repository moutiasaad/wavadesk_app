import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/dashboard_snapshot.dart';

/// New workspace (no customer message yet): replaces grid + chart (spec §6).
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({super.key, required this.steps});

  final OnboardingSteps steps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final rows = [
      (l.dash_onb_wa, steps.whatsapp, () => context.push(Routes.whatsapp)),
      (l.dash_onb_kb, steps.kb, () => context.go(Routes.knowledge)),
      (l.dash_onb_ai, steps.ai, () => context.push(Routes.aiAgent)),
    ];
    final next = rows.where((r) => !r.$2).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.dash_onb_title, style: t.h6.copyWith(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          for (final (label, done, go) in rows)
            InkWell(
              onTap: done ? null : go,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? c.success : Colors.transparent,
                        border: done ? null : Border.all(color: c.borderStrong, width: 1.5),
                      ),
                      child: done ? Icon(AppIcons.check, size: 14, color: c.onPrimary) : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: t.bodyMedium.copyWith(
                          color: done ? c.textSecondary : c.textPrimary,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (!done) Icon(AppIcons.chevronEnd, size: 16, color: c.textTertiary),
                  ],
                ),
              ),
            ),
          if (next != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: l.dash_onb_cta, expand: true, onPressed: next.$3),
          ],
        ],
      ),
    );
  }
}
