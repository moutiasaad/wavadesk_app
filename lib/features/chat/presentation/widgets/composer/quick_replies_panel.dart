import 'package:flutter/material.dart';

import '../../../../../core/models/models.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/l10n.dart';

/// `/` quick replies panel above the composer (Chat spec §4.7.3): max 240dp,
/// `surfaceElevated`, radius 16; search-as-you-type over title/shortcut/text.
class QuickRepliesPanel extends StatelessWidget {
  const QuickRepliesPanel({super.key, required this.replies, required this.query, required this.onPick});

  final List<QuickReply> replies;

  /// Text typed after the leading "/".
  final String query;
  final ValueChanged<QuickReply> onPick;

  static List<QuickReply> filter(List<QuickReply> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final r in all)
        if (r.shortcut.toLowerCase().contains(q) ||
            r.title.toLowerCase().contains(q) ||
            r.text.toLowerCase().contains(q))
          r,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    final items = filter(replies, query);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: context.shadows.medium,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(l.composer_quick_empty, style: t.bodySmall.copyWith(color: c.textSecondary)),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: c.divider, indent: 14, endIndent: 14),
                itemBuilder: (context, i) {
                  final r = items[i];
                  return InkWell(
                    onTap: () => onPick(r),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: t.listTitle.copyWith(fontSize: 14)),
                                Text(
                                  r.text,
                                  style: t.bodySmall.copyWith(color: c.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('/${r.shortcut}', style: t.caption.copyWith(color: c.textTertiary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
