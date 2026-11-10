import 'package:flutter/foundation.dart';

import '../../../core/models/models.dart';

/// Where the sheet was opened from (Assign spec §2, analytics `source`).
enum AssignSource { claimBar, menu, swipe, bulk, chip }

extension AssignSourceX on AssignSource {
  String get analyticsName => switch (this) {
    AssignSource.claimBar => 'claim_bar',
    AssignSource.menu => 'menu',
    AssignSource.swipe => 'swipe',
    AssignSource.bulk => 'bulk',
    AssignSource.chip => 'chip',
  };
}

enum AssigneeType { agent, team, ai }

enum TeamRouting { leastBusy, roundRobin, manual }

enum UnassignableReason { deactivated, outOfScope, capacity }

/// `{type, id}` — current assignee, suggestion target, undo target.
@immutable
class AssigneeRef {
  const AssigneeRef(this.type, this.id);

  final AssigneeType type;
  final String id;

  @override
  bool operator ==(Object other) => other is AssigneeRef && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// `AgentAssignee` (§8).
@immutable
class AgentAssignee {
  const AgentAssignee({
    required this.id,
    required this.name,
    required this.firstName,
    this.email = '',
    this.avatarUrl,
    this.gender,
    this.presence = Presence.online,
    this.lastSeenAt,
    this.openConversations = 0,
    this.maxConcurrent,
    this.skills = const [],
    this.teamIds = const [],
    this.assignable = true,
    this.unassignableReason,
  });

  final String id;
  final String name;
  final String firstName;
  final String email;
  final String? avatarUrl;

  /// 'f' | 'm' | null (null → masculine forms).
  final String? gender;
  final Presence presence;
  final DateTime? lastSeenAt;
  final int openConversations;
  final int? maxConcurrent;
  final List<String> skills;
  final List<String> teamIds;
  final bool assignable;
  final UnassignableReason? unassignableReason;

  bool get female => gender == 'f';

  /// open / max, or null without a max.
  double? get load => maxConcurrent == null || maxConcurrent! <= 0 ? null : openConversations / maxConcurrent!;
  bool get atCapacity => maxConcurrent != null && openConversations >= maxConcurrent!;

  /// For the app-wide [Agent] model (inbox assignee, system events).
  Agent toAgent() => Agent(
    id: id,
    name: name,
    email: email,
    presence: presence,
    avatarUrl: avatarUrl,
    openConversations: openConversations,
    gender: gender,
  );

  AgentAssignee copyWith({Presence? presence, int? openConversations, DateTime? lastSeenAt}) => AgentAssignee(
    id: id,
    name: name,
    firstName: firstName,
    email: email,
    avatarUrl: avatarUrl,
    gender: gender,
    presence: presence ?? this.presence,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    openConversations: openConversations ?? this.openConversations,
    maxConcurrent: maxConcurrent,
    skills: skills,
    teamIds: teamIds,
    assignable: assignable,
    unassignableReason: unassignableReason,
  );

  @override
  bool operator ==(Object other) => other is AgentAssignee && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class TeamAssignee {
  const TeamAssignee({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.availableCount,
    required this.routing,
    this.members = const [],
  });

  final String id;
  final String name;
  final int membersCount;
  final int availableCount;
  final TeamRouting routing;
  final List<AgentAssignee> members;

  Team toTeam() => Team(id: id, name: name, memberCount: membersCount);
}

@immutable
class AiAssignee {
  const AiAssignee({required this.enabled, required this.available, this.reasonUnavailable});

  final bool enabled;

  /// false → row disabled with "لا توجد قاعدة معرفة كافية".
  final bool available;
  final String? reasonUnavailable;
}

enum SuggestionReason { handledBefore, skillMatch, leastBusy }

@immutable
class SuggestedAssignee {
  const SuggestedAssignee({required this.ref, required this.reason, this.reasonLabel, this.skill});

  final AssigneeRef ref;
  final SuggestionReason reason;

  /// Server-provided label; the app builds one from [reason] when null.
  final String? reasonLabel;
  final String? skill;
}

/// `GET /api/v1/assignees` (§8).
@immutable
class AssigneesPayload {
  const AssigneesPayload({
    required this.me,
    this.agents = const [],
    this.teams = const [],
    this.ai = const AiAssignee(enabled: false, available: false),
    this.suggested,
    this.current,
    this.capacityEnforced = false,
  });

  final AgentAssignee me;

  /// Colleagues (me excluded).
  final List<AgentAssignee> agents;
  final List<TeamAssignee> teams;
  final AiAssignee ai;
  final SuggestedAssignee? suggested;
  final AssigneeRef? current;
  final bool capacityEnforced;

  AgentAssignee? agentById(String id) {
    if (me.id == id) return me;
    for (final a in agents) {
      if (a.id == id) return a;
    }
    for (final t in teams) {
      for (final m in t.members) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  TeamAssignee? teamById(String id) {
    for (final t in teams) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// The one selected row (§5.6 "single-select across agents/teams/AI/me").
sealed class AssignTarget {
  const AssignTarget();

  AssigneeType get type;
  String get id;
  String get displayName;
  AssigneeRef get ref => AssigneeRef(type, id);

  /// Selection key; a team member picked from the expansion is an agent.
  String get key => '${type.name}:$id';
}

class AgentTarget extends AssignTarget {
  const AgentTarget(this.agent, {this.isMe = false});

  final AgentAssignee agent;
  final bool isMe;

  @override
  AssigneeType get type => AssigneeType.agent;
  @override
  String get id => agent.id;
  @override
  String get displayName => agent.firstName;
}

class TeamTarget extends AssignTarget {
  const TeamTarget(this.team);

  final TeamAssignee team;

  @override
  AssigneeType get type => AssigneeType.team;
  @override
  String get id => team.id;
  @override
  String get displayName => team.name;
}

class AiTarget extends AssignTarget {
  const AiTarget();

  @override
  AssigneeType get type => AssigneeType.ai;
  @override
  String get id => 'ai';
  @override
  String get displayName => 'AI';
}

/// What the sheet hands back (§2 "Returns AssignResult?").
@immutable
class AssignResult {
  const AssignResult({
    required this.target,
    required this.assigneeName,
    required this.succeeded,
    required this.total,
    this.failures = const [],
    this.claimed = false,
    this.unassigned = false,
  });

  final AssignTarget? target;

  /// Who actually got it (a team routes to a member).
  final String assigneeName;
  final List<String> succeeded;
  final int total;
  final List<BulkAssignFailure> failures;

  /// "أنا" on an unassigned conversation went through Claim.
  final bool claimed;
  final bool unassigned;
}

@immutable
class BulkAssignFailure {
  const BulkAssignFailure({required this.conversationId, required this.code});

  final String conversationId;

  /// same_assignee | forbidden | capacity_reached | state_changed | resolved | error
  final String code;
}
