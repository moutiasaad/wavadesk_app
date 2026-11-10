import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// First load (spec §7): 3 stat cards, banner, 6 rows. [rowsOnly]: just the
/// row group, while a filter/sort change is fetching.
class KbSkeleton extends StatelessWidget {
  const KbSkeleton({super.key, this.rowsOnly = false});

  final bool rowsOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget row() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              const SkeletonBox(width: 34, height: 34, radius: 10),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 180, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 120, height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
    final rows = Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      child: Column(children: [for (var i = 0; i < 6; i++) row()]),
    );
    if (rowsOnly) return AppSkeleton(child: rows);
    return AppSkeleton(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  const Expanded(child: SkeletonBox(height: 96, radius: AppRadius.xl)),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, 12, AppSpacing.lg, 0),
            child: SkeletonBox(height: 64, radius: AppRadius.xl),
          ),
          const SizedBox(height: 40),
          rows,
        ],
      ),
    );
  }
}
