import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import 'conversation_summary.dart';

/// Row-3 tag kinds in priority order (Inbox spec §4.5.3).
enum RowTagKind { waiting, aiReady, aiReplied, colleague, snoozed, windowClosing }

@immutable
class RowTag {
  const RowTag(this.kind, {this.minutes = 0, this.hours = 0, this.assignee, this.until});

  final RowTagKind kind;

  /// Waiting minutes (live, recomputed by the shared ticker).
  final int minutes;

  /// Hours until the WhatsApp window closes (rounded up).
  final int hours;
  final AssigneeRef? assignee;
  final DateTime? until;
}

abstract final class RowTagResolver {
  /// Returns the first tag that applies, or null (row shrinks).
  static RowTag? resolve(
    ConversationSummary c, {
    required InboxSegment segment,
    required String meId,
    required DateTime now,
  }) {
    // 1. Customer waiting > SLA and unanswered.
    if (c.waitingOverSla(now)) {
      return RowTag(RowTagKind.waiting, minutes: now.difference(c.waitingSince!).inMinutes);
    }
    // 2. AI suggestion ready.
    if (c.aiSuggestionReady && c.isActive) return const RowTag(RowTagKind.aiReady);
    // 3. Last reply was AI and the conversation is open.
    if (c.isActive && c.lastMessage?.senderType == SenderType.ai) return const RowTag(RowTagKind.aiReplied);
    // 4. Assigned to a colleague — only in "الكل".
    if (segment == InboxSegment.all && c.assignee != null && !c.isMine(meId)) {
      return RowTag(RowTagKind.colleague, assignee: c.assignee);
    }
    // 5. Snoozed.
    if (c.status == ConversationStatus.snoozed && c.snoozedUntil != null) {
      return RowTag(RowTagKind.snoozed, until: c.snoozedUntil);
    }
    // 6. WhatsApp 24h window closes in < 2h.
    final expires = c.waWindowExpiresAt;
    if (c.channel == Channel.whatsapp && expires != null && c.isActive) {
      final left = expires.difference(now);
      if (!left.isNegative && left < const Duration(hours: 2)) {
        return RowTag(RowTagKind.windowClosing, hours: (left.inMinutes / 60).ceil().clamp(1, 2));
      }
    }
    return null;
  }
}
