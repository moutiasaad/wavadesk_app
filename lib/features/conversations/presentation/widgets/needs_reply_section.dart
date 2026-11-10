import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';

/// "تحتاج ردّك الآن" header (Inbox spec §4.6): red dot 8 + caption 700
/// `textError` + count, "عرض الكل" when more than 3. Padding 14/16/6.
class NeedsReplyHeader extends StatelessWidget {
  const NeedsReplyHeader({super.key, required this.count, required this.expanded, required this.onToggle});

  final int count;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg, end: AppSpacing.sm, top: 14, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                '${l.inbox_needs_reply} · $count',
                style: t.caption.copyWith(fontWeight: FontWeight.w700, color: c.textError),
              ),
            ),
          ),
          if (count > 3)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: c.primary,
                textStyle: t.buttonSmall,
                minimumSize: const Size(48, 36),
              ),
              onPressed: onToggle,
              child: Text(expanded ? l.inbox_show_less : l.inbox_see_all),
            ),
        ],
      ),
    );
  }
}

/// 8dp `backgroundMuted` gap + "باقي المحادثات" header.
class RestHeader extends StatelessWidget {
  const RestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: AppSpacing.sm, color: c.backgroundMuted),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg, end: AppSpacing.lg, top: 14, bottom: 6),
          child: Semantics(
            header: true,
            child: Text(context.l10n.inbox_rest, style: context.text.caption.copyWith(color: c.textSecondary)),
          ),
        ),
      ],
    );
  }
}
