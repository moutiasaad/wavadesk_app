import 'package:flutter/material.dart';

import '../../../../core/widgets/widgets.dart';
import '../dash_palette.dart';

/// Loading (Dashboard v2 §5): shimmer KPI tiles, chart and team cards in
/// their real sizes; the header is already drawn from the session.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile() => DashCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 80, height: 12),
              SizedBox(height: 10),
              SkeletonBox(width: 56, height: 26),
            ],
          ),
        );
    Widget row() => Row(children: [Expanded(child: tile()), const SizedBox(width: 10), Expanded(child: tile())]);
    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(),
          const SizedBox(height: 10),
          row(),
          const SizedBox(height: 10),
          const DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [SkeletonBox(width: 110, height: 14), Spacer(), SkeletonBox(width: 60, height: 12)]),
                SizedBox(height: 10),
                SkeletonBox(height: 64, radius: 8),
                SizedBox(height: 4),
                SkeletonBox(height: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DashCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 90, height: 14),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      const Column(
                        children: [SkeletonBox(width: 40, height: 40, circle: true), SizedBox(height: 6), SkeletonBox(width: 36, height: 10)],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
