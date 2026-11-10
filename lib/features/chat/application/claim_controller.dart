import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/analytics.dart';
import '../../../core/api/wd_api.dart';
import '../data/chat_api.dart';
import 'local_chat_events.dart';

/// Outcome of a claim attempt (Claim spec §6, §11).
enum ClaimPhase { idle, claiming, success, conflict, forbidden, network, locked }

@immutable
class ClaimState {
  const ClaimState({this.phase = ClaimPhase.idle, this.claimedBy, this.team, this.max});

  final ClaimPhase phase;

  /// 409: who holds it.
  final String? claimedBy;

  /// 403 not_in_team: owning team.
  final String? team;

  /// 403 capacity_reached: limit.
  final int? max;

  bool get claiming => phase == ClaimPhase.claiming;
}

final claimControllerProvider = NotifierProvider.autoDispose.family<ClaimController, ClaimState, String>(
  ClaimController.new,
);

/// Explicit claim (Claim spec §7.1). Never optimistic: the composer only
/// appears after the server confirms ownership. Each tap carries an
/// `Idempotency-Key`, taps within 600ms are ignored, and a tap while a
/// claim is in flight does nothing.
class ClaimController extends AutoDisposeFamilyNotifier<ClaimState, String> {
  DateTime? _lastTap;

  @override
  ClaimState build(String id) => const ClaimState();

  int _waitSeconds(Conversation? c) {
    if (c == null) return 0;
    DateTime? since = c.waitingSince;
    if (since == null) {
      for (var i = c.messages.length - 1; i >= 0; i--) {
        final m = c.messages[i];
        if (m.type == MessageBubbleType.incoming) {
          since = m.sentAt;
        } else if (m.type != MessageBubbleType.system && m.type != MessageBubbleType.internalNote) {
          break;
        }
      }
    }
    return since == null ? 0 : DateTime.now().difference(since).inSeconds;
  }

  /// [source]: chat | swipe | push | auto. [setAvailable] flips presence to
  /// "متاح" (away confirm sheet).
  Future<ClaimState> claim({String source = 'chat', bool setAvailable = false}) async {
    final now = DateTime.now();
    if (state.claiming) return state;
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 600)) return state;
    _lastTap = now;

    final inbox = ref.read(inboxProvider.notifier);
    final c = inbox.byId(arg);
    Analytics.log('claim_tap', {'wait_seconds': _waitSeconds(c), 'viewers_count': c?.viewers.length ?? 0});
    state = const ClaimState(phase: ClaimPhase.claiming);
    final started = DateTime.now();
    // One key per tap: reused by the client on its own automatic retry.
    final requestId = WdApi.newIdempotencyKey();

    ClaimState result;
    try {
      final api = ref.read(chatApiProvider);
      result = api == null ? await _sampleClaim() : await _apiClaim(api, requestId, setAvailable);
    } catch (_) {
      result = const ClaimState(phase: ClaimPhase.network);
    }
    if (result.phase == ClaimPhase.success && setAvailable) {
      ref.read(settingsProvider.notifier).setPresence(Presence.online);
    }
    Analytics.log('claim_result', {
      'result': switch (result.phase) {
        ClaimPhase.success => 'ok',
        ClaimPhase.conflict => 'conflict',
        ClaimPhase.forbidden => result.max != null ? 'capacity' : 'forbidden',
        ClaimPhase.network => 'network',
        _ => result.phase.name,
      },
      'latency_ms': DateTime.now().difference(started).inMilliseconds,
      'source': source,
    });
    // Back to idle so the bar can retry; the phase is reported to the caller.
    state = result.phase == ClaimPhase.success
        ? result
        : ClaimState(phase: ClaimPhase.idle, claimedBy: result.claimedBy);
    return result;
  }

  /// Sample mode: same rules the server enforces (compare-and-set on
  /// `assignee IS NULL`).
  Future<ClaimState> _sampleClaim() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (ref.read(inboxProvider).network != NetworkState.online) return const ClaimState(phase: ClaimPhase.network);
    final inbox = ref.read(inboxProvider.notifier);
    final c = inbox.byId(arg);
    if (c == null) return const ClaimState(phase: ClaimPhase.network);
    if (c.customer.blocked || c.isClosed) return const ClaimState(phase: ClaimPhase.locked);
    if (MockData.hardCapacityLimit) {
      final open = ref
          .read(inboxProvider)
          .conversations
          .where((x) => x.ownership == Ownership.mine && !x.isClosed)
          .length;
      if (open >= MockData.maxConcurrent) {
        return ClaimState(phase: ClaimPhase.forbidden, max: MockData.maxConcurrent);
      }
    }
    final by = inbox.claimChecked(arg);
    return by == null
        ? const ClaimState(phase: ClaimPhase.success)
        : ClaimState(phase: ClaimPhase.conflict, claimedBy: by);
  }

  /// `POST conversations/{id}/claim` → the new detail (mirrored into the
  /// inbox so it moves Unassigned → Mine at once). Errors (README §8):
  /// 409 already_assigned (details.assignee.name), 403 not_in_team /
  /// role_forbidden, 423 conversation_resolved / contact_blocked.
  Future<ClaimState> _apiClaim(ChatApi api, String requestId, bool setAvailable) async {
    try {
      final r = await api.action(arg, 'claim', {if (setAvailable) 'set_available': true}, requestId);
      syncRemoteConversation(ref, r);
      // The thread API has no ownership events: add "استلمت المحادثة" here.
      ref.read(localChatEventsProvider.notifier).add(
        arg,
        SystemEvent(kind: SystemEventKind.claimed, actorId: ref.read(currentAgentProvider).id),
      );
      return const ClaimState(phase: ClaimPhase.success);
    } on ChatApiException catch (e) {
      if (e.statusCode == 409 && e.code == 'already_assigned') {
        final a = e.body['assignee'];
        ref.read(localChatEventsProvider.notifier).add(
          arg,
          SystemEvent(
            kind: SystemEventKind.claimed,
            actorId: a is Map ? '${a['id']}' : null,
            actorName: e.claimedBy,
          ),
        );
      }
      // 409 / 403 / 423: the server state differs from ours → refetch now so
      // the bar becomes ReadOnlyBar(colleague / team / resolved) at once.
      if (e.statusCode == 409 || e.statusCode == 403 || e.statusCode == 423) {
        unawaited(api.detail(arg).then((r) => syncRemoteConversation(ref, r)).catchError((Object _) {}));
      }
      final t = e.body['team'];
      final team = (t is Map ? t['name'] as String? : null) ?? ref.read(remoteChatPermissionsProvider)[arg]?.teamName;
      return switch (e.statusCode) {
        0 => const ClaimState(phase: ClaimPhase.network),
        409 when e.code == 'already_assigned' => ClaimState(phase: ClaimPhase.conflict, claimedBy: e.claimedBy ?? ''),
        409 => const ClaimState(phase: ClaimPhase.network),
        403 => ClaimState(
          phase: ClaimPhase.forbidden,
          team: e.code == 'not_in_team' ? team : null,
          max: e.code == 'capacity_reached' ? ((e.body['max'] as num?)?.toInt() ?? 0) : null,
        ),
        423 => const ClaimState(phase: ClaimPhase.locked),
        _ => const ClaimState(phase: ClaimPhase.network),
      };
    }
  }
}

/// SLA + capacity used by the claim bar (Claim spec §4.2.2, §6, §8).
@immutable
class ClaimLimits {
  const ClaimLimits({required this.slaSeconds, required this.open, this.max, this.hardLimit = false});

  final int slaSeconds;

  /// My open conversations.
  final int open;

  /// Workspace `max_concurrent`; null = no limit.
  final int? max;

  /// The workspace enforces [max] (claim disabled when reached).
  final bool hardLimit;

  bool get atCapacity => max != null && open >= max!;
  bool get hardBlocked => atCapacity && hardLimit;
}

/// Real API: `sla_seconds` + `capacity` of the conversation detail.
/// Sample mode: `assets/fake` workspace settings + the in-memory inbox.
final claimLimitsProvider = Provider.autoDispose.family<ClaimLimits, String>((ref, id) {
  final localOpen = ref.watch(
    inboxProvider.select(
      (s) => s.conversations
          .where((c) => c.ownership == Ownership.mine && !c.isClosed && c.status != ConversationStatus.snoozed)
          .length,
    ),
  );
  if (!useRealApi) {
    return ClaimLimits(
      slaSeconds: MockData.slaSeconds,
      open: localOpen,
      max: MockData.maxConcurrent,
      hardLimit: MockData.hardCapacityLimit,
    );
  }
  final r = ref.watch(remoteChatPermissionsProvider.select((m) => m[id]));
  final cap = r?.capacity;
  return ClaimLimits(
    slaSeconds: r?.slaSeconds ?? 300,
    open: cap?.open ?? localOpen,
    max: cap?.max,
    hardLimit: cap?.hardLimit ?? false,
  );
});
