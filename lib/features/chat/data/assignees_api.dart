import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
