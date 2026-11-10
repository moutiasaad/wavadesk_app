import 'package:flutter/foundation.dart';

import 'agent.dart';
import 'customer.dart';
import 'enums.dart';
import 'message.dart';

@immutable
class AiSuggestion {
  const AiSuggestion({required this.text, required this.source, this.confidence = 0.9, this.noAnswer = false});

  final String text;

  /// 0–1. Below 0.6 the card warns "تأكد من الرد قبل الإرسال".
  final double confidence;

  /// AI found nothing in the knowledge base (card shows the no-answer row).
  final bool noAnswer;

  /// Knowledge-base entry the draft came from ("سياسة التوصيل").
  final String source;
}

@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.customer,
    required this.status,
    required this.ownership,
    required this.messages,
    this.priority = Priority.low,
    this.assignee,
    this.unreadCount = 0,
    this.waitingSince,
    this.aiSuggestion,
    this.aiSuggestionDismissed = false,
    this.tags = const [],
    this.orderRef,
    this.viewers = const [],
    this.snoozedUntil,
    this.serviceWindowOpen = true,
    this.customerTyping = false,
    this.aiPaused = false,
    this.customerOnline = false,
    this.lastSeen,
    this.browsingPage,
    this.channelConnected = true,
    this.colleagueTypingNote,
  });

  final String id;
  final Customer customer;
  final ConversationStatus status;
  final Ownership ownership;
  final List<Message> messages; // oldest → newest
  final Priority priority;
  final Agent? assignee;
  final int unreadCount;

  /// Set when the customer is waiting on us; drives the waiting tag & sort.
  final DateTime? waitingSince;
  final AiSuggestion? aiSuggestion;
  final bool aiSuggestionDismissed;
  final List<String> tags;
  final String? orderRef;

  /// Colleagues currently looking at this conversation.
  final List<Agent> viewers;
  final DateTime? snoozedUntil;

  /// WhatsApp 24-hour customer-service window.
  final bool serviceWindowOpen;
  final bool customerTyping;

  /// AI auto-replies paused for this conversation only.
  final bool aiPaused;
  final bool customerOnline;
  final DateTime? lastSeen;

  /// Website chat: page the visitor is on ("/checkout").
  final String? browsingPage;

  /// False when the channel (e.g. WhatsApp) is disconnected.
  final bool channelConnected;

  /// Colleague currently typing an internal note.
  final String? colleagueTypingNote;

  Channel get channel => customer.channel;
  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  /// Last message that is visible to the customer (notes/system excluded).
  Message? get lastPreviewMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.type != MessageBubbleType.internalNote && m.type != MessageBubbleType.system) {
        return m;
      }
    }
    return null;
  }

  DateTime get lastActivity => lastMessage?.sentAt ?? DateTime(2000);

  bool get isUnread => unreadCount > 0;
  bool get isClosed => status == ConversationStatus.closed || status == ConversationStatus.resolved;
  bool get hasSuggestion => aiSuggestion != null;

  Conversation copyWith({
    Customer? customer,
    ConversationStatus? status,
    Ownership? ownership,
    List<Message>? messages,
    Priority? priority,
    Agent? assignee,
    bool clearAssignee = false,
    int? unreadCount,
    DateTime? waitingSince,
    bool clearWaiting = false,
    AiSuggestion? aiSuggestion,
    bool clearSuggestion = false,
    bool? aiSuggestionDismissed,
    List<String>? tags,
    List<Agent>? viewers,
    DateTime? snoozedUntil,
    bool clearSnooze = false,
    bool? serviceWindowOpen,
    bool? customerTyping,
    bool? aiPaused,
    bool? customerOnline,
    String? colleagueTypingNote,
    bool clearColleagueTyping = false,
    bool? channelConnected,
  }) => Conversation(
    id: id,
    customer: customer ?? this.customer,
    status: status ?? this.status,
    ownership: ownership ?? this.ownership,
    messages: messages ?? this.messages,
    priority: priority ?? this.priority,
    assignee: clearAssignee ? null : (assignee ?? this.assignee),
    unreadCount: unreadCount ?? this.unreadCount,
    waitingSince: clearWaiting ? null : (waitingSince ?? this.waitingSince),
    aiSuggestion: clearSuggestion ? null : (aiSuggestion ?? this.aiSuggestion),
    aiSuggestionDismissed: aiSuggestionDismissed ?? this.aiSuggestionDismissed,
    tags: tags ?? this.tags,
    orderRef: orderRef,
    viewers: viewers ?? this.viewers,
    snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
    serviceWindowOpen: serviceWindowOpen ?? this.serviceWindowOpen,
    customerTyping: customerTyping ?? this.customerTyping,
    aiPaused: aiPaused ?? this.aiPaused,
    customerOnline: customerOnline ?? this.customerOnline,
    lastSeen: lastSeen,
    browsingPage: browsingPage,
    channelConnected: channelConnected ?? this.channelConnected,
    colleagueTypingNote: clearColleagueTyping ? null : (colleagueTypingNote ?? this.colleagueTypingNote),
  );
}
