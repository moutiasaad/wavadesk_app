import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import 'notification_day_group.dart';

/// First load (Notifications spec §7): 2 group-header skeletons + 3 row
/// skeletons each (tile 34 + 2 lines).
class NotificationSkeleton extends StatelessWidget {
  const NotificationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row() => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.md),
          child: Row(
            children: [
              SkeletonBox(width: 34, height: 34, radius: 10),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: 12),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 120, height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
    Widget header({bool first = false}) => Padding(
          padding: EdgeInsetsDirectional.only(start: 22, top: first ? 4 : 16, bottom: 6),
          child: const Align(alignment: AlignmentDirectional.centerStart, child: SkeletonBox(width: 52, height: 10)),
        );
    return ExcludeSemantics(
      child: AppSkeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(first: true),
            NotificationGroupCard(children: [row(), row(), row()]),
            header(),
            NotificationGroupCard(children: [row(), row(), row()]),
          ],
        ),
      ),
    );
  }
}
