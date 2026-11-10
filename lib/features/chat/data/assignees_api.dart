import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/api/wd_api.dart';
import '../../../core/api/wd_api_provider.dart';
import '../domain/assignee.dart';

class AssignApiException implements Exception {
  const AssignApiException(this.code, {this.statusCode = 0, this.currentAssigneeName, this.max});

  /// network | state_changed | forbidden | capacity_reached | error
  final String code;
  final int statusCode;

  /// 409 `current_assignee.name`.
  final String? currentAssigneeName;

  /// 422 capacity `max`.
  final int? max;

  bool get isNetwork => code == 'network';

  @override
  String toString() => 'AssignApiException($code)';
}

/// Who actually received the conversation (a team may route to a member).
class AssignedTo {
  const AssignedTo({required this.type, required this.id, required this.name, this.agent});

  /// `null` type = back to unassigned / team queue.
  final AssigneeType? type;
  final String? id;
  final String name;
  final AgentAssignee? agent;
}

class BulkAssignResponse {
  const BulkAssignResponse({required this.succeeded, required this.failed, required this.assignedTo});

  final List<String> succeeded;
  final List<BulkAssignFailure> failed;
  final Map<String, AssignedTo> assignedTo;
}

abstract interface class AssigneesApi {
  /// Last successful payload for these ids — offline list (§6).
  AssigneesPayload? cached(List<String> conversationIds);

  Future<AssigneesPayload> load(List<String> conversationIds);

  /// `assigneeType == null` → unassign. [expectedCurrent] lets the sample
  /// backend detect a takeover (the real server checks its own state).
  Future<AssignedTo> assign(
    String conversationId, {
    required AssigneeType? assigneeType,
    required String? assigneeId,
    String? note,
    required String idempotencyKey,
    AssigneeRef? expectedCurrent,
  });

  Future<BulkAssignResponse> bulk(
    List<String> ids, {
    required AssigneeType assigneeType,
    required String assigneeId,
    String? note,
  });
}

final assigneesApiProvider = Provider<AssigneesApi>((ref) {
  if (!useRealApi) return SampleAssigneesApi(ref);
  return HttpAssigneesApi(ref.read(wdApiRequiredProvider));
});

// ---- JSON ----------------------------------------------------------------------------

Presence _presence(Object? p) => switch (p) {
  'busy' => Presence.busy,
  'away' || 'offline' => Presence.away,
  _ => Presence.online,
};

AssigneeType? _type(Object? t) => switch (t) {
  'agent' => AssigneeType.agent,
  'team' => AssigneeType.team,
  'ai' => AssigneeType.ai,
  _ => null,
};

AgentAssignee agentAssigneeFromJson(Map<String, dynamic> j) {
  final name = (j['name'] as String?) ?? '';
  return AgentAssignee(
    id: '${j['id']}',
    name: name,
    firstName: (j['first_name'] as String?) ?? name.split(' ').first,
    email: (j['email'] as String?) ?? '',
    avatarUrl: j['avatar_url'] as String?,
    gender: j['gender'] as String?,
    presence: _presence(j['presence']),
    lastSeenAt: DateTime.tryParse('${j['last_seen_at'] ?? ''}')?.toLocal(),
    openConversations: (j['open_conversations'] as num?)?.toInt() ?? 0,
    maxConcurrent: (j['max_concurrent'] as num?)?.toInt(),
    skills: [for (final s in (j['skills'] as List? ?? const [])) '$s'],
    teamIds: [for (final s in (j['team_ids'] as List? ?? const [])) '$s'],
    assignable: j['assignable'] != false,
    unassignableReason: switch (j['unassignable_reason']) {
      'deactivated' => UnassignableReason.deactivated,
      'out_of_scope' => UnassignableReason.outOfScope,
      'capacity' => UnassignableReason.capacity,
      _ => null,
    },
  );
}

AssigneesPayload assigneesPayloadFromJson(Map<String, dynamic> j) {
  List<AgentAssignee> agents(Object? raw) => [
    for (final a in (raw as List? ?? const []))
      if (a is Map) agentAssigneeFromJson(Map<String, dynamic>.from(a)),
  ];
  final s = j['suggested'];
  final cur = j['current'];
  final ai = j['ai'] is Map ? Map<String, dynamic>.from(j['ai'] as Map) : const <String, dynamic>{};
  return AssigneesPayload(
    me: agentAssigneeFromJson(Map<String, dynamic>.from(j['me'] as Map)),
    agents: agents(j['agents']),
    teams: [
      for (final t in (j['teams'] as List? ?? const []))
        if (t is Map)
          TeamAssignee(
            id: '${t['id']}',
            name: '${t['name']}',
            membersCount: (t['members_count'] as num?)?.toInt() ?? 0,
            availableCount: (t['available_count'] as num?)?.toInt() ?? 0,
            routing: switch (t['routing']) {
              'round_robin' => TeamRouting.roundRobin,
              'manual' => TeamRouting.manual,
              _ => TeamRouting.leastBusy,
            },
            members: agents(t['members']),
          ),
    ],
    ai: AiAssignee(
      enabled: ai['enabled'] == true,
      available: ai['available'] != false,
      reasonUnavailable: ai['reason_unavailable'] as String?,
    ),
    suggested: s is Map && _type(s['type']) != null
        ? SuggestedAssignee(
            ref: AssigneeRef(_type(s['type'])!, '${s['id']}'),
            reason: switch (s['reason_code']) {
              'handled_before' => SuggestionReason.handledBefore,
              'skill_match' => SuggestionReason.skillMatch,
              _ => SuggestionReason.leastBusy,
            },
            reasonLabel: s['reason_label'] as String?,
            skill: s['skill'] as String?,
          )
        : null,
    current: cur is Map && _type(cur['type']) != null ? AssigneeRef(_type(cur['type'])!, '${cur['id']}') : null,
    capacityEnforced: j['capacity_enforced'] == true,
  );
}

// ---- HTTP (/mobile/v1) ---------------------------------------------------------------

/// `GET /mobile/v1/assignees` row → [AgentAssignee]. The server only offers
/// agents eligible for every selected conversation; "offline" shows as away.
AgentAssignee _mobileAgent(Map<String, dynamic> j, {bool? assignable}) {
  final name = (j['name'] as String?) ?? '';
  return AgentAssignee(
    id: '${j['id']}',
    name: name,
    firstName: name.split(' ').first,
    email: '',
    avatarUrl: j['avatar_url'] as String?,
    presence: _presence(j['presence']),
    openConversations: (j['open_load'] as num?)?.toInt() ?? 0,
    teamIds: [
      for (final t in (j['teams'] as List? ?? const []))
        if (t is Map) '${t['id']}',
    ],
    assignable: assignable ?? true,
    unassignableReason: assignable == false ? UnassignableReason.outOfScope : null,
  );
}

AssigneesPayload assigneesPayloadFromMobile(Map<String, dynamic> j) {
  final agents = [
    for (final a in (j['agents'] as List? ?? const []))
      if (a is Map) _mobileAgent(Map<String, dynamic>.from(a)),
  ];
  final me = Map<String, dynamic>.from(j['me'] as Map? ?? const {});
  final s = j['suggested'];
  final cur = j['current'];
  final ai = j['ai'] is Map ? Map<String, dynamic>.from(j['ai'] as Map) : const <String, dynamic>{};
  return AssigneesPayload(
    me: _mobileAgent(me, assignable: me['eligible'] != false),
    agents: agents,
    teams: [
      for (final t in (j['teams'] as List? ?? const []))
        if (t is Map)
          TeamAssignee(
            id: '${t['id']}',
            name: '${t['name']}',
            membersCount: (t['members'] as num?)?.toInt() ?? 0,
            availableCount: agents
                .where((a) => a.teamIds.contains('${t['id']}') && a.presence == Presence.online)
                .length,
            routing: TeamRouting.leastBusy,
            members: [
              for (final a in agents)
                if (a.teamIds.contains('${t['id']}')) a,
            ],
          ),
    ],
    ai: AiAssignee(enabled: ai['available'] == true, available: ai['available'] == true),
    suggested: s is Map && s['id'] != null
        ? SuggestedAssignee(ref: AssigneeRef(AssigneeType.agent, '${s['id']}'), reason: SuggestionReason.leastBusy)
        : null,
    current: cur is Map && cur['id'] != null ? AssigneeRef(AssigneeType.agent, '${cur['id']}') : null,
    capacityEnforced: j['capacity_enforced'] == true,
  );
}

class HttpAssigneesApi implements AssigneesApi {
  HttpAssigneesApi(this._api);

  final WdApi _api;
  final _cache = <String, AssigneesPayload>{};

  String _key(List<String> ids) => ids.join(',');

  static AssignApiException _mapError(WdApiException e) {
    if (e.isNetwork) return const AssignApiException('network');
    final who = e.details['assignee'];
    return switch (e.code) {
      'already_assigned' || 'invalid_state' || 'conversation_resolved' => AssignApiException(
        'state_changed',
        statusCode: e.status,
        currentAssigneeName: who is Map ? who['name'] as String? : null,
      ),
      'role_forbidden' || 'not_in_team' || 'not_your_conversation' || 'module_unavailable' || 'forbidden' =>
        AssignApiException('forbidden', statusCode: e.status),
      _ when e.status == 403 => AssignApiException('forbidden', statusCode: e.status),
      _ => AssignApiException('error', statusCode: e.status),
    };
  }

  Future<WdResponse> _call(Future<WdResponse> Function() f) async {
    try {
      return await f();
    } on WdApiException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  AssigneesPayload? cached(List<String> ids) => _cache[_key(ids)];

  @override
  Future<AssigneesPayload> load(List<String> ids) async {
    final q = ids.length == 1 ? {'conversation_id': ids.first} : {'conversation_ids': ids.join(',')};
    final r = await _call(() => _api.get('assignees', query: q));
    final p = assigneesPayloadFromMobile(r.map);
    _cache[_key(ids)] = p;
    return p;
  }

  static Map<String, Object?> _assignee(AssigneeType? type, String? id) => {
    'type': switch (type) {
      AssigneeType.agent => 'agent',
      AssigneeType.team => 'team',
      AssigneeType.ai => 'ai',
      null => 'none',
    },
    if (type == AssigneeType.agent || type == AssigneeType.team) 'id': id,
  };

  @override
  Future<AssignedTo> assign(
    String conversationId, {
    required AssigneeType? assigneeType,
    required String? assigneeId,
    String? note,
    required String idempotencyKey,
    AssigneeRef? expectedCurrent,
  }) async {
    final r = await _call(
      () => _api.post(
        'conversations/$conversationId/assign',
        idempotencyKey: idempotencyKey,
        body: {
          'assignee': _assignee(assigneeType, assigneeId),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      ),
    );
    return _assignedToFromDetail(r.map, assigneeType);
  }

  /// Reads who holds the conversation from the returned detail.
  static AssignedTo _assignedToFromDetail(Map<String, dynamic> d, AssigneeType? requested) {
    final a = d['assignee'];
    if (a is Map && a['id'] != null) {
      final m = Map<String, dynamic>.from(a);
      return AssignedTo(type: AssigneeType.agent, id: '${m['id']}', name: '${m['name'] ?? ''}', agent: _mobileAgent(m));
    }
    final t = d['team'];
    if (requested == AssigneeType.team && t is Map) {
      return AssignedTo(type: AssigneeType.team, id: '${t['id']}', name: '${t['name'] ?? ''}');
    }
    if (requested == AssigneeType.ai || d['ai_handling'] == true) {
      return const AssignedTo(type: AssigneeType.ai, id: 'ai', name: '');
    }
    return const AssignedTo(type: null, id: null, name: '');
  }

  @override
  Future<BulkAssignResponse> bulk(
    List<String> ids, {
    required AssigneeType assigneeType,
    required String assigneeId,
    String? note,
  }) async {
    final r = await _call(
      () => _api.post(
        'conversations/bulk',
        body: {'action': 'assign', 'ids': ids, 'assignee': _assignee(assigneeType, assigneeId)},
      ),
    );
    final results = [
      for (final x in (r.map['results'] as List? ?? const []))
        if (x is Map) Map<String, dynamic>.from(x),
    ];
    final to = AssignedTo(type: assigneeType, id: assigneeId, name: '');
    return BulkAssignResponse(
      succeeded: [
        for (final x in results)
          if (x['ok'] == true) '${x['id']}',
      ],
      failed: [
        for (final x in results)
          if (x['ok'] != true)
            BulkAssignFailure(
              conversationId: '${x['id']}',
              code: switch ((x['error'] is Map ? (x['error'] as Map)['code'] : null) as String?) {
                'already_assigned' || 'invalid_state' => 'state_changed',
                'conversation_resolved' => 'resolved',
                'role_forbidden' || 'not_in_team' || 'not_your_conversation' => 'forbidden',
                _ => 'error',
              },
            ),
      ],
      assignedTo: {
        for (final x in results)
          if (x['ok'] == true) '${x['id']}': to,
      },
    );
  }
}

// ---- Sample --------------------------------------------------------------------------

/// Builds the §8 payload from `assets/fake/agents.json` + the in-memory
/// inbox. Rules: unassignable agents → 403, at capacity with
/// `hard_capacity_limit` → 422, the conversation changed since the sheet
/// saw it → 409, offline → network error.
class SampleAssigneesApi implements AssigneesApi {
  SampleAssigneesApi(this._ref);

  final Ref _ref;
  static int _roundRobin = 0;
  static const _latency = Duration(milliseconds: 650);

  Map<String, dynamic> get _json => MockData.agentsJson;
  Map<String, dynamic> get _assignCfg =>
      _json['assign'] is Map ? Map<String, dynamic>.from(_json['assign'] as Map) : const {};

  Conversation? _conv(String id) => _ref.read(inboxProvider.notifier).byId(id);

  bool get _offline => _ref.read(inboxProvider).network == NetworkState.offline;

  AgentAssignee _agent(Map<String, dynamic> raw, {required String meId, required List<String> myTeams}) {
    final m = Map<String, dynamic>.from(raw);
    final ago = (m['last_seen_ago_minutes'] as num?)?.toInt();
    final max = (m['max_concurrent'] as num?)?.toInt() ?? MockData.maxConcurrent;
    final open = (m['open_conversations'] as num?)?.toInt() ?? 0;
    final scope = _assignCfg['assign_scope'];
    final teamIds = [for (final t in (m['team_ids'] as List? ?? const [])) '$t'];
    final outOfScope = scope == 'own_teams' && m['id'] != meId && !teamIds.any(myTeams.contains);
    final capacityBlocked = MockData.hardCapacityLimit && open >= max;
    final base = agentAssigneeFromJson({
      ...m,
      'max_concurrent': max,
      if (ago != null) 'last_seen_at': DateTime.now().subtract(Duration(minutes: ago)).toUtc().toIso8601String(),
    });
    if (outOfScope || capacityBlocked) {
      return AgentAssignee(
        id: base.id,
        name: base.name,
        firstName: base.firstName,
        email: base.email,
        gender: base.gender,
        presence: base.presence,
        lastSeenAt: base.lastSeenAt,
        openConversations: base.openConversations,
        maxConcurrent: base.maxConcurrent,
        skills: base.skills,
        teamIds: base.teamIds,
        assignable: false,
        unassignableReason: outOfScope ? UnassignableReason.outOfScope : UnassignableReason.capacity,
      );
    }
    return base;
  }

  AssigneeRef? _currentOf(Conversation? c) {
    if (c == null) return null;
    return switch (c.ownership) {
      Ownership.ai => const AssigneeRef(AssigneeType.ai, 'ai'),
      Ownership.unassigned => null,
      _ => c.assignee == null ? null : AssigneeRef(AssigneeType.agent, c.assignee!.id),
    };
  }

  AssigneesPayload _build(List<String> ids) {
    final meRaw = Map<String, dynamic>.from(_json['me'] as Map);
    final meId = '${meRaw['id']}';
    final myTeams = [for (final t in (meRaw['team_ids'] as List? ?? const [])) '$t'];
    final me = _agent(meRaw, meId: meId, myTeams: myTeams);
    final colleagues = [
      for (final a in (_json['colleagues'] as List? ?? const []))
        _agent(Map<String, dynamic>.from(a as Map), meId: meId, myTeams: myTeams),
    ];
    final all = {me.id: me, for (final a in colleagues) a.id: a};
    final teams = [
      for (final t in (_json['teams'] as List? ?? const []))
        () {
          final m = Map<String, dynamic>.from(t as Map);
          final members = [for (final id in (m['member_ids'] as List? ?? const [])) ?all['$id']];
          return TeamAssignee(
            id: '${m['id']}',
            name: '${m['name']}',
            membersCount: members.isEmpty ? (m['member_count'] as num?)?.toInt() ?? 0 : members.length,
            availableCount: members.where((x) => x.presence == Presence.online && x.assignable).length,
            routing: switch (m['routing']) {
              'round_robin' => TeamRouting.roundRobin,
              'manual' => TeamRouting.manual,
              _ => TeamRouting.leastBusy,
            },
            members: members,
          );
        }(),
    ];

    final single = ids.length == 1 ? _conv(ids.first) : null;
    final current = _currentOf(single);
    SuggestedAssignee? suggested;
    if (single != null) {
      final cfg = _assignCfg['suggested'];
      final raw = cfg is Map ? cfg[single.id] : null;
      if (raw is Map) {
        suggested = SuggestedAssignee(
          ref: AssigneeRef(raw['type'] == 'team' ? AssigneeType.team : AssigneeType.agent, '${raw['id']}'),
          reason: switch (raw['reason_code']) {
            'handled_before' => SuggestionReason.handledBefore,
            'skill_match' => SuggestionReason.skillMatch,
            _ => SuggestionReason.leastBusy,
          },
          skill: raw['skill'] as String?,
        );
      } else {
        // A colleague who replied in this conversation before.
        String? handled;
        for (final m in single.messages.reversed) {
          final s = m.senderId;
          if (m.type == MessageBubbleType.outgoing && s != null && s != meId && all[s]?.assignable == true) {
            handled = s;
            break;
          }
        }
        if (handled != null && handled != current?.id) {
          suggested = SuggestedAssignee(
            ref: AssigneeRef(AssigneeType.agent, handled),
            reason: SuggestionReason.handledBefore,
          );
        } else {
          final free =
              colleagues.where((a) => a.presence == Presence.online && a.assignable && a.id != current?.id).toList()
                ..sort((a, b) => a.openConversations.compareTo(b.openConversations));
          if (free.isNotEmpty) {
            suggested = SuggestedAssignee(
              ref: AssigneeRef(AssigneeType.agent, free.first.id),
              reason: SuggestionReason.leastBusy,
            );
          }
        }
      }
    }
    final channelOk = single == null || single.channel != Channel.email;
    return AssigneesPayload(
      me: me,
      agents: colleagues,
      teams: teams,
      ai: AiAssignee(
        enabled: _assignCfg['ai_enabled'] != false && channelOk,
        available: _assignCfg['ai_kb_ready'] != false,
      ),
      suggested: suggested,
      current: current,
      capacityEnforced: MockData.hardCapacityLimit,
    );
  }

  @override
  AssigneesPayload? cached(List<String> ids) => _build(ids);

  @override
  Future<AssigneesPayload> load(List<String> ids) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_offline) throw const AssignApiException('network');
    return _build(ids);
  }

  /// Team routing (§5.7): least busy available member, next in rotation,
  /// or — manual / nobody available — the team queue (unassigned).
  AssignedTo _route(TeamAssignee team) {
    final available = team.members.where((m) => m.presence == Presence.online && m.assignable).toList();
    if (team.routing == TeamRouting.manual || available.isEmpty) {
      return AssignedTo(type: null, id: null, name: team.name);
    }
    final pick = team.routing == TeamRouting.roundRobin
        ? available[_roundRobin++ % available.length]
        : (available..sort((a, b) => a.openConversations.compareTo(b.openConversations))).first;
    return AssignedTo(type: AssigneeType.agent, id: pick.id, name: pick.name, agent: pick);
  }

  AssignedTo _check(String id, AssigneeType? type, String? assigneeId, AssigneesPayload p) {
    final c = _conv(id);
    if (c == null || c.isClosed) throw const AssignApiException('state_changed', statusCode: 409);
    switch (type) {
      case null:
        return const AssignedTo(type: null, id: null, name: '');
      case AssigneeType.ai:
        if (!p.ai.enabled || !p.ai.available) throw const AssignApiException('forbidden', statusCode: 403);
        return const AssignedTo(type: AssigneeType.ai, id: 'ai', name: 'AI');
      case AssigneeType.team:
        final t = p.teamById(assigneeId ?? '');
        if (t == null) throw const AssignApiException('forbidden', statusCode: 403);
        return _route(t);
      case AssigneeType.agent:
        final a = p.agentById(assigneeId ?? '');
        if (a == null) throw const AssignApiException('forbidden', statusCode: 403);
        if (!a.assignable) {
          throw a.unassignableReason == UnassignableReason.capacity
              ? AssignApiException('capacity_reached', statusCode: 422, max: a.maxConcurrent)
              : const AssignApiException('forbidden', statusCode: 403);
        }
        return AssignedTo(type: AssigneeType.agent, id: a.id, name: a.name, agent: a);
    }
  }

  @override
  Future<AssignedTo> assign(
    String conversationId, {
    required AssigneeType? assigneeType,
    required String? assigneeId,
    String? note,
    required String idempotencyKey,
    AssigneeRef? expectedCurrent,
  }) async {
    await Future<void>.delayed(_latency);
    if (_offline) throw const AssignApiException('network');
    final c = _conv(conversationId);
    final now = _currentOf(c);
    if (now != expectedCurrent) {
      throw AssignApiException('state_changed', statusCode: 409, currentAssigneeName: c?.assignee?.name);
    }
    return _check(conversationId, assigneeType, assigneeId, _build([conversationId]));
  }

  @override
  Future<BulkAssignResponse> bulk(
    List<String> ids, {
    required AssigneeType assigneeType,
    required String assigneeId,
    String? note,
  }) async {
    await Future<void>.delayed(_latency);
    if (_offline) throw const AssignApiException('network');
    final p = _build(ids);
    final ok = <String>[];
    final failed = <BulkAssignFailure>[];
    final to = <String, AssignedTo>{};
    for (final id in ids) {
      final c = _conv(id);
      if (c == null || c.isClosed) {
        failed.add(BulkAssignFailure(conversationId: id, code: 'resolved'));
        continue;
      }
      if (_currentOf(c) == AssigneeRef(assigneeType, assigneeId)) {
        failed.add(BulkAssignFailure(conversationId: id, code: 'same_assignee'));
        continue;
      }
      try {
        to[id] = _check(id, assigneeType, assigneeId, p);
        ok.add(id);
      } on AssignApiException catch (e) {
        failed.add(BulkAssignFailure(conversationId: id, code: e.code));
      }
    }
    return BulkAssignResponse(succeeded: ok, failed: failed, assignedTo: to);
  }
}
