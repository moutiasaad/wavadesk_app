import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// Loading state without cache (§6): hero (circle 76 + 2 lines), 4 quick
/// action tiles, 3 cards. Shimmer from [AppSkeleton] (static under reduce
/// motion).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        children: [
          const SkeletonBox(width: 76, height: 76, circle: true),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(width: 160, height: 16),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 110, height: 12),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                const Expanded(
                  child: Column(
                    children: [
                      SkeletonBox(width: 48, height: 48, circle: true),
                      SizedBox(height: AppSpacing.xs),
                      SkeletonBox(width: 40, height: 10),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final h in const [64.0, 96.0, 140.0]) ...[
            SkeletonBox(width: double.infinity, height: h, radius: AppRadius.xl),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
