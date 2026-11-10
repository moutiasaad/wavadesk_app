import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../application/assign_controller.dart';

/// الكل · متاحون (n) · فريقي — shown only with more than 8 agents (§5.3).
class AssigneeFilterChips extends StatelessWidget {
  const AssigneeFilterChips({super.key, required this.filter, required this.availableCount, required this.onChanged});

  final AssignFilter filter;
  final int availableCount;
  final ValueChanged<AssignFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        children: [
          for (final (f, label) in [
            (AssignFilter.all, l.as_filter_all),
            (AssignFilter.available, l.as_filter_available(availableCount)),
            (AssignFilter.myTeam, l.as_filter_my_team),
          ])
            AppFilterChip(label: label, selected: filter == f, onTap: () => onChanged(f)),
        ],
      ),
    );
  }
}
