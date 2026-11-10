import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// First load: section header bar + 3 tiles (avatar circle + 2 lines) (§8).
/// Shimmer off under reduce motion (AppSkeleton handles it).
class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 22, AppSpacing.screenH, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 64, height: 10),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const SkeletonBox(height: 40, width: 40, circle: true),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(widthFactor: i.isEven ? 0.5 : 0.4, child: const SkeletonBox(height: 12)),
                          const SizedBox(height: 8),
                          FractionallySizedBox(
                            widthFactor: i.isEven ? 0.85 : 0.7,
                            child: const SkeletonBox(height: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
