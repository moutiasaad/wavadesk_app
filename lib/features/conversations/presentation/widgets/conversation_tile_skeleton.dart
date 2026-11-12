import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';

/// First-load placeholder (Inbox v2 §5.1): 8 rows of avatar circle + 2 bars
/// + a short bar, shimmer from [AppSkeleton] (static under reduce-motion).
class ConversationTileSkeleton extends StatelessWidget {
  const ConversationTileSkeleton({super.key});

  /// The 8-row list.
  static Widget list() =>
      AppSkeleton(child: Column(children: [for (var i = 0; i < 8; i++) const ConversationTileSkeleton()]));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SkeletonBox(width: 50, height: 50, circle: true),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: box.maxWidth * 0.42, height: 12),
                        const Spacer(),
                        SkeletonBox(width: box.maxWidth * 0.12, height: 10),
                      ],
                    ),
                    const SizedBox(height: 9),
                    SkeletonBox(width: box.maxWidth * 0.78, height: 10),
                    const SizedBox(height: 8),
                    SkeletonBox(width: box.maxWidth * 0.26, height: 8),
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
