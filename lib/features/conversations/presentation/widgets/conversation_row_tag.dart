import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/relative_time_formatter.dart';
import '../../domain/row_tag_resolver.dart';
import 'inbox_palette.dart';

/// Row-3 status tag (Inbox v2 §4.4): h20, padding 0 7, radius 6, gap 3,
/// Cairo 11/700, optional 12dp icon.
class ConversationRowTag extends StatelessWidget {
  const ConversationRowTag({super.key, required this.tag, required this.now});

  final RowTag tag;
  final DateTime now;

  static String label(RowTag tag, DateTime now, AppLocalizations l, String locale) => switch (tag.kind) {
    RowTagKind.waiting => tag.minutes < 60 ? l.inbox_wait_min(tag.minutes) : l.inbox_wait_hr(tag.minutes ~/ 60),
    RowTagKind.aiReady => l.inbox_tag_ai_ready,
    RowTagKind.aiReplied => l.inbox_tag_ai_replied,
    RowTagKind.unassigned => l.inbox_seg_unassigned,
    RowTagKind.colleague => tag.assignee?.firstName ?? '',
    RowTagKind.snoozed => l.inbox_tag_snoozed(RelativeTimeFormatter.until(tag.until!, now, l, locale)),
  };

  @override
  Widget build(BuildContext context) {
    final p = InboxPalette.of(context);
    final text = label(tag, now, context.l10n, context.localeName);
    final (Color bg, Color fg, IconData? icon) = switch (tag.kind) {
      RowTagKind.waiting => (p.waitBg, p.waitFg, AppIcons.clock),
      RowTagKind.aiReady => (p.suggestBg, p.suggestFg, AppIcons.ai),
      RowTagKind.aiReplied => (p.aiBg, p.aiFg, null),
      RowTagKind.unassigned => (p.unassignedBg, p.unassignedFg, null),
      RowTagKind.colleague => (p.colleagueBg, p.colleagueFg, null),
      RowTagKind.snoozed => (p.snoozedBg, p.snoozedFg, null),
    };
    final assignee = tag.assignee;
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag.kind == RowTagKind.colleague && assignee != null) ...[
            SizedBox.square(
              dimension: 14,
              child: AppAvatar(name: assignee.name, id: assignee.id, imageUrl: assignee.avatarUrl, size: AppAvatarSize.xxs),
            ),
            const SizedBox(width: 3),
          ] else if (icon != null) ...[
            AppIcon(icon, dp: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w700, height: 1.3, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
