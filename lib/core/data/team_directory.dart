import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_session.dart';
import '../api/wd_api.dart';
import '../api/wd_api_provider.dart';
import '../models/models.dart';
import '../state/load_state.dart';

/// Workspace members + teams (`GET /mobile/v1/team`). Feeds the Team screen,
/// `colleaguesProvider` and `teamsProvider` (filters, mentions, pickers).
@immutable
class TeamDirectoryState {
  const TeamDirectoryState({
    this.members = const [],
    this.teams = const [],
    this.meId,
    this.teamsEnabled = true,
    this.seatsUsed = 0,
    this.seatsMax,
    this.canAddUser = true,
    this.phase = LoadPhase.loading,
    this.error,
  });

  /// Everyone, the signed-in user included (see [meId]).
  final List<Agent> members;
  final List<Team> teams;
  final String? meId;
  final bool teamsEnabled;

  /// Plan seats (`meta.limits.users`): accounts in the workspace vs the
  /// plan's max (+ bought seats). [seatsMax] null = unlimited.
  final int seatsUsed;
  final int? seatsMax;
  final bool canAddUser;

  final LoadPhase phase;

  /// Last failure (kept alongside data after a failed refresh).
  final Object? error;

  List<Agent> get colleagues => [for (final a in members) if (a.id != meId) a];

  TeamDirectoryState copyWith({LoadPhase? phase, Object? error, bool clearError = false}) => TeamDirectoryState(
        members: members,
        teams: teams,
        meId: meId,
        teamsEnabled: teamsEnabled,
        seatsUsed: seatsUsed,
        seatsMax: seatsMax,
        canAddUser: canAddUser,
        phase: phase ?? this.phase,
        error: clearError ? null : error ?? this.error,
      );
}

final teamDirectoryProvider = NotifierProvider<TeamDirectoryController, TeamDirectoryState>(TeamDirectoryController.new);

class TeamDirectoryController extends Notifier<TeamDirectoryState> {
  static const _cacheKey = 'team_directory';
  bool _inFlight = false;

  @override
  TeamDirectoryState build() {
    // A new sign-in starts over (the cache is cleared on sign-out).
    ref.watch(authProvider);
    scheduleMicrotask(refresh);
    return MemoryCache.get<TeamDirectoryState>(_cacheKey) ?? const TeamDirectoryState();
  }

  /// Silent when data is already on screen; a failure then keeps it.
  Future<void> refresh() async {
    if (_inFlight) return;
    final api = ref.read(wdApiProvider);
    if (api == null) return;
    _inFlight = true;
    if (state.phase == LoadPhase.error) state = state.copyWith(phase: LoadPhase.loading, clearError: true);
    try {
      final r = await api.get('team');
      final next = _parse(r);
      MemoryCache.put(_cacheKey, next);
      state = next;
    } catch (e) {
      state = state.copyWith(phase: state.phase == LoadPhase.ready ? LoadPhase.ready : LoadPhase.error, error: e);
    } finally {
      _inFlight = false;
    }
  }

  static AgentRole _role(Object? v) => switch (v) {
        'admin' || 'tenant_admin' || 'owner' => AgentRole.admin,
        'supervisor' => AgentRole.supervisor,
        _ => AgentRole.agent,
      };

  static Presence _presence(Object? v) => switch (v) {
        'online' => Presence.online,
        'busy' => Presence.busy,
        _ => Presence.away, // away / offline
      };

  static TeamDirectoryState _parse(WdResponse r) {
    final d = r.map;
    String? meId;
    final members = <Agent>[];
    for (final m in (d['members'] as List? ?? const [])) {
      if (m is! Map) continue;
      final id = '${m['id']}';
      if (m['is_me'] == true) meId = id;
      members.add(Agent(
        id: id,
        name: '${m['name'] ?? ''}',
        email: '',
        role: _role(m['role']),
        presence: _presence(m['presence']),
        avatarUrl: m['avatar_url'] as String?,
        openConversations: (m['open'] as num?)?.toInt() ?? 0,
      ));
    }
    final teams = [
      for (final t in (d['teams'] as List? ?? const []))
        if (t is Map) Team(id: '${t['id']}', name: '${t['name'] ?? ''}', memberCount: (t['member_ids'] as List?)?.length ?? 0),
    ];
    final limits = r.meta['limits'];
    final users = limits is Map ? limits['users'] : null;
    final teamsAllowed = limits is Map && limits['teams'] is Map ? limits['teams']['allowed'] : null;
    return TeamDirectoryState(
      members: members,
      teams: teams,
      meId: meId,
      teamsEnabled: teamsAllowed is bool ? teamsAllowed : r.meta['teams_enabled'] != false,
      seatsUsed: users is Map ? (users['used'] as num?)?.toInt() ?? members.length : members.length,
      seatsMax: users is Map ? (users['max'] as num?)?.toInt() : null,
      // Older servers send no limits: let the server decide on submit.
      canAddUser: users is Map ? users['can_create'] != false : true,
      phase: LoadPhase.ready,
    );
  }
}
