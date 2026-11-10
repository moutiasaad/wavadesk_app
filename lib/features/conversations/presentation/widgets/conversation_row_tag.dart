import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/l10n.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/relative_time_formatter.dart';
import '../../domain/row_tag_resolver.dart';
import '../../../../core/utils/span_format.dart';

/// Row-3 tag (Inbox spec §4.5.3): compact `StatusBadge`, h20, radius 6.
class ConversationRowTag extends StatelessWidget {
  const ConversationRowTag({super.key, required this.tag, required this.now});

  final RowTag tag;
  final DateTime now;

  static String label(RowTag tag, DateTime now, AppLocalizations l, String locale) => switch (tag.kind) {
    RowTagKind.waiting => l.inbox_tag_waiting(SpanFormat.minutes(tag.minutes, l)),
    RowTagKind.aiReady => l.inbox_tag_ai_ready,
    RowTagKind.aiReplied => l.inbox_tag_ai_replied,
    RowTagKind.colleague => tag.assignee?.firstName ?? '',
    RowTagKind.snoozed => l.inbox_tag_snoozed(RelativeTimeFormatter.until(tag.until!, now, l, locale)),
    RowTagKind.windowClosing => l.inbox_tag_window(tag.hours),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = label(tag, now, context.l10n, context.localeName);
    final (Color fg, Color bg, IconData? icon) = switch (tag.kind) {
      RowTagKind.waiting => (c.statusWaiting, c.statusWaitingContainer, AppIcons.waiting),
      RowTagKind.aiReady => (c.statusAi, c.statusAiContainer, AppIcons.ai),
      RowTagKind.aiReplied => (c.statusClosed, c.statusClosedContainer, AppIcons.aiAgent),
      RowTagKind.colleague => (c.statusClosed, c.statusClosedContainer, null),
      RowTagKind.snoozed => (c.statusSnoozed, c.statusSnoozedContainer, AppIcons.snooze),
      RowTagKind.windowClosing => (c.statusPending, c.statusPendingContainer, AppIcons.waiting),
    };
    final assignee = tag.assignee;
    return StatusBadge(
      label: text,
      foreground: fg,
      background: bg,
      icon: icon,
      compact: true,
      leading: tag.kind == RowTagKind.colleague && assignee != null
          ? AppAvatar(name: assignee.name, id: assignee.id, imageUrl: assignee.avatarUrl, size: AppAvatarSize.xxs)
          : null,
    );
  }
}
