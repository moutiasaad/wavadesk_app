/// Domain enums (§12.3: variants are enums).
library;

enum Channel { whatsapp, web, messenger, instagram, email, telegram, sms, other }

extension ChannelX on Channel {
  /// Channels where the chat header shows a call action (§8.1).
  bool get supportsCall => this == Channel.whatsapp || this == Channel.sms;

  /// WhatsApp enforces the 24h customer-service window (§8.6).
  bool get hasServiceWindow => this == Channel.whatsapp;
}

enum ConversationStatus { open, pending, waiting, snoozed, resolved, closed, ai }

enum Priority { urgent, high, medium, low }

enum Presence { online, busy, away }

/// Ownership state shown on every conversation (§2.4).
enum Ownership { mine, unassigned, colleague, ai }

enum AgentRole { admin, supervisor, agent }

enum MessageBubbleType { incoming, outgoing, outgoingAi, outgoingColleague, internalNote, system }

enum MessageKind {
  text,
  image,
  album,
  video,
  voice,
  file,
  location,
  contact,
  sticker,
  template,
  email,
  deleted,
  unsupported,
}

enum DeliveryState { sending, sent, delivered, read, failed }

/// Segmented control on the conversations list (§9.1).
enum InboxSegment { mine, unassigned, all }

/// Quick filter chips row on the conversations list (§9.1).
enum QuickFilter { all, unread, awaitingReply, aiReplied, closed }

enum NetworkState { online, connecting, offline }

enum DateRangeFilter { any, today, last7, last30, custom }

enum AssigneeFilter { all, me, colleague, ai, unassigned }

enum KnowledgeType { faq, policy, product, snippet, website }

enum NotificationKind { assigned, mention, waiting, aiHandoff, resolved, system }
