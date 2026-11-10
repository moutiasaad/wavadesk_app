import 'package:flutter/foundation.dart';

/// Dashboard spec §2 `?range=`.
enum DashboardRange {
  today('today'),
  yesterday('yesterday'),
  last7('7d'),
  last30('30d');

  const DashboardRange(this.wire);
  final String wire;

  static DashboardRange parse(String? v) => values.firstWhere((r) => r.wire == v, orElse: () => today);
}

/// Dashboard spec §2 `?scope=` (§5 role matrix decides which are offered).
enum DashboardScope {
  me,
  team,
  workspace;

  static DashboardScope parse(String? v) => values.firstWhere((s) => s.name == v, orElse: () => me);
}

/// Alert kinds in priority order (§4.3).
enum DashboardAlertKind {
  whatsappDisconnected('whatsapp_disconnected'),
  slaBreach('sla_breach'),
  unassignedBacklog('unassigned_backlog'),
  kbUnanswered('kb_unanswered'),
  trialEnding('trial_ending');

  const DashboardAlertKind(this.wire);
  final String wire;

  static DashboardAlertKind? parse(String? v) => values.where((k) => k.wire == v).firstOrNull;
}

enum TeamPresence {
  online,
  busy,
  away;

  static TeamPresence parse(String? v) => values.firstWhere((p) => p.name == v, orElse: () => away);
}

int _int(Object? v) => (v as num?)?.toInt() ?? 0;
int? _intOrNull(Object? v) => (v as num?)?.toInt();
double? _doubleOrNull(Object? v) => (v as num?)?.toDouble();
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
List<Map<String, dynamic>> _list(Object? v) => [for (final e in (v as List? ?? const [])) if (e is Map) Map<String, dynamic>.from(e)];
DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();

/// First-response distribution (§4.4.1), shares 0..1.
@immutable
class FrtBuckets {
  const FrtBuckets({required this.lt1m, required this.m1to5, required this.m5to15, required this.gt15m});

  final double lt1m;
  final double m1to5;
  final double m5to15;
  final double gt15m;

  static FrtBuckets? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    return FrtBuckets(
      lt1m: _doubleOrNull(j['lt_1m']) ?? 0,
      m1to5: _doubleOrNull(j['m1_5']) ?? 0,
      m5to15: _doubleOrNull(j['m5_15']) ?? 0,
      gt15m: _doubleOrNull(j['gt_15m']) ?? 0,
    );
  }

  Map<String, Object?> toJson() => {'lt_1m': lt1m, 'm1_5': m1to5, 'm5_15': m5to15, 'gt_15m': gt15m};
}

@immutable
class DashboardMetrics {
  const DashboardMetrics({
    required this.open,
    this.openDelta,
    required this.awaiting,
    this.oldestWaitSeconds,
    this.overSla = 0,
    this.avgFirstResponseSeconds,
    this.firstResponseDeltaSeconds,
    required this.slaSeconds,
    this.frtBuckets,
    this.ai,
    required this.resolved,
  });

  final int open;
  final int? openDelta;
  final int awaiting;
  final int? oldestWaitSeconds;
  final int overSla;
  final int? avgFirstResponseSeconds;
  final int? firstResponseDeltaSeconds;
  final int slaSeconds;
  final FrtBuckets? frtBuckets;

  /// Null when the workspace AI is off (the grid shows "resolved" instead).
  final AiResolution? ai;
  final int resolved;

  DashboardMetrics copyWith({int? open, int? awaiting, int? oldestWaitSeconds}) => DashboardMetrics(
        open: open ?? this.open,
        openDelta: openDelta,
        awaiting: awaiting ?? this.awaiting,
        oldestWaitSeconds: awaiting == 0 ? null : (oldestWaitSeconds ?? this.oldestWaitSeconds),
        overSla: overSla,
        avgFirstResponseSeconds: avgFirstResponseSeconds,
        firstResponseDeltaSeconds: firstResponseDeltaSeconds,
        slaSeconds: slaSeconds,
        frtBuckets: frtBuckets,
        ai: ai,
        resolved: resolved,
      );

  factory DashboardMetrics.fromJson(Map<String, dynamic> j) {
    final open = _map(j['open']);
    final aw = _map(j['awaiting']);
    final frt = _map(j['first_response']);
    return DashboardMetrics(
      open: _int(open['value']),
      openDelta: _intOrNull(open['delta']),
      awaiting: _int(aw['value']),
      oldestWaitSeconds: _intOrNull(aw['oldest_wait_seconds']),
      overSla: _int(aw['over_sla']),
      avgFirstResponseSeconds: _intOrNull(frt['avg_seconds']),
      firstResponseDeltaSeconds: _intOrNull(frt['delta_seconds']),
      slaSeconds: _intOrNull(frt['sla_seconds']) ?? 300,
      frtBuckets: FrtBuckets.fromJson(frt['buckets']),
      ai: j['ai_resolution'] is Map ? AiResolution.fromJson(_map(j['ai_resolution'])) : null,
      resolved: _int(_map(j['resolved'])['value']),
    );
  }

  Map<String, Object?> toJson() => {
        'open': {'value': open, 'delta': openDelta},
        'awaiting': {'value': awaiting, 'oldest_wait_seconds': oldestWaitSeconds, 'over_sla': overSla},
        'first_response': {
          'avg_seconds': avgFirstResponseSeconds,
          'delta_seconds': firstResponseDeltaSeconds,
          'sla_seconds': slaSeconds,
          'buckets': frtBuckets?.toJson(),
        },
        'ai_resolution': ai?.toJson(),
        'resolved': {'value': resolved},
      };
}

@immutable
class AiResolution {
  const AiResolution({required this.rate, required this.answered, required this.handoffs, this.thumbsUpRate, required this.hoursSaved});

  /// 0..1
  final double rate;
  final int answered;
  final int handoffs;
  final double? thumbsUpRate;
  final int hoursSaved;

  factory AiResolution.fromJson(Map<String, dynamic> j) => AiResolution(
        rate: _doubleOrNull(j['rate']) ?? 0,
        answered: _int(j['answered']),
        handoffs: _int(j['handoffs']),
        thumbsUpRate: _doubleOrNull(j['thumbs_up_rate']),
        hoursSaved: _int(j['hours_saved']),
      );

  Map<String, Object?> toJson() =>
      {'rate': rate, 'answered': answered, 'handoffs': handoffs, 'thumbs_up_rate': thumbsUpRate, 'hours_saved': hoursSaved};
}

@immutable
class VolumeBucket {
  const VolumeBucket({required this.start, required this.label, required this.total, required this.ai, this.isCurrent = false, this.isFuture = false});

  final DateTime start;
  final String label;
  final int total;
  final int ai;
  final bool isCurrent;
  final bool isFuture;

  VolumeBucket copyWith({int? total, int? ai}) =>
      VolumeBucket(start: start, label: label, total: total ?? this.total, ai: ai ?? this.ai, isCurrent: isCurrent, isFuture: isFuture);

  factory VolumeBucket.fromJson(Map<String, dynamic> j) => VolumeBucket(
        start: _date(j['start']) ?? DateTime.now(),
        label: '${j['label'] ?? ''}',
        total: _int(j['total']),
        ai: _int(j['ai']),
        isCurrent: j['is_current'] == true,
        isFuture: j['is_future'] == true,
      );

  Map<String, Object?> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'label': label,
        'total': total,
        'ai': ai,
        'is_current': isCurrent,
        'is_future': isFuture,
      };
}

@immutable
class VolumeSeries {
  const VolumeSeries({required this.hourly, required this.total, required this.series});

  /// `bucket == hour` (today / yesterday) vs daily (7d / 30d).
  final bool hourly;
  final int total;
  final List<VolumeBucket> series;

  VolumeBucket? get peak => series.isEmpty ? null : series.reduce((a, b) => b.total > a.total ? b : a);

  factory VolumeSeries.fromJson(Map<String, dynamic> j) => VolumeSeries(
        hourly: j['bucket'] != 'day',
        total: _int(j['total']),
        series: [for (final b in _list(j['series'])) VolumeBucket.fromJson(b)],
      );

  Map<String, Object?> toJson() =>
      {'bucket': hourly ? 'hour' : 'day', 'total': total, 'series': [for (final b in series) b.toJson()]};
}

@immutable
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.firstName,
    this.avatarUrl,
    this.gender,
    required this.presence,
    required this.open,
    this.maxConcurrent,
    this.avgFirstResponseToday,
    this.isMe = false,
  });

  final String id;
  final String name;
  final String firstName;
  final String? avatarUrl;
  final String? gender;
  final TeamPresence presence;
  final int open;
  final int? maxConcurrent;
  final int? avgFirstResponseToday;
  final bool isMe;

  /// 0..1+ of `max_concurrent`, null without a limit.
  double? get load => (maxConcurrent ?? 0) > 0 ? open / maxConcurrent! : null;

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        firstName: '${j['first_name'] ?? j['name'] ?? ''}',
        avatarUrl: j['avatar_url'] as String?,
        gender: j['gender'] as String?,
        presence: TeamPresence.parse(j['presence'] as String?),
        open: _int(j['open']),
        maxConcurrent: _intOrNull(j['max_concurrent']),
        avgFirstResponseToday: _intOrNull(j['avg_first_response_today']),
        isMe: j['is_me'] == true,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'first_name': firstName,
        'avatar_url': avatarUrl,
        'gender': gender,
        'presence': presence.name,
        'open': open,
        'max_concurrent': maxConcurrent,
        'avg_first_response_today': avgFirstResponseToday,
        'is_me': isMe,
      };
}

@immutable
class DashboardAlert {
  const DashboardAlert({required this.kind, required this.count, this.meta = const {}, this.dismissible = false});

  final DashboardAlertKind kind;
  final int count;
  final Map<String, dynamic> meta;
  final bool dismissible;

  int get slaMinutes => _intOrNull(meta['sla_minutes']) ?? 5;
  int get daysLeft => _intOrNull(meta['days_left']) ?? count;

  Map<String, Object?> toJson() => {'kind': kind.wire, 'count': count, 'meta': meta, 'dismissible': dismissible};
}

@immutable
class OnboardingSteps {
  const OnboardingSteps({required this.whatsapp, required this.kb, required this.ai});

  final bool whatsapp;
  final bool kb;
  final bool ai;

  Map<String, Object?> toJson() => {'whatsapp': whatsapp, 'kb': kb, 'ai': ai};
}

@immutable
class DashboardTeamRef {
  const DashboardTeamRef(this.id, this.name);
  final String id;
  final String name;
}

@immutable
class DashboardPermissions {
  const DashboardPermissions({required this.scopes, this.teams = const [], this.canRedistribute = false, this.canViewReports = false});

  final List<DashboardScope> scopes;
  final List<DashboardTeamRef> teams;
  final bool canRedistribute;
  final bool canViewReports;

  /// Owner / admin / lead see the scope bar (§4.2); agents only the range.
  bool get showScopes => scopes.length > 1;
  bool get isAdmin => scopes.contains(DashboardScope.workspace);

  factory DashboardPermissions.fromJson(Map<String, dynamic> j) => DashboardPermissions(
        scopes: [for (final s in (j['scopes'] as List? ?? const ['me'])) DashboardScope.parse('$s')],
        teams: [for (final t in _list(j['teams'])) DashboardTeamRef('${t['id']}', '${t['name'] ?? ''}')],
        canRedistribute: j['can_redistribute'] == true,
        canViewReports: j['can_view_reports'] == true,
      );

  Map<String, Object?> toJson() => {
        'scopes': [for (final s in scopes) s.name],
        'teams': [for (final t in teams) {'id': t.id, 'name': t.name}],
        'can_redistribute': canRedistribute,
        'can_view_reports': canViewReports,
      };
}

/// `GET /mobile/v1/dashboard` (spec §9).
@immutable
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.generatedAt,
    required this.timezone,
    required this.scope,
    required this.range,
    required this.metrics,
    required this.volume,
    this.teamNow = const [],
    this.aiHandling,
    this.channels = const {},
    this.alerts = const [],
    this.onboarding,
    required this.permissions,
    this.businessHoursStart = 9,
    this.businessHoursEnd = 21,
    this.is24h = false,
    this.myPresence,
  });

  final DateTime generatedAt;
  final String timezone;
  final DashboardScope scope;
  final DashboardRange range;
  final DashboardMetrics metrics;
  final VolumeSeries volume;
  final List<TeamMember> teamNow;

  /// `ai_now.handling`; null when the AI is off.
  final int? aiHandling;

  /// channel key → conversations in range, biggest first.
  final Map<String, int> channels;
  final List<DashboardAlert> alerts;

  /// Non-null = new workspace: show the setup card instead of grid + chart.
  final OnboardingSteps? onboarding;
  final DashboardPermissions permissions;
  final int businessHoursStart;
  final int businessHoursEnd;
  final bool is24h;

  /// `me.presence` as the server has it (online | busy | away).
  final String? myPresence;

  bool get aiEnabled => metrics.ai != null;

  /// Highest-priority alert (§4.3 shows at most one).
  DashboardAlert? get topAlert {
    if (alerts.isEmpty) return null;
    final sorted = [...alerts]..sort((a, b) => a.kind.index.compareTo(b.kind.index));
    return sorted.first;
  }

  DashboardSnapshot copyWith({
    DashboardMetrics? metrics,
    VolumeSeries? volume,
    List<DashboardAlert>? alerts,
    DateTime? generatedAt,
  }) =>
      DashboardSnapshot(
        generatedAt: generatedAt ?? this.generatedAt,
        timezone: timezone,
        scope: scope,
        range: range,
        metrics: metrics ?? this.metrics,
        volume: volume ?? this.volume,
        teamNow: teamNow,
        aiHandling: aiHandling,
        channels: channels,
        alerts: alerts ?? this.alerts,
        onboarding: onboarding,
        permissions: permissions,
        businessHoursStart: businessHoursStart,
        businessHoursEnd: businessHoursEnd,
        is24h: is24h,
        myPresence: myPresence,
      );

  factory DashboardSnapshot.fromJson(Map<String, dynamic> j) {
    final bh = _map(j['business_hours']);
    int hour(Object? v, int fallback) => int.tryParse('$v'.split(':').first) ?? fallback;
    final onb = j['onboarding'];
    return DashboardSnapshot(
      generatedAt: _date(j['generated_at']) ?? DateTime.now(),
      timezone: '${j['timezone'] ?? 'UTC'}',
      scope: DashboardScope.parse(j['scope'] as String?),
      range: DashboardRange.parse(j['range'] as String?),
      metrics: DashboardMetrics.fromJson(_map(j['metrics'])),
      volume: VolumeSeries.fromJson(_map(j['volume'])),
      teamNow: [for (final m in _list(j['team_now'])) TeamMember.fromJson(m)],
      aiHandling: _intOrNull(_map(j['ai_now'])['handling']),
      channels: {for (final c in _list(j['channels'])) '${c['channel']}': _int(c['count'])},
      alerts: [
        for (final a in _list(j['alerts']))
          if (DashboardAlertKind.parse(a['kind'] as String?) case final kind?)
            DashboardAlert(kind: kind, count: _int(a['count']), meta: _map(a['meta']), dismissible: a['dismissible'] == true),
      ],
      onboarding: onb is Map
          ? OnboardingSteps(whatsapp: onb['whatsapp'] == true, kb: onb['kb'] == true, ai: onb['ai'] == true)
          : null,
      permissions: DashboardPermissions.fromJson(_map(j['permissions'])),
      businessHoursStart: hour(bh['start'], 9),
      businessHoursEnd: hour(bh['end'], 21),
      is24h: bh['is_24h'] == true,
      myPresence: _map(j['me'])['presence'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'timezone': timezone,
        'scope': scope.name,
        'range': range.wire,
        'business_hours': {
          'start': '${businessHoursStart.toString().padLeft(2, '0')}:00',
          'end': '${businessHoursEnd.toString().padLeft(2, '0')}:00',
          'is_24h': is24h,
        },
        'metrics': metrics.toJson(),
        'volume': volume.toJson(),
        'team_now': [for (final m in teamNow) m.toJson()],
        'ai_now': aiHandling == null ? null : {'handling': aiHandling},
        'channels': [for (final e in channels.entries) {'channel': e.key, 'count': e.value}],
        'alerts': [for (final a in alerts) a.toJson()],
        'onboarding': onboarding?.toJson(),
        'permissions': permissions.toJson(),
        'me': {'presence': myPresence},
      };
}

/// `GET /mobile/v1/dashboard/live` (§8).
@immutable
class DashboardLive {
  const DashboardLive({required this.open, required this.awaiting, this.oldestWaitSeconds, required this.currentTotal, required this.currentAi});

  final int open;
  final int awaiting;
  final int? oldestWaitSeconds;
  final int currentTotal;
  final int currentAi;

  factory DashboardLive.fromJson(Map<String, dynamic> j) {
    final b = _map(j['current_bucket']);
    return DashboardLive(
      open: _int(j['open']),
      awaiting: _int(j['awaiting']),
      oldestWaitSeconds: _intOrNull(j['oldest_wait_seconds']),
      currentTotal: _int(b['total']),
      currentAi: _int(b['ai']),
    );
  }
}
