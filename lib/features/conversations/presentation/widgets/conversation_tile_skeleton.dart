import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

/// First-load placeholder (Inbox spec §4.10): circle 50 + name line 40% +
/// time line 15% + preview line 75%. Shimmer from [AppSkeleton] (static
/// under reduce-motion).
class ConversationTileSkeleton extends StatelessWidget {
  const ConversationTileSkeleton({super.key});

  /// The 8-row list.
  static Widget list() =>
      AppSkeleton(child: Column(children: [for (var i = 0; i < 8; i++) const ConversationTileSkeleton()]));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SkeletonBox(width: 50, height: 50, circle: true),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: box.maxWidth * 0.40, height: 12),
                        const Spacer(),
                        SkeletonBox(width: box.maxWidth * 0.15, height: 10),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SkeletonBox(width: box.maxWidth * 0.75, height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
