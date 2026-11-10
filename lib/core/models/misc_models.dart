import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class KnowledgeEntry {
  const KnowledgeEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.enabled = true,
    this.usageCount = 0,
    this.keywords = const [],
  });

  final String id;
  final KnowledgeType type;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool enabled;

  /// How many AI replies used this entry in the last 30 days.
  final int usageCount;
  final List<String> keywords;

  KnowledgeEntry copyWith({
    KnowledgeType? type,
    String? title,
    String? body,
    bool? enabled,
    List<String>? keywords,
    DateTime? updatedAt,
  }) => KnowledgeEntry(
    id: id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    updatedAt: updatedAt ?? this.updatedAt,
    enabled: enabled ?? this.enabled,
    usageCount: usageCount,
    keywords: keywords ?? this.keywords,
  );
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.conversationId,
    this.read = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? conversationId;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    conversationId: conversationId,
    read: read ?? this.read,
  );
}

@immutable
class QuickReply {
  const QuickReply({required this.shortcut, required this.title, required this.text});

  final String shortcut;
  final String title;
  final String text;
}

@immutable
class MessageTemplate {
  const MessageTemplate({required this.id, required this.name, required this.body, required this.category});

  final String id;
  final String name;
  final String body;
  final String category;
}

@immutable
class DashboardStats {
  const DashboardStats({
    required this.openConversations,
    required this.openDelta,
    required this.waitingOverSla,
    required this.avgFirstResponse,
    required this.firstResponseDelta,
    required this.resolvedToday,
    required this.resolvedDelta,
    required this.aiResolvedRate,
    required this.aiRateDelta,
    required this.csat,
    required this.hourlyVolume,
    required this.channelShare,
  });

  final int openConversations;
  final double openDelta;
  final int waitingOverSla;
  final Duration avgFirstResponse;
  final double firstResponseDelta;
  final int resolvedToday;
  final double resolvedDelta;
  final double aiResolvedRate;
  final double aiRateDelta;
  final double csat;

  /// Conversations per hour, today (24 values).
  final List<int> hourlyVolume;
  final Map<Channel, int> channelShare;
}

@immutable
class WhatsAppConnection {
  const WhatsAppConnection({
    required this.connected,
    this.phoneNumber,
    this.displayName,
    this.connectedSince,
    this.messagesToday = 0,
    this.loaded = true,
  });

  /// False until the real status arrived (real API): show no status yet.
  final bool loaded;
  final bool connected;
  final String? phoneNumber;
  final String? displayName;
  final DateTime? connectedSince;
  final int messagesToday;
}

@immutable
class AiAgentSettings {
  const AiAgentSettings({
    this.enabled = true,
    this.autoReply = false,
    this.suggestReplies = true,
    this.replyWhenClaimed = false,
    this.handoffOnNegativeSentiment = true,
    this.tone = 'friendly',
    this.agentName = 'وفاء',
    this.repliesUsed = 0,
    this.repliesQuota = 1000,
  });

  final bool enabled;
  final bool autoReply;
  final bool suggestReplies;
  final bool replyWhenClaimed;
  final bool handoffOnNegativeSentiment;
  final String tone; // friendly | formal | concise
  final String agentName;
  final int repliesUsed;
  final int repliesQuota;

  AiAgentSettings copyWith({
    bool? enabled,
    bool? autoReply,
    bool? suggestReplies,
    bool? replyWhenClaimed,
    bool? handoffOnNegativeSentiment,
    String? tone,
    String? agentName,
  }) => AiAgentSettings(
    enabled: enabled ?? this.enabled,
    autoReply: autoReply ?? this.autoReply,
    suggestReplies: suggestReplies ?? this.suggestReplies,
    replyWhenClaimed: replyWhenClaimed ?? this.replyWhenClaimed,
    handoffOnNegativeSentiment: handoffOnNegativeSentiment ?? this.handoffOnNegativeSentiment,
    tone: tone ?? this.tone,
    agentName: agentName ?? this.agentName,
    repliesUsed: repliesUsed,
    repliesQuota: repliesQuota,
  );
}
