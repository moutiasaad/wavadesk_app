import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../data/assignees_api.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../domain/assignee.dart';
import '../domain/assignee_sorter.dart';
import 'claim_controller.dart';

enum AssignFilter { all, available, myTeam }

/// One sheet opening (unique per open — §7 state is not kept across opens).
@immutable
class AssignArgs {
  AssignArgs({required this.conversationIds, required this.source})
    : sessionId = '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  static int _seq = 0;

  final String sessionId;
  final List<String> conversationIds;
  final AssignSource source;

  bool get bulk => conversationIds.length > 1;

  @override
  bool operator ==(Object other) => other is AssignArgs && other.sessionId == sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

@immutable
class AssignState {
  const AssignState({
    this.payload,
    this.loading = true,
    this.loadFailed = false,
    this.query = '',
    this.filter = AssignFilter.all,
    this.selected,
    this.selectedFromSuggestion = false,
    this.expandedTeams = const {},
    this.submitting = false,
    this.takenLiveBy,
    this.expectedCurrent,
    this.offline = false,
    this.resolvedWhileOpen = false,
    this.capacityErrorKey,
    this.capacityMax,
    this.agentOrder = const [],
  });

  final AssigneesPayload? payload;
  final bool loading;
  final bool loadFailed;
  final String query;
  final AssignFilter filter;
  final AssignTarget? selected;
  final bool selectedFromSuggestion;
  final Set<String> expandedTeams;
  final bool submitting;

  /// "استلمها {name} للتو" (§6).
  final String? takenLiveBy;

  /// The owner this sheet last saw — sent so a takeover is detected.
  final AssigneeRef? expectedCurrent;
  final bool offline;

  /// §6 "Conversation resolved while sheet open" → close.
  final bool resolvedWhileOpen;

  /// 422 inline error under that row.
  final String? capacityErrorKey;
  final int? capacityMax;

  /// Agent ids in the §5.6 order computed on open (no jumping later).
  final List<String> agentOrder;

  AssignState copyWith({
    AssigneesPayload? payload,
    bool? loading,
    bool? loadFailed,
    String? query,
    AssignFilter? filter,
    AssignTarget? selected,
    bool clearSelected = false,
    bool? selectedFromSuggestion,
    Set<String>? expandedTeams,
    bool? submitting,
    String? takenLiveBy,
    AssigneeRef? expectedCurrent,
    bool clearExpectedCurrent = false,
    bool? offline,
    bool? resolvedWhileOpen,
    String? capacityErrorKey,
    int? capacityMax,
    bool clearCapacityError = false,
    List<String>? agentOrder,
  }) => AssignState(
    payload: payload ?? this.payload,
    loading: loading ?? this.loading,
    loadFailed: loadFailed ?? this.loadFailed,
    query: query ?? this.query,
    filter: filter ?? this.filter,
    selected: clearSelected ? null : (selected ?? this.selected),
    selectedFromSuggestion: selectedFromSuggestion ?? this.selectedFromSuggestion,
    expandedTeams: expandedTeams ?? this.expandedTeams,
    submitting: submitting ?? this.submitting,
    takenLiveBy: takenLiveBy ?? this.takenLiveBy,
    expectedCurrent: clearExpectedCurrent ? null : (expectedCurrent ?? this.expectedCurrent),
    offline: offline ?? this.offline,
    resolvedWhileOpen: resolvedWhileOpen ?? this.resolvedWhileOpen,
    capacityErrorKey: clearCapacityError ? null : (capacityErrorKey ?? this.capacityErrorKey),
    capacityMax: clearCapacityError ? null : (capacityMax ?? this.capacityMax),
    agentOrder: agentOrder ?? this.agentOrder,
  );
}

/// What the sheet does after a submit.
sealed class AssignSubmitOutcome {
  const AssignSubmitOutcome();
}

class AssignSucceeded extends AssignSubmitOutcome {
  const AssignSucceeded(this.result, this.undo);
  final AssignResult result;
  final Future<void> Function()? undo;
}

/// Close the sheet and show a snackbar (403 / network) — [retry] repeats it.
class AssignFailed extends AssignSubmitOutcome {
  const AssignFailed(this.code, this.retry);
  final String code;
  final Future<AssignSubmitOutcome> Function() retry;
}

/// Stay open (409 banner / 422 inline).
class AssignStayOpen extends AssignSubmitOutcome {
  const AssignStayOpen();
}

final assignControllerProvider = NotifierProvider.autoDispose.family<AssignController, AssignState, AssignArgs>(
  AssignController.new,
);

/// Load, filter, select, submit, undo, bulk (Assign spec §5–§9).
class AssignController extends AutoDisposeFamilyNotifier<AssignState, AssignArgs> {
  AssigneesApi get _api => ref.read(assigneesApiProvider);
  InboxController get _inbox => ref.read(inboxProvider.notifier);
  Timer? _searchDebounce;
  bool _disposed = false;
  bool _ownChange = false;
  final _openedAt = DateTime.now();

  @override
  AssignState build(AssignArgs args) {
    ref.onDispose(() {
      _disposed = true;
      _searchDebounce?.cancel();
    });
    final offline = ref.read(inboxProvider).network == NetworkState.offline;
    ref.listen(inboxProvider.select((s) => s.network), (_, n) {
      final off = n == NetworkState.offline;
      state = state.copyWith(offline: off);
      if (!off && state.loadFailed) load();
    });
    if (!args.bulk) {
      final id = args.conversationIds.first;
      ref.listen(inboxProvider.select((s) => s.conversations.where((c) => c.id == id).firstOrNull), (_, c) {
        _onConversationChanged(c);
      });
    }
    Analytics.log('assign_open', {'source': args.source.analyticsName, 'count': args.conversationIds.length});

    final cached = _api.cached(args.conversationIds);
    scheduleMicrotask(load);
    return cached == null
        ? AssignState(offline: offline)
        : _withPayload(AssignState(offline: offline), cached, initial: true);
  }

  AssignState _withPayload(AssignState s, AssigneesPayload p, {bool initial = false}) {
    // Order fixed on open; later loads only append newcomers (§6 presence).
    final order = initial || s.agentOrder.isEmpty
        ? [for (final a in AssigneeSorter.sort(p.agents)) a.id]
        : [
            ...s.agentOrder,
            for (final a in p.agents)
              if (!s.agentOrder.contains(a.id)) a.id,
          ];
    return s.copyWith(
      payload: p,
      loading: false,
      loadFailed: false,
      agentOrder: order,
      expectedCurrent: initial || s.payload == null ? p.current : s.expectedCurrent,
      clearExpectedCurrent: (initial || s.payload == null) && p.current == null,
    );
  }

  Future<void> load() async {
    try {
      final p = await _api.load(arg.conversationIds);
      if (_disposed) return;
      state = _withPayload(state, p, initial: state.payload == null);
    } on AssignApiException catch (e) {
      if (_disposed) return;
      state = state.copyWith(loading: false, loadFailed: state.payload == null, offline: e.isNetwork ? true : null);
    }
  }

  AssigneeRef? _refOf(Conversation c) => switch (c.ownership) {
    Ownership.ai => const AssigneeRef(AssigneeType.ai, 'ai'),
    Ownership.unassigned => null,
    _ => c.assignee == null ? null : AssigneeRef(AssigneeType.agent, c.assignee!.id),
  };

  /// Live takeover / resolve while open (§6).
  void _onConversationChanged(Conversation? c) {
    if (_disposed || _ownChange || state.submitting) return;
    if (c == null || c.isClosed) {
      state = state.copyWith(resolvedWhileOpen: true);
      return;
    }
    final now = _refOf(c);
    if (now != state.expectedCurrent && state.payload != null) {
      Analytics.log('assign_conflict');
      state = state.copyWith(
        takenLiveBy: c.ownership == Ownership.ai ? 'AI' : (c.assignee?.name ?? ''),
        expectedCurrent: now,
        clearExpectedCurrent: now == null,
      );
      load();
    }
  }

  // ---- Search / filter / select ------------------------------------------------------

  void setQuery(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 120), () {
      if (_disposed) return;
      state = state.copyWith(query: q);
      if (q.trim().isNotEmpty) {
        Analytics.log('assign_search', {
          'query_len': q.trim().length,
          'results': visibleAgents().length + visibleTeams().length,
        });
      }
    });
  }

  void setFilter(AssignFilter f) => state = state.copyWith(filter: f);

  void select(AssignTarget t, {bool fromSuggestion = false}) {
    if (state.submitting) return;
    HapticFeedback.selectionClick();
    final presence = t is AgentTarget ? t.agent.presence.name : null;
    Analytics.log('assign_select', {
      'type': t is AgentTarget && t.isMe ? 'me' : t.type.name,
      'presence': ?presence,
      'was_suggested': fromSuggestion || state.payload?.suggested?.ref == t.ref,
    });
    state = state.copyWith(
      selected: t,
      selectedFromSuggestion: fromSuggestion || state.payload?.suggested?.ref == t.ref,
      clearCapacityError: true,
    );
  }

  void toggleTeam(String teamId) {
    final next = {...state.expandedTeams};
    next.contains(teamId) ? next.remove(teamId) : next.add(teamId);
    state = state.copyWith(expandedTeams: next);
  }

  // ---- Derived lists -----------------------------------------------------------------

  String get _q => ArabicNormalizer.normalize(state.query);

  bool _agentMatches(AgentAssignee a) {
    final q = _q;
    if (q.isEmpty) return true;
    final teams = state.payload?.teams ?? const [];
    return ArabicNormalizer.matches(a.name, q) ||
        ArabicNormalizer.matches(a.email, q) ||
        a.skills.any((s) => ArabicNormalizer.matches(s, q)) ||
        teams.any((t) => a.teamIds.contains(t.id) && ArabicNormalizer.matches(t.name, q));
  }

  bool _sharesTeamWithMe(AgentAssignee a) {
    final mine = state.payload?.me.teamIds ?? const [];
    return a.teamIds.any(mine.contains);
  }

  /// Colleagues in the fixed order, filtered.
  List<AgentAssignee> visibleAgents() {
    final p = state.payload;
    if (p == null) return const [];
    final byId = {for (final a in p.agents) a.id: a};
    return [
      for (final id in state.agentOrder)
        if (byId[id] case final a?)
          if (_agentMatches(a) &&
              (state.filter != AssignFilter.available || a.presence == Presence.online) &&
              (state.filter != AssignFilter.myTeam || _sharesTeamWithMe(a)))
            a,
    ];
  }

  List<TeamAssignee> visibleTeams() {
    final p = state.payload;
    if (p == null || state.filter == AssignFilter.available) return const [];
    final q = _q;
    final mine = p.me.teamIds;
    return [
      for (final t in p.teams)
        if ((q.isEmpty || ArabicNormalizer.matches(t.name, q)) &&
            (state.filter != AssignFilter.myTeam || mine.contains(t.id)))
          t,
    ];
  }

  /// "أنا": bulk always; single only when the conversation isn't mine (§4).
  bool get showMe {
    final p = state.payload;
    if (p == null) return false;
    if (state.filter == AssignFilter.available && p.me.presence != Presence.online) return false;
    if (!ArabicNormalizer.matches(p.me.name, _q) && !ArabicNormalizer.matches('أنا me', _q)) return false;
    return arg.bulk || state.expectedCurrent?.id != p.me.id;
  }

  bool get showAi {
    final p = state.payload;
    if (p == null || !p.ai.enabled || state.filter != AssignFilter.all) return false;
    return ArabicNormalizer.matches('الذكاء الاصطناعي AI', _q);
  }

  bool get showFilters => (state.payload?.agents.length ?? 0) + 1 > 8;

  int get availableCount =>
      (state.payload?.agents.where((a) => a.presence == Presence.online).length ?? 0) +
      (state.payload?.me.presence == Presence.online ? 1 : 0);

  bool isCurrent(AssigneeRef r) => !arg.bulk && state.expectedCurrent == r;

  // ---- Submit ------------------------------------------------------------------------

  static String _noteBucket(int n) => n == 0 ? '0' : (n <= 50 ? '1-50' : (n <= 200 ? '51-200' : '201+'));

  Future<AssignSubmitOutcome> submit(String note) async {
    final t = state.selected;
    if (t == null || state.submitting || state.offline) return const AssignStayOpen();
    return _submit(t, note.trim());
  }

  /// "إلغاء الإسناد (إرجاعها لغير المُسندة)".
  Future<AssignSubmitOutcome> unassign(String note) => _submit(null, note.trim());

  Future<AssignSubmitOutcome> _submit(AssignTarget? t, String note) async {
    state = state.copyWith(submitting: true, clearCapacityError: true);
    final watch = Stopwatch()..start();
    void log(String result) => Analytics.log('assign_submit', {
      'type': t == null ? 'unassign' : (t is AgentTarget && t.isMe ? 'me' : t.type.name),
      'has_note': note.isNotEmpty,
      'note_len_bucket': _noteBucket(note.length),
      'latency_ms': watch.elapsedMilliseconds,
      'result': result,
      'open_to_submit_ms': DateTime.now().difference(_openedAt).inMilliseconds,
    });
    try {
      final out = arg.bulk ? await _bulk(t!, note) : await _single(t, note);
      log(out is AssignSucceeded ? 'ok' : 'stay');
      if (!_disposed) state = state.copyWith(submitting: false);
      return out;
    } on AssignApiException catch (e) {
      log(e.code);
      if (_disposed) return const AssignStayOpen();
      state = state.copyWith(submitting: false);
      switch (e.code) {
        case 'state_changed':
          Analytics.log('assign_conflict');
          final c = _inbox.byId(arg.conversationIds.first);
          if (c == null || c.isClosed) {
            state = state.copyWith(resolvedWhileOpen: true);
          } else {
            final now = _refOf(c);
            state = state.copyWith(
              takenLiveBy: e.currentAssigneeName ?? c.assignee?.name ?? '',
              expectedCurrent: now,
              clearExpectedCurrent: now == null,
            );
            unawaited(load());
          }
          return const AssignStayOpen();
        case 'capacity_reached':
          state = state.copyWith(capacityErrorKey: t?.key, capacityMax: e.max);
          return const AssignStayOpen();
        default:
          return AssignFailed(e.code, () => _retry(t, note));
      }
    }
  }

  /// Snackbar "إعادة المحاولة" after the sheet closed: same request, no UI.
  Future<AssignSubmitOutcome> _retry(AssignTarget? t, String note) async {
    try {
      return arg.bulk ? await _bulk(t!, note) : await _single(t, note);
    } on AssignApiException catch (e) {
      return AssignFailed(e.code, () => _retry(t, note));
    }
  }

  String _key() => 'as-${DateTime.now().microsecondsSinceEpoch}';

  Future<AssignSubmitOutcome> _single(AssignTarget? t, String note) async {
    final id = arg.conversationIds.first;
    final before = _inbox.byId(id);

    // "أنا" on an unassigned conversation = Claim (Claim spec §7.1).
    if (t is AgentTarget && t.isMe && state.expectedCurrent == null) {
      final claim = await ref.read(claimControllerProvider(id).notifier).claim(source: 'assign_sheet');
      if (claim.phase == ClaimPhase.conflict) {
        throw AssignApiException('state_changed', statusCode: 409, currentAssigneeName: claim.claimedBy);
      }
      if (claim.phase != ClaimPhase.success) throw const AssignApiException('network');
      if (note.isNotEmpty) _inbox.addNote(id, note);
      return AssignSucceeded(
        AssignResult(target: t, assigneeName: t.agent.name, succeeded: [id], total: 1, claimed: true),
        null,
      );
    }

    final to = await _api.assign(
      id,
      assigneeType: t?.type,
      assigneeId: t?.id,
      note: note,
      idempotencyKey: _key(),
      expectedCurrent: state.expectedCurrent,
    );
    _apply(id, t, to, note);
    final name = t == null ? '' : (to.name.isNotEmpty ? to.name : t.displayName);
    return AssignSucceeded(
      AssignResult(target: t, assigneeName: name, succeeded: [id], total: 1, unassigned: t == null),
      before == null ? null : () => _undo([before]),
    );
  }

  Future<AssignSubmitOutcome> _bulk(AssignTarget t, String note) async {
    final snapshots = {for (final id in arg.conversationIds) id: ?_inbox.byId(id)};
    final r = await _api.bulk(arg.conversationIds, assigneeType: t.type, assigneeId: t.id, note: note);
    for (final id in r.succeeded) {
      final to =
          r.assignedTo[id] ??
          (t is AgentTarget
              ? AssignedTo(type: AssigneeType.agent, id: t.id, name: t.agent.name, agent: t.agent)
              : AssignedTo(type: t.type, id: t.id, name: t.displayName));
      _apply(id, t, to, note);
    }
    _inbox.clearSelection();
    final name = t is AgentTarget ? t.agent.name : (t is AiTarget ? 'AI' : t.displayName);
    return AssignSucceeded(
      AssignResult(
        target: t,
        assigneeName: name,
        succeeded: r.succeeded,
        total: arg.conversationIds.length,
        failures: r.failed,
      ),
      r.succeeded.isEmpty ? null : () => _undo([for (final id in r.succeeded) ?snapshots[id]]),
    );
  }

  /// Local store update after the server said yes (§7 "200").
  void _apply(String id, AssignTarget? t, AssignedTo to, String note) {
    _ownChange = true;
    try {
      switch (to.type) {
        case AssigneeType.agent:
          final agent =
              to.agent?.toAgent() ??
              (t is AgentTarget ? t.agent.toAgent() : Agent(id: to.id ?? '', name: to.name, email: ''));
          _inbox.assign(id, agent);
        case AssigneeType.ai:
          _inbox.assignToAi(id);
        case AssigneeType.team || null:
          // Unassign, or a team queue (manual routing / nobody available).
          _inbox.unassign(id);
      }
      // Internal amber note attributed to me (§5.9).
      if (note.isNotEmpty) _inbox.addNote(id, note, mentions: [if (to.name.isNotEmpty) to.name.split(' ').first]);
      if (!_disposed) {
        final c = _inbox.byId(id);
        if (c != null && !arg.bulk) {
          final now = _refOf(c);
          state = state.copyWith(expectedCurrent: now, clearExpectedCurrent: now == null);
        }
      }
    } finally {
      _ownChange = false;
    }
  }

  /// Undo restores each previous owner, keeps the note, adds the event.
  Future<void> _undo(List<Conversation> snapshots) async {
    Analytics.log('assign_undo');
    for (final s in snapshots) {
      _ownChange = true;
      _inbox.undoAssign(s);
      _ownChange = false;
      final prev = _refOf(s);
      unawaited(
        _api
            .assign(
              s.id,
              assigneeType: prev?.type,
              assigneeId: prev?.id,
              idempotencyKey: _key(),
              expectedCurrent: _refOf(_inbox.byId(s.id) ?? s),
            )
            .then<void>((_) {}, onError: (_) {}),
      );
    }
  }
}
