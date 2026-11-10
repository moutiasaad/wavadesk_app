import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';

/// Rows of the reversed message list (Chat spec §4.3).
sealed class ChatListItem {
  const ChatListItem();
  String get key;
}

@immutable
class MessageItem extends ChatListItem {
  const MessageItem(this.message, {required this.firstInGroup, required this.lastInGroup, required this.gapAbove});

  final Message message;

  /// Top bubble of a group: shows the colleague sender label.
  final bool firstInGroup;

  /// Bottom bubble of a group: only it gets the tail + status row.
  final bool lastInGroup;

  /// 4dp inside a group, 10dp between groups.
  final double gapAbove;

  @override
  String get key => 'm:${message.id}';
}

@immutable
class DayDividerItem extends ChatListItem {
  const DayDividerItem(this.day);
  final DateTime day;

  @override
  String get key => 'd:${day.year}-${day.month}-${day.day}';
}

@immutable
class UnreadDividerItem extends ChatListItem {
  const UnreadDividerItem(this.count);
  final int count;

  @override
  String get key => 'unread';
}

@immutable
class TypingItem extends ChatListItem {
  const TypingItem();

  @override
  String get key => 'typing';
}

abstract final class MessageGrouping {
  static const groupWindow = Duration(minutes: 3);

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _groupable(Message m) => m.type != MessageBubbleType.system;

  static bool sameGroup(Message a, Message b) =>
      _groupable(a) &&
      _groupable(b) &&
      a.senderKey == b.senderKey &&
      _sameDay(a.sentAt, b.sentAt) &&
      b.sentAt.difference(a.sentAt).abs() <= groupWindow;

  /// [messages] oldest → newest. Returns rows newest → oldest, ready for a
  /// `ListView(reverse: true)`: day dividers, the unread divider before
  /// [unreadAnchorId], grouping flags, and a typing row at the bottom.
  static List<ChatListItem> build(
    List<Message> messages, {
    String? unreadAnchorId,
    int unreadCount = 0,
    bool typing = false,
  }) {
    final out = <ChatListItem>[];
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final prev = i > 0 ? messages[i - 1] : null;
      final next = i + 1 < messages.length ? messages[i + 1] : null;
      if (prev == null || !_sameDay(prev.sentAt, m.sentAt)) {
        out.add(DayDividerItem(DateTime(m.sentAt.year, m.sentAt.month, m.sentAt.day)));
      }
      if (unreadAnchorId != null && m.id == unreadAnchorId && unreadCount > 0) {
        out.add(UnreadDividerItem(unreadCount));
      }
      final groupedWithPrev = prev != null && sameGroup(prev, m) && m.id != unreadAnchorId;
      final groupedWithNext = next != null && sameGroup(m, next) && next.id != unreadAnchorId;
      out.add(
        MessageItem(
          m,
          firstInGroup: !groupedWithPrev,
          lastInGroup: !groupedWithNext,
          gapAbove: groupedWithPrev ? 4 : 10,
        ),
      );
    }
    if (typing) out.add(const TypingItem());
    return out.reversed.toList();
  }
}
