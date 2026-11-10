import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// First-load placeholders (spec §6): metric bars, 12 chart bars at random
/// heights 20–70%, 5 team circles.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  static final _heights = List<double>.generate(12, (i) => 0.2 + Random(i * 7 + 3).nextDouble() * 0.5);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    BoxDecoration card() => BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: c.border),
        );

    Widget metric() => Expanded(
          child: Container(
            height: 84,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
            decoration: card(),
            child: LayoutBuilder(
              builder: (_, box) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: box.maxWidth * 0.5, height: 10),
                  const SizedBox(height: 14),
                  SkeletonBox(width: box.maxWidth * 0.4, height: 24),
                ],
              ),
            ),
          ),
        );

    return AppSkeleton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: 6),
            Row(children: [metric(), const SizedBox(width: 10), metric()]),
            const SizedBox(height: 10),
            Row(children: [metric(), const SizedBox(width: 10), metric()]),
            const SizedBox(height: 10),
            Container(
              height: 150,
              padding: const EdgeInsets.all(14),
              decoration: card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 120, height: 12),
                  const Spacer(),
                  SizedBox(
                    height: 96,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 12; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Expanded(child: SkeletonBox(height: 96 * _heights[i], radius: 5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
              decoration: card(),
              child: Row(
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    const SkeletonBox(width: 40, height: 40, circle: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
