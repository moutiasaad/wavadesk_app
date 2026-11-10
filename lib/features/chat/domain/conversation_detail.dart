import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';

/// What an agent may do in this conversation (`permissions` in §8).
@immutable
class ChatPermissions {
  const ChatPermissions({
    this.canReply = true,
    this.canAssign = true,
    this.canResolve = true,
    this.canDeleteMessages = true,
    this.isAdmin = false,
    this.canClaim = true,
    this.claimTeamName,
    this.canHandToAi,
  });

  final bool canReply;
  final bool canAssign;
  final bool canResolve;
  final bool canDeleteMessages;

  /// Admins see "استلم بدلًا عنه" and "تصدير المحادثة".
  final bool isAdmin;

  /// False when the agent isn't in the conversation's team (Claim spec §2).
  final bool canClaim;

  /// Owning team, for "هذه المحادثة لفريق {team}".
  final String? claimTeamName;

  /// Real API (`can_toggle_ai`): the admin "تولَّ الذكاء الاصطناعي الرد"
  /// action is available. Null when the server omits it (workspace AI setting decides).
  final bool? canHandToAi;
}

/// Conversation header + state for the chat screen (Chat spec §8
/// `GET /conversations/{id}`), built from the shared [Conversation].
@immutable
class ConversationDetail {
  const ConversationDetail({
    required this.conversation,
    required this.permissions,
    required this.aiEnabledInWorkspace,
    required this.aiAutoMode,
    required this.meId,
  });

  final Conversation conversation;
  final ChatPermissions permissions;

  /// AI agent switched on for the workspace.
  final bool aiEnabledInWorkspace;

  /// Workspace AI mode is "auto-reply" (vs suggestions only).
  final bool aiAutoMode;
  final String meId;

  String get id => conversation.id;
  Customer get contact => conversation.customer;
  Channel get channel => conversation.channel;
  ConversationStatus get status => conversation.status;
  Agent? get assignee => conversation.assignee;
  bool get isMine => conversation.ownership == Ownership.mine;
  bool get isUnassigned => conversation.ownership == Ownership.unassigned || conversation.ownership == Ownership.ai;
  bool get handledByAi => conversation.ownership == Ownership.ai && !conversation.aiPaused;
  bool get blocked => contact.blocked;

  /// False for virtual contacts (web chat / Messenger / official WhatsApp
  /// rows the API returns with `contact.id: null`): no profile to open.
  bool get hasProfile => !contact.id.startsWith('virtual-');
  bool get isClosed => conversation.isClosed;
  bool get isOpen => !isClosed && status != ConversationStatus.snoozed;

  /// WhatsApp 24h window: closes 24h after the last inbound message.
  DateTime? get waWindowExpiresAt {
    if (channel != Channel.whatsapp) return null;
    if (!conversation.serviceWindowOpen) return DateTime.fromMillisecondsSinceEpoch(0);
    for (var i = conversation.messages.length - 1; i >= 0; i--) {
      final m = conversation.messages[i];
      if (m.type == MessageBubbleType.incoming) return m.sentAt.add(const Duration(hours: 24));
    }
    return null;
  }

  bool windowClosed(DateTime now) {
    final e = waWindowExpiresAt;
    return e != null && !e.isAfter(now);
  }

  /// First unanswered inbound (for the claim bar's waiting tag).
  DateTime? get waitingSince {
    if (conversation.waitingSince != null) return conversation.waitingSince;
    DateTime? since;
    for (var i = conversation.messages.length - 1; i >= 0; i--) {
      final m = conversation.messages[i];
      if (m.type == MessageBubbleType.incoming) {
        since = m.sentAt;
      } else if (m.type != MessageBubbleType.system && m.type != MessageBubbleType.internalNote) {
        break;
      }
    }
    return since;
  }
}
