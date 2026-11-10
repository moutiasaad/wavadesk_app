import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';

/// لي | غير مُسندة | الكل (Inbox spec §4.2). Counts in `primary`, hidden
/// when 0; "الكل" never shows a count.
class InboxSegmented extends StatelessWidget {
  const InboxSegmented({super.key, required this.selected, required this.counts, required this.onChanged});

  final InboxSegment selected;
  final Map<String, int> counts;
  final ValueChanged<InboxSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    int? count(String key) {
      final n = counts[key] ?? 0;
      return n > 0 ? n : null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppSegmented<InboxSegment>(
        selected: selected,
        onChanged: (s) {
          if (s == selected) return;
          HapticFeedback.selectionClick();
          onChanged(s);
        },
        segments: [
          AppSegment(value: InboxSegment.mine, label: l.inbox_seg_mine, count: count('mine')),
          AppSegment(value: InboxSegment.unassigned, label: l.inbox_seg_unassigned, count: count('unassigned')),
          AppSegment(value: InboxSegment.all, label: l.inbox_seg_all),
        ],
      ),
    );
  }
}
