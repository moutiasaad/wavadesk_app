import 'dart:async';
import 'dart:math';

import '../../../core/api/wd_api.dart';
import '../../../core/models/models.dart';
import '../../conversations/domain/conversation_summary.dart';
import '../domain/dashboard_snapshot.dart';
import '../domain/greeting.dart';

/// Result of a conditional `GET dashboard`.
class DashboardFetch {
  const DashboardFetch({this.snapshot, this.etag, this.notModified = false});

  final DashboardSnapshot? snapshot;
  final String? etag;

  /// 304: the cached snapshot is still current.
  final bool notModified;
}

class DashboardApiException implements Exception {
  const DashboardApiException(this.status, {this.code, this.message});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;

  bool get isNetwork => status == 0;

  @override
  String toString() => 'DashboardApiException($status $code)';
}

/// Dashboard spec §9.
abstract interface class DashboardApi {
  Future<DashboardFetch> fetch({required DashboardRange range, required DashboardScope scope, String? teamId, String? etag});
  Future<DashboardLive> live({required DashboardScope scope, String? teamId});
  Future<void> setPresence(String status, {DateTime? until});
  Future<void> dismissAlert(DashboardAlertKind kind, {required DashboardScope scope});
}

class HttpDashboardApi implements DashboardApi {
  HttpDashboardApi(this._api);

  final WdApi _api;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw DashboardApiException(e.status, code: e.code, message: e.message);
    }
  }

  @override
  Future<DashboardFetch> fetch({required DashboardRange range, required DashboardScope scope, String? teamId, String? etag}) =>
      _guard(() async {
        final r = await _api.get(
          'dashboard',
          query: {'range': range.wire, 'scope': scope.name, 'team_id': teamId},
          ifNoneMatch: etag,
        );
        if (r.notModified) return DashboardFetch(etag: r.etag ?? etag, notModified: true);
        return DashboardFetch(snapshot: DashboardSnapshot.fromJson(r.map), etag: r.etag);
      });

  @override
  Future<DashboardLive> live({required DashboardScope scope, String? teamId}) => _guard(() async {
        final r = await _api.get('dashboard/live', query: {'scope': scope.name, 'team_id': teamId});
        return DashboardLive.fromJson(r.map);
      });

  @override
  Future<void> setPresence(String status, {DateTime? until}) =>
      _guard(() => _api.put('me/presence', body: {'status': status, if (until != null) 'until': until.toUtc().toIso8601String()}));

  @override
  Future<void> dismissAlert(DashboardAlertKind kind, {required DashboardScope scope}) =>
      _guard(() => _api.post('dashboard/alerts/${kind.wire}/dismiss?scope=${scope.name}', body: const <String, Object?>{}));
}

/// Sample mode: a snapshot computed from the local inbox so the numbers
/// match the lists a tap opens. Volume history is synthetic (seeded per day).
///
/// Demo triggers: none — but `#dash_error` as the first agent's name… no.
/// Use the debug flag [failNext] to see the full-error state.
class SampleDashboardApi implements DashboardApi {
  SampleDashboardApi({
    required this.conversations,
    required this.me,
    required this.colleagues,
    required this.maxConcurrent,
    required this.slaSeconds,
    required this.whatsappConnected,
  });

  /// Current inbox rows (read on every fetch).
  final List<ConversationSummary> Function() conversations;
  final Agent Function() me;
  final List<Agent> Function() colleagues;
  final int maxConcurrent;
  final int slaSeconds;
  final bool Function() whatsappConnected;

  static bool failNext = false;
  final Set<DashboardAlertKind> _dismissed = {};

  @override
  Future<DashboardFetch> fetch({required DashboardRange range, required DashboardScope scope, String? teamId, String? etag}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (failNext) {
      failNext = false;
      throw const DashboardApiException(0, code: 'network');
    }
    return DashboardFetch(snapshot: _build(range, scope));
  }

  @override
  Future<DashboardLive> live({required DashboardScope scope, String? teamId}) async {
    final s = _build(DashboardRange.today, scope);
    final cur = s.volume.series.where((b) => b.isCurrent).firstOrNull;
    return DashboardLive(
      open: s.metrics.open,
      awaiting: s.metrics.awaiting,
      oldestWaitSeconds: s.metrics.oldestWaitSeconds,
      currentTotal: cur?.total ?? 0,
      currentAi: cur?.ai ?? 0,
    );
  }

  @override
  Future<void> setPresence(String status, {DateTime? until}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<void> dismissAlert(DashboardAlertKind kind, {required DashboardScope scope}) async {
    _dismissed.add(kind);
  }

  DashboardSnapshot _build(DashboardRange range, DashboardScope scope) {
    final now = DateTime.now();
    final me = this.me();
    final all = conversations();
    final inScope = scope == DashboardScope.me ? all.where((c) => c.isMine(me.id)).toList() : all;
    final open = inScope.where((c) => c.isActive).toList();
    final waiting = open.where((c) => c.waitingSince != null || c.lastMessage?.senderType == SenderType.contact).toList();
    DateTime? oldest;
    for (final c in waiting) {
      final w = c.waitingSince ?? c.lastActivityAt;
      if (oldest == null || w.isBefore(oldest)) oldest = w;
    }
    final overSla = waiting.where((c) => now.difference(c.waitingSince ?? c.lastActivityAt).inSeconds > slaSeconds).length;
    final resolved = inScope.where((c) => c.isClosed).length;
    final unassigned = all.where((c) => c.isActive && c.assignee == null).length;
    final aiHandling = all.where((c) => c.isActive && c.lastMessage?.senderType == SenderType.ai).length;

    final rnd = Random(now.year * 1000 + now.month * 50 + now.day + range.index * 7 + scope.index);
    final volume = _volume(range, now, rnd, scale: scope == DashboardScope.me ? 0.35 : 1);
    final channels = <String, int>{};
    for (final c in inScope) {
      final key = c.channel == Channel.web ? 'webchat' : c.channel.name;
      channels[key] = (channels[key] ?? 0) + 1;
    }

    final lead = me.canManage;
    final team = <TeamMember>[
      _member(me, isMe: true),
      for (final a in colleagues()) _member(a),
    ];
    final rank = {TeamPresence.online: 0, TeamPresence.busy: 1, TeamPresence.away: 2};
    team.sort((a, b) {
      if (a.isMe != b.isMe) return a.isMe ? -1 : 1;
      final p = rank[a.presence]!.compareTo(rank[b.presence]!);
      return p != 0 ? p : b.open.compareTo(a.open);
    });

    final alerts = <DashboardAlert>[
      if (!whatsappConnected()) const DashboardAlert(kind: DashboardAlertKind.whatsappDisconnected, count: 1),
      if (overSla > 0)
        DashboardAlert(kind: DashboardAlertKind.slaBreach, count: overSla, meta: {'sla_minutes': slaSeconds ~/ 60}),
      if (lead && unassigned >= 5)
        DashboardAlert(kind: DashboardAlertKind.unassignedBacklog, count: unassigned, dismissible: true),
      const DashboardAlert(kind: DashboardAlertKind.kbUnanswered, count: 4, dismissible: true),
    ].where((a) => !_dismissed.contains(a.kind)).toList();

    final total = volume.fold<int>(0, (s, b) => s + b.total);
    return DashboardSnapshot(
      generatedAt: now,
      timezone: now.timeZoneName,
      scope: scope,
      range: range,
      metrics: DashboardMetrics(
        open: open.length,
        openDelta: rnd.nextInt(7) - 2,
        awaiting: waiting.length,
        oldestWaitSeconds: oldest == null ? null : now.difference(oldest).inSeconds,
        overSla: overSla,
        avgFirstResponseSeconds: 60 + rnd.nextInt(60),
        firstResponseDeltaSeconds: rnd.nextInt(30) - 20,
        slaSeconds: slaSeconds,
        frtBuckets: const FrtBuckets(lt1m: 0.52, m1to5: 0.31, m5to15: 0.12, gt15m: 0.05),
        ai: AiResolution(rate: 0.64, answered: (total * 0.6).round(), handoffs: (total * 0.12).round(), thumbsUpRate: 0.91, hoursSaved: (total * 0.6 * 4 / 60).round()),
        resolved: resolved + rnd.nextInt(20),
      ),
      volume: VolumeSeries(hourly: range == DashboardRange.today || range == DashboardRange.yesterday, total: total, series: volume),
      teamNow: team,
      aiHandling: aiHandling,
      channels: Map.fromEntries(channels.entries.toList()..sort((a, b) => b.value.compareTo(a.value))),
      alerts: alerts,
      permissions: DashboardPermissions(
        scopes: switch (me.role) {
          AgentRole.admin => const [DashboardScope.me, DashboardScope.team, DashboardScope.workspace],
          AgentRole.supervisor => const [DashboardScope.me, DashboardScope.team],
          AgentRole.agent => const [DashboardScope.me],
        },
        canRedistribute: lead,
        canViewReports: me.isAdmin,
      ),
    );
  }

  TeamMember _member(Agent a, {bool isMe = false}) => TeamMember(
        id: a.id,
        name: a.name,
        firstName: Greeting.firstName(a.name),
        avatarUrl: a.avatarUrl,
        gender: a.gender,
        presence: switch (a.presence) {
          Presence.online => TeamPresence.online,
          Presence.busy => TeamPresence.busy,
          Presence.away => TeamPresence.away,
        },
        open: isMe ? conversations().where((c) => c.isActive && c.isMine(a.id)).length : a.openConversations,
        maxConcurrent: maxConcurrent,
        avgFirstResponseToday: 50 + a.name.length * 4,
        isMe: isMe,
      );

  static List<VolumeBucket> _volume(DashboardRange range, DateTime now, Random rnd, {double scale = 1}) {
    int n(double base) => (base * scale * (0.6 + rnd.nextDouble() * 0.8)).round();
    switch (range) {
      case DashboardRange.today:
      case DashboardRange.yesterday:
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: range == DashboardRange.today ? 0 : 1));
        return [
          for (var h = 9; h <= 20; h++)
            () {
              final start = day.add(Duration(hours: h));
              final future = start.isAfter(now);
              final total = future ? 0 : n(4 + 6 * sin((h - 9) / 11 * pi));
              return VolumeBucket(
                start: start,
                label: _hourLabel(h),
                total: total,
                ai: (total * 0.55).round(),
                isCurrent: !future && now.isBefore(start.add(const Duration(hours: 1))),
                isFuture: future,
              );
            }(),
        ];
      case DashboardRange.last7:
      case DashboardRange.last30:
        final days = range == DashboardRange.last7 ? 7 : 30;
        final today = DateTime(now.year, now.month, now.day);
        return [
          for (var i = days - 1; i >= 0; i--)
            () {
              final start = today.subtract(Duration(days: i));
              final total = n(60);
              return VolumeBucket(
                start: start,
                label: days == 7 ? _weekday(start.weekday) : '${start.day}/${start.month}',
                total: total,
                ai: (total * 0.55).round(),
                isCurrent: i == 0,
              );
            }(),
        ];
    }
  }

  static String _hourLabel(int h) => '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'ص' : 'م'}';

  static String _weekday(int w) => const ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'][w - 1];
}
