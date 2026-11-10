import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Day header (Notifications spec §4.4): caption 12.5/700 textSecondary,
/// padding top 16 (first: 4), start 22, bottom 6.
class NotificationDayHeader extends StatelessWidget {
  const NotificationDayHeader({super.key, required this.label, this.first = false});

  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsetsDirectional.only(start: 22, end: 22, top: first ? 4 : 16, bottom: 6),
        child: Semantics(
          header: true,
          child: Text(
            label,
            style: context.text.caption.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.colors.textSecondary),
          ),
        ),
      );
}

/// Group card (§4.5): surface, radius 18, 1dp border, margin H16, full-width
/// 1dp dividers between rows.
class NotificationGroupCard extends StatelessWidget {
  const NotificationGroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) Divider(height: 1, color: c.divider),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
