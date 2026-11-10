import 'package:flutter/foundation.dart';

import 'enums.dart';

@immutable
class Agent {
  const Agent({
    required this.id,
    required this.name,
    required this.email,
    this.role = AgentRole.agent,
    this.presence = Presence.online,
    this.avatarUrl,
    this.openConversations = 0,
    this.gender,
  });

  final String id;
  final String name;
  final String email;
  final AgentRole role;
  final Presence presence;
  final String? avatarUrl;
  final int openConversations;

  /// 'f' / 'm' when the API provides it — picks Arabic verb forms
  /// ("تشاهد" / "يشاهد"). Null → masculine (Claim spec §4.2.1).
  final String? gender;

  bool get canManage => role != AgentRole.agent;
  bool get isAdmin => role == AgentRole.admin;

  Agent copyWith({Presence? presence, int? openConversations}) => Agent(
    id: id,
    name: name,
    email: email,
    role: role,
    presence: presence ?? this.presence,
    avatarUrl: avatarUrl,
    openConversations: openConversations ?? this.openConversations,
    gender: gender,
  );

  @override
  bool operator ==(Object other) => other is Agent && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class Team {
  const Team({required this.id, required this.name, required this.memberCount});

  final String id;
  final String name;
  final int memberCount;
}
