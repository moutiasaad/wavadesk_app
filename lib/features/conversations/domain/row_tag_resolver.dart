import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';
import 'conversation_summary.dart';

/// Row-3 tag kinds in priority order (Inbox v2 §4.4).
enum RowTagKind { waiting, aiReady, aiReplied, unassigned, colleague, snoozed }

@immutable
class RowTag {
  const RowTag(this.kind, {this.minutes = 0, this.assignee, this.until});

  final RowTagKind kind;

  /// Waiting minutes (live, recomputed by the shared ticker).
  final int minutes;
  final AssigneeRef? assignee;
  final DateTime? until;
}

abstract final class RowTagResolver {
  /// The one tag a row shows (or null). [allPill] = the "الكل" pill;
  /// [lead] = supervisors / admins (colleague tag).
  static RowTag? resolve(
    ConversationSummary c, {
    required String meId,
    required DateTime now,
    bool allPill = false,
    bool lead = false,
  }) {
    // 1. Customer waiting for a human (unanswered) for a minute or more.
    final waited = c.waitingSince == null || !c.isActive ? null : now.difference(c.waitingSince!).inMinutes;
    if (waited != null && waited >= 1) return RowTag(RowTagKind.waiting, minutes: waited);
    // 2. AI suggestion ready.
    if (c.aiSuggestionReady && c.isActive) return const RowTag(RowTagKind.aiReady);
    // 3. The AI is answering it (the list API's `ai_handling`) or wrote last.
    if (c.isActive && (c.handledByAi || c.lastMessage?.senderType == SenderType.ai)) {
      return const RowTag(RowTagKind.aiReplied);
    }
    // 4. Unassigned — only in "الكل".
    if (allPill && c.isActive && c.assignee == null) return const RowTag(RowTagKind.unassigned);
    // 5. A colleague's — leads / admins in "الكل".
    if (allPill && lead && c.assignee != null && !c.isMine(meId)) {
      return RowTag(RowTagKind.colleague, assignee: c.assignee);
    }
    // Snoozed.
    if (c.status == ConversationStatus.snoozed && c.snoozedUntil != null) {
      return RowTag(RowTagKind.snoozed, until: c.snoozedUntil);
    }
    return null;
  }
}
