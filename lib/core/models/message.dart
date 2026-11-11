import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class QuotedMessage {
  const QuotedMessage({required this.sender, required this.text, this.messageId});

  final String sender;
  final String text;

  /// Original message, for tap → scroll + highlight.
  final String? messageId;
}

@immutable
class Reaction {
  const Reaction({required this.emoji, required this.byContact});

  final String emoji;
  final bool byContact;
}

/// System event kinds (Chat spec §9).
enum SystemEventKind {
  claimed,
  assigned,
  unassigned,
  aiHandoff,
  aiPaused,
  aiResumed,
  resolved,
  reopened,
  snoozed,
  priority,
  tagAdded,
  windowClosed,
  blocked,
  unblocked,
  started,

  /// "اتصل {actor} بالعميل" (Profile spec §7.4, optional).
  called,

  /// "ألغى {actor} الإسناد" — Undo after an assignment (Assign spec §7).
  assignUndone,
}

@immutable
class SystemEvent {
  const SystemEvent({required this.kind, this.actorId, this.actorName, this.target, this.value});

  final SystemEventKind kind;
  final String? actorId;
  final String? actorName;

  /// Assignee name, etc.
  final String? target;

  /// Priority label, tag, snooze time (ISO), handoff reason, channel…
  final String? value;
}

@immutable
class Message {
  const Message({
    required this.id,
    required this.type,
    required this.sentAt,
    this.kind = MessageKind.text,
    this.text = '',
    this.senderName,
    this.senderId,
    this.delivery = DeliveryState.read,
    this.quote,
    this.mediaDuration,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.locationLabel,
    this.aiSource,
    this.aiConfidence,
    this.reactions = const [],
    this.edited = false,
    this.mentions = const [],
    this.templateName,
    this.templateButtons = const [],
    this.albumCount = 0,
    this.contactName,
    this.contactPhone,
    this.emailSubject,
    this.systemEvent,
    this.transcript,
    this.retries = 0,
    this.sentVia,
    this.aiFeedback,
    this.mediaAvailable = true,
  });

  final String id;
  final MessageBubbleType type;
  final MessageKind kind;
  final String text;
  final DateTime sentAt;

  /// Agent name for colleague bubbles / notes.
  final String? senderName;
  final String? senderId;
  final DeliveryState delivery;
  final QuotedMessage? quote;
  final Duration? mediaDuration;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final String? locationLabel;

  /// Knowledge source the AI reply was drafted from.
  final String? aiSource;
  final double? aiConfidence;
  final List<Reaction> reactions;
  final bool edited;

  /// @mentioned teammates in internal notes.
  final List<String> mentions;
  final String? templateName;
  final List<String> templateButtons;

  /// Number of images in an album.
  final int albumCount;
  final String? contactName;
  final String? contactPhone;
  final String? emailSubject;
  final SystemEvent? systemEvent;

  /// AI transcript of a voice message (after "تحويل لنص").
  final String? transcript;

  /// Send attempts so far (offline queue, max 3).
  final int retries;

  /// manual | ai_suggestion | ai_edited | quick_reply | template
  final String? sentVia;

  /// 'up' / 'down' feedback on an AI reply.
  final String? aiFeedback;

  /// The server holds the media file (false while it is still fetching an
  /// incoming WhatsApp photo, or for media it could not get).
  final bool mediaAvailable;

  bool get isOutgoing =>
      type == MessageBubbleType.outgoing ||
      type == MessageBubbleType.outgoingAi ||
      type == MessageBubbleType.outgoingColleague;

  /// Sender grouping key for bubble tails and spacing (§5, §6).
  String get senderKey => switch (type) {
    MessageBubbleType.incoming => 'customer',
    MessageBubbleType.outgoing => 'me',
    MessageBubbleType.outgoingAi => 'ai',
    MessageBubbleType.outgoingColleague => 'colleague:$senderName',
    MessageBubbleType.internalNote => 'note:$senderName',
    MessageBubbleType.system => 'system:$id',
  };

  Message copyWith({
    DeliveryState? delivery,
    List<Reaction>? reactions,
    String? transcript,
    int? retries,
    String? aiFeedback,
    MessageKind? kind,
    String? text,
    String? mediaUrl,
  }) => Message(
    id: id,
    type: type,
    kind: kind ?? this.kind,
    text: text ?? this.text,
    sentAt: sentAt,
    senderName: senderName,
    senderId: senderId,
    delivery: delivery ?? this.delivery,
    quote: quote,
    mediaDuration: mediaDuration,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    fileName: fileName,
    fileSize: fileSize,
    locationLabel: locationLabel,
    aiSource: aiSource,
    aiConfidence: aiConfidence,
    reactions: reactions ?? this.reactions,
    edited: edited,
    mentions: mentions,
    templateName: templateName,
    templateButtons: templateButtons,
    albumCount: albumCount,
    contactName: contactName,
    contactPhone: contactPhone,
    emailSubject: emailSubject,
    systemEvent: systemEvent,
    transcript: transcript ?? this.transcript,
    retries: retries ?? this.retries,
    sentVia: sentVia,
    aiFeedback: aiFeedback ?? this.aiFeedback,
    mediaAvailable: mediaAvailable,
  );
}
