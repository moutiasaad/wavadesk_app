import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';

/// Inbox row data — the `ConversationSummary` contract (Inbox spec §6).
/// Built from the API JSON, or from a loaded [Conversation] (offline search).

enum MessageDirection { incoming, outgoing }

enum SenderType { contact, agent, ai, system, note }

enum LastMessageType { text, image, voice, file, location, sticker, deleted }

@immutable
class ContactRef {
  const ContactRef({required this.id, required this.name, this.avatarUrl, this.phone, this.email});

  final String id;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? email;
}

@immutable
class AssigneeRef {
  const AssigneeRef({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

@immutable
class LastMessage {
  const LastMessage({
    required this.id,
    required this.direction,
    required this.senderType,
    required this.type,
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.text,
    this.durationSec,
    this.fileName,
    this.delivery,
  });

  final String id;
  final MessageDirection direction;
  final SenderType senderType;
  final LastMessageType type;
  final DateTime createdAt;
  final String? senderId;
  final String? senderName;
  final String? text;
  final int? durationSec;
  final String? fileName;
  final DeliveryState? delivery;
}

@immutable
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.channel,
    required this.contact,
    required this.status,
    required this.lastActivityAt,
    this.priority,
    this.assignee,
    this.handledByAi = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.waitingSince,
    this.slaSeconds = 300,
    this.aiSuggestionReady = false,
    this.snoozedUntil,
    this.waWindowExpiresAt,
    this.isTyping = false,
    this.tags = const [],
    this.teamIds = const [],
    this.closedAt,
  });

  final String id;
  final Channel channel;
  final ContactRef contact;
  final ConversationStatus status;
  final Priority? priority;
  final AssigneeRef? assignee;
  final bool handledByAi;
  final LastMessage? lastMessage;
  final int unreadCount;

  /// First unanswered inbound message.
  final DateTime? waitingSince;

  /// Workspace SLA (default 5 min).
  final int slaSeconds;
  final bool aiSuggestionReady;
  final DateTime? snoozedUntil;
  final DateTime? waWindowExpiresAt;
  final bool isTyping;
  final DateTime lastActivityAt;
  final List<String> tags;
  final List<String> teamIds;
  final DateTime? closedAt;

  bool get isUnread => unreadCount > 0;
  bool get isClosed => status == ConversationStatus.resolved || status == ConversationStatus.closed;

  /// Open-ish statuses that count as "work in progress" for the segments.
  bool get isActive =>
      status == ConversationStatus.open ||
      status == ConversationStatus.pending ||
      status == ConversationStatus.waiting ||
      status == ConversationStatus.ai;

  bool isMine(String meId) => assignee?.id == meId;

  /// Customer waiting longer than the SLA with no reply yet (§4.5.3 #1).
  bool waitingOverSla(DateTime now) =>
      waitingSince != null && isActive && now.difference(waitingSince!).inSeconds > slaSeconds;

  // ---- JSON (API) ---------------------------------------------------------------

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) =>
      values.firstWhere((v) => v.name == raw, orElse: () => fallback);

  static DateTime? _date(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

  factory ConversationSummary.fromJson(Map<String, dynamic> j) {
    final contact = Map<String, dynamic>.from(j['contact'] as Map? ?? const {});
    final assignee = j['assignee'] is Map ? Map<String, dynamic>.from(j['assignee'] as Map) : null;
    final last = j['last_message'] is Map ? Map<String, dynamic>.from(j['last_message'] as Map) : null;
    return ConversationSummary(
      id: '${j['id']}',
      channel: _enum(Channel.values, j['channel'], Channel.other),
      contact: ContactRef(
        id: '${contact['id']}',
        name: (contact['name'] as String?) ?? '',
        avatarUrl: contact['avatar_url'] as String?,
        phone: contact['phone'] as String?,
        email: contact['email'] as String?,
      ),
      status: _enum(ConversationStatus.values, j['status'], ConversationStatus.open),
      priority: j['priority'] == null ? null : _enum(Priority.values, j['priority'], Priority.low),
      assignee: assignee == null
          ? null
          : AssigneeRef(
              id: '${assignee['id']}',
              name: (assignee['name'] as String?) ?? '',
              avatarUrl: assignee['avatar_url'] as String?,
            ),
      handledByAi: j['handled_by_ai'] == true,
      lastMessage: last == null
          ? null
          : LastMessage(
              id: '${last['id']}',
              direction: last['direction'] == 'out' ? MessageDirection.outgoing : MessageDirection.incoming,
              senderType: _enum(SenderType.values, last['sender_type'], SenderType.contact),
              senderId: last['sender_id']?.toString(),
              senderName: last['sender_name'] as String?,
              type: _enum(LastMessageType.values, last['type'], LastMessageType.text),
              text: last['text'] as String?,
              durationSec: (last['duration_sec'] as num?)?.toInt(),
              fileName: last['file_name'] as String?,
              delivery: last['delivery'] == null
                  ? null
                  : _enum(DeliveryState.values, last['delivery'], DeliveryState.sent),
              createdAt: _date(last['created_at']) ?? DateTime.now(),
            ),
      unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      waitingSince: _date(j['waiting_since']),
      slaSeconds: (j['sla_seconds'] as num?)?.toInt() ?? 300,
      aiSuggestionReady: j['ai_suggestion_ready'] == true,
      snoozedUntil: _date(j['snoozed_until']),
      waWindowExpiresAt: _date(j['wa_window_expires_at']),
      isTyping: j['is_typing'] == true,
      lastActivityAt: _date(j['last_activity_at']) ?? DateTime.now(),
      tags: [for (final t in (j['tags'] as List? ?? const [])) '$t'],
      teamIds: [for (final t in (j['team_ids'] as List? ?? const [])) '$t'],
      closedAt: _date(j['closed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'channel': channel.name,
    'contact': {
      'id': contact.id,
      'name': contact.name,
      'avatar_url': contact.avatarUrl,
      'phone': contact.phone,
      'email': contact.email,
    },
    'status': status.name,
    'priority': priority?.name,
    'assignee': assignee == null
        ? null
        : {'id': assignee!.id, 'name': assignee!.name, 'avatar_url': assignee!.avatarUrl},
    'handled_by_ai': handledByAi,
    'last_message': lastMessage == null
        ? null
        : {
            'id': lastMessage!.id,
            'direction': lastMessage!.direction == MessageDirection.outgoing ? 'out' : 'in',
            'sender_type': lastMessage!.senderType.name,
            'sender_id': lastMessage!.senderId,
            'sender_name': lastMessage!.senderName,
            'type': lastMessage!.type.name,
            'text': lastMessage!.text,
            'duration_sec': lastMessage!.durationSec,
            'file_name': lastMessage!.fileName,
            'delivery': lastMessage!.delivery?.name,
            'created_at': lastMessage!.createdAt.toUtc().toIso8601String(),
          },
    'unread_count': unreadCount,
    'waiting_since': waitingSince?.toUtc().toIso8601String(),
    'sla_seconds': slaSeconds,
    'ai_suggestion_ready': aiSuggestionReady,
    'snoozed_until': snoozedUntil?.toUtc().toIso8601String(),
    'wa_window_expires_at': waWindowExpiresAt?.toUtc().toIso8601String(),
    'is_typing': isTyping,
    'last_activity_at': lastActivityAt.toUtc().toIso8601String(),
    'tags': tags,
    'team_ids': teamIds,
    'closed_at': closedAt?.toUtc().toIso8601String(),
  };

  // ---- Adapter from the local sample-data model -------------------------------

  factory ConversationSummary.fromConversation(Conversation c, {required String meId, required List<String> teamIds}) {
    // Last customer-visible or note message (system events are skipped).
    Message? last;
    for (var i = c.messages.length - 1; i >= 0; i--) {
      if (c.messages[i].type != MessageBubbleType.system) {
        last = c.messages[i];
        break;
      }
    }

    // First unanswered inbound = start of the trailing run of incoming
    // messages (notes don't count as an answer).
    DateTime? waiting = c.waitingSince;
    if (waiting == null) {
      for (var i = c.messages.length - 1; i >= 0; i--) {
        final m = c.messages[i];
        if (m.type == MessageBubbleType.incoming) {
          waiting = m.sentAt;
        } else if (m.type == MessageBubbleType.internalNote || m.type == MessageBubbleType.system) {
          continue;
        } else {
          break;
        }
      }
    }

    DateTime? lastInbound;
    for (var i = c.messages.length - 1; i >= 0; i--) {
      if (c.messages[i].type == MessageBubbleType.incoming) {
        lastInbound = c.messages[i].sentAt;
        break;
      }
    }

    LastMessage? lastMessage;
    if (last != null) {
      final senderType = switch (last.type) {
        MessageBubbleType.incoming => SenderType.contact,
        MessageBubbleType.outgoingAi => SenderType.ai,
        MessageBubbleType.internalNote => SenderType.note,
        MessageBubbleType.system => SenderType.system,
        MessageBubbleType.outgoing || MessageBubbleType.outgoingColleague => SenderType.agent,
      };
      lastMessage = LastMessage(
        id: last.id,
        direction: last.isOutgoing ? MessageDirection.outgoing : MessageDirection.incoming,
        senderType: senderType,
        // Own messages carry the signed-in agent's id; colleagues their name.
        senderId: last.type == MessageBubbleType.outgoing ? meId : null,
        senderName: last.type == MessageBubbleType.outgoing ? null : last.senderName,
        type: switch (last.kind) {
          MessageKind.image || MessageKind.album || MessageKind.video => LastMessageType.image,
          MessageKind.voice => LastMessageType.voice,
          MessageKind.file => LastMessageType.file,
          MessageKind.location => LastMessageType.location,
          MessageKind.sticker => LastMessageType.sticker,
          MessageKind.deleted => LastMessageType.deleted,
          MessageKind.text ||
          MessageKind.contact ||
          MessageKind.template ||
          MessageKind.email ||
          MessageKind.unsupported => LastMessageType.text,
        },
        text: switch (last.kind) {
          MessageKind.location => last.locationLabel,
          MessageKind.contact => last.contactName,
          MessageKind.email => last.emailSubject ?? last.text,
          _ => last.text,
        },
        durationSec: last.mediaDuration?.inSeconds,
        fileName: last.fileName,
        delivery: last.isOutgoing ? last.delivery : null,
        createdAt: last.sentAt,
      );
    }

    final hasAssignee = c.ownership == Ownership.mine || c.ownership == Ownership.colleague;
    return ConversationSummary(
      id: c.id,
      channel: c.channel,
      contact: ContactRef(
        id: c.customer.id,
        name: c.customer.name,
        avatarUrl: c.customer.avatarUrl,
        phone: c.customer.phone,
        email: c.customer.email,
      ),
      status: c.status,
      priority: c.priority,
      assignee: hasAssignee && c.assignee != null
          ? AssigneeRef(id: c.assignee!.id, name: c.assignee!.name, avatarUrl: c.assignee!.avatarUrl)
          : null,
      handledByAi: c.ownership == Ownership.ai,
      lastMessage: lastMessage,
      unreadCount: c.unreadCount,
      waitingSince: c.isClosed ? null : waiting,
      aiSuggestionReady: c.aiSuggestion != null,
      snoozedUntil: c.snoozedUntil,
      waWindowExpiresAt: c.channel == Channel.whatsapp && lastInbound != null
          ? lastInbound.add(const Duration(hours: 24))
          : null,
      isTyping: c.customerTyping,
      lastActivityAt: c.lastActivity,
      tags: [...c.tags, ...c.customer.tags],
      teamIds: teamIds,
      closedAt: c.isClosed ? c.lastActivity : null,
    );
  }
}
