import 'package:flutter/foundation.dart';

/// AI Agent spec §8 (`GET /mobile/v1/ai-agent`).
enum AiMode {
  suggest,

  /// Web "Hybrid": sends answers already approved, drafts the rest.
  hybrid,
  auto,

  /// Older app setting; no longer offered (not on the web panel).
  afterHours('after_hours');

  const AiMode([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;

  static AiMode parse(Object? v) => values.firstWhere((m) => m.wire == v, orElse: () => suggest);
}

enum AiTone {
  friendly,
  formal,
  concise;

  static AiTone parse(Object? v) => values.firstWhere((t) => t.name == v, orElse: () => friendly);
}

/// The web panel's reply languages; [customer] is its "Auto".
enum LanguagePolicy {
  customer,
  ar,
  en,
  fr,
  es,
  pt,
  de,
  it;

  static LanguagePolicy parse(Object? v) => values.firstWhere((p) => p.name == v, orElse: () => customer);
}

enum ArabicStyle {
  msa,
  saudi;

  static ArabicStyle parse(Object? v) => values.firstWhere((s) => s.name == v, orElse: () => msa);
}

enum ConfidenceLevel {
  low,
  medium,
  high;

  static ConfidenceLevel parse(Object? v) => values.firstWhere((c) => c.name == v, orElse: () => medium);
}

enum HandoffTargetType {
  unassigned,
  team,
  lastAgent('last_agent');

  const HandoffTargetType([this._wire]);
  final String? _wire;
  String get wire => _wire ?? name;

  static HandoffTargetType parse(Object? v) => values.firstWhere((t) => t.wire == v, orElse: () => unassigned);
}

enum AfterHoursBehavior {
  tellReturnTime('tell_return_time'),
  handoffAndNotify('handoff_and_notify');

  const AfterHoursBehavior(this.wire);
  final String wire;

  static AfterHoursBehavior parse(Object? v) => values.firstWhere((b) => b.wire == v, orElse: () => tellReturnTime);
}

/// Week days in display order (week starts Saturday, SA locale).
const weekDays = ['sat', 'sun', 'mon', 'tue', 'wed', 'thu', 'fri'];

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
List<Map<String, dynamic>> _list(Object? v) => [for (final e in (v as List? ?? const [])) if (e is Map) Map<String, dynamic>.from(e)];
int _int(Object? v, [int d = 0]) => (v as num?)?.toInt() ?? d;
double? _double(Object? v) => (v as num?)?.toDouble();

/// "HH:mm" minutes since midnight.
@immutable
class TimeRange {
  const TimeRange(this.start, this.end);

  final int start;
  final int end;

  static int parseTime(Object? v) {
    final p = '$v'.split(':');
    return (int.tryParse(p.first) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  static String formatTime(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  factory TimeRange.fromJson(Map<String, dynamic> j) => TimeRange(parseTime(j['start']), parseTime(j['end']));
  Map<String, Object?> toJson() => {'start': formatTime(start), 'end': formatTime(end)};

  @override
  bool operator ==(Object other) => other is TimeRange && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class DayHours {
  const DayHours({required this.day, required this.open, this.ranges = const []});

  final String day;
  final bool open;
  final List<TimeRange> ranges;

  DayHours copyWith({bool? open, List<TimeRange>? ranges}) => DayHours(day: day, open: open ?? this.open, ranges: ranges ?? this.ranges);

  factory DayHours.fromJson(Map<String, dynamic> j) => DayHours(
        day: '${j['day']}',
        open: j['open'] == true,
        ranges: [for (final r in _list(j['ranges'])) TimeRange.fromJson(r)],
      );
  Map<String, Object?> toJson() => {'day': day, 'open': open, 'ranges': [for (final r in ranges) r.toJson()]};
}

@immutable
class Holiday {
  const Holiday({required this.id, required this.name, required this.date, required this.enabled});

  final String id;
  final String name;
  final String date;
  final bool enabled;

  Holiday copyWith({bool? enabled}) => Holiday(id: id, name: name, date: date, enabled: enabled ?? this.enabled);

  factory Holiday.fromJson(Map<String, dynamic> j) =>
      Holiday(id: '${j['id']}', name: '${j['name'] ?? ''}', date: '${j['date'] ?? ''}', enabled: j['enabled'] == true);
  Map<String, Object?> toJson() => {'id': id, 'name': name, 'date': date, 'enabled': enabled};
}

@immutable
class WorkingHours {
  const WorkingHours({this.is24h = false, this.timezone = 'Asia/Riyadh', this.week = const [], this.holidays = const []});

  final bool is24h;
  final String timezone;
  final List<DayHours> week;
  final List<Holiday> holidays;

  /// Set = 24h, or at least one open day with a range.
  bool get isSet => is24h || week.any((d) => d.open && d.ranges.isNotEmpty);

  DayHours day(String key) => week.firstWhere((d) => d.day == key, orElse: () => DayHours(day: key, open: false));

  WorkingHours copyWith({bool? is24h, String? timezone, List<DayHours>? week, List<Holiday>? holidays}) => WorkingHours(
        is24h: is24h ?? this.is24h,
        timezone: timezone ?? this.timezone,
        week: week ?? this.week,
        holidays: holidays ?? this.holidays,
      );

  factory WorkingHours.fromJson(Map<String, dynamic> j) => WorkingHours(
        is24h: j['is_24h'] == true,
        timezone: '${j['timezone'] ?? 'Asia/Riyadh'}',
        week: [for (final d in _list(j['week'])) DayHours.fromJson(d)],
        holidays: [for (final h in _list(j['holidays'])) Holiday.fromJson(h)],
      );
  Map<String, Object?> toJson() => {
        'is_24h': is24h,
        'timezone': timezone,
        'week': [for (final d in week) d.toJson()],
        'holidays': [for (final h in holidays) h.toJson()],
      };
}

@immutable
class HandoffRules {
  const HandoffRules({
    this.onHumanRequest = true,
    this.onComplaint = true,
    this.onPayment = true,
    this.onNoAnswer = true,
    this.onLowConfidence = true,
    this.afterReplies,
    this.keywords = const [],
    this.target = HandoffTargetType.unassigned,
    this.teamId,
    this.afterHours = AfterHoursBehavior.tellReturnTime,
    this.message = '',
  });

  final bool onHumanRequest;
  final bool onComplaint;
  final bool onPayment;
  final bool onNoAnswer;
  final bool onLowConfidence;

  /// null = rule off; 2–10.
  final int? afterReplies;
  final List<String> keywords;
  final HandoffTargetType target;
  final String? teamId;
  final AfterHoursBehavior afterHours;
  final String message;

  /// Any rule besides the always-on human request (readiness §4.3).
  bool get anyRule => onComplaint || onPayment || onNoAnswer || onLowConfidence || afterReplies != null || keywords.isNotEmpty;

  HandoffRules copyWith({
    bool? onComplaint,
    bool? onPayment,
    bool? onNoAnswer,
    bool? onLowConfidence,
    int? afterReplies,
    bool clearAfterReplies = false,
    List<String>? keywords,
    HandoffTargetType? target,
    String? teamId,
    AfterHoursBehavior? afterHours,
    String? message,
  }) =>
      HandoffRules(
        onHumanRequest: true,
        onComplaint: onComplaint ?? this.onComplaint,
        onPayment: onPayment ?? this.onPayment,
        onNoAnswer: onNoAnswer ?? this.onNoAnswer,
        onLowConfidence: onLowConfidence ?? this.onLowConfidence,
        afterReplies: clearAfterReplies ? null : (afterReplies ?? this.afterReplies),
        keywords: keywords ?? this.keywords,
        target: target ?? this.target,
        teamId: target != null && target != HandoffTargetType.team ? null : (teamId ?? this.teamId),
        afterHours: afterHours ?? this.afterHours,
        message: message ?? this.message,
      );

  factory HandoffRules.fromJson(Map<String, dynamic> j) {
    final t = _map(j['target']);
    return HandoffRules(
      onHumanRequest: true,
      onComplaint: j['on_complaint'] != false,
      onPayment: j['on_payment'] != false,
      onNoAnswer: j['on_no_answer'] != false,
      onLowConfidence: j['on_low_confidence'] != false,
      afterReplies: (j['after_replies'] as num?)?.toInt(),
      keywords: [for (final k in (j['keywords'] as List? ?? const [])) '$k'],
      target: HandoffTargetType.parse(t['type']),
      teamId: t['team_id'] as String?,
      afterHours: AfterHoursBehavior.parse(j['after_hours']),
      message: '${j['message'] ?? ''}',
    );
  }

  Map<String, Object?> toJson() => {
        'on_human_request': true,
        'on_complaint': onComplaint,
        'on_payment': onPayment,
        'on_no_answer': onNoAnswer,
        'on_low_confidence': onLowConfidence,
        'after_replies': afterReplies,
        'keywords': keywords,
        'target': {'type': target.wire, 'team_id': teamId},
        'after_hours': afterHours.wire,
        'message': message,
      };
}

@immutable
class RewriteStyle {
  const RewriteStyle({required this.id, required this.name, required this.instruction});

  final String id;
  final String name;
  final String instruction;

  factory RewriteStyle.fromJson(Map<String, dynamic> j) =>
      RewriteStyle(id: '${j['id']}', name: '${j['name'] ?? ''}', instruction: '${j['instruction'] ?? ''}');
  Map<String, Object?> toJson() => {'id': id, 'name': name, 'instruction': instruction};
}

@immutable
class AiWeekStats {
  const AiWeekStats({
    this.answered = 0,
    this.hoursSaved = 0,
    this.resolutionRate,
    this.thumbsUpRate,
    this.handoffs = 0,
    this.topHandoffReasons = const [],
    this.topSources = const [],
    this.daily = const [],
  });

  final int answered;
  final int hoursSaved;
  final double? resolutionRate;
  final double? thumbsUpRate;
  final int handoffs;

  /// (reason, count)
  final List<(String, int)> topHandoffReasons;

  /// (kb_id, title, count)
  final List<(String, String, int)> topSources;

  /// (date, answered, handoffs)
  final List<(DateTime, int, int)> daily;

  bool get hasData => answered > 0 || handoffs > 0;

  factory AiWeekStats.fromJson(Map<String, dynamic> j) => AiWeekStats(
        answered: _int(j['answered']),
        hoursSaved: _int(j['hours_saved']),
        resolutionRate: _double(j['resolution_rate']),
        thumbsUpRate: _double(j['thumbs_up_rate']),
        handoffs: _int(j['handoffs']),
        topHandoffReasons: [for (final r in _list(j['top_handoff_reasons'])) ('${r['reason']}', _int(r['count']))],
        topSources: [for (final s in _list(j['top_sources'])) ('${s['kb_id']}', '${s['title'] ?? ''}', _int(s['count']))],
        daily: [
          for (final d in _list(j['daily']))
            (DateTime.tryParse('${d['date']}') ?? DateTime.now(), _int(d['answered']), _int(d['handoffs'])),
        ],
      );

  Map<String, Object?> toJson() => {
        'answered': answered,
        'hours_saved': hoursSaved,
        'resolution_rate': resolutionRate,
        'thumbs_up_rate': thumbsUpRate,
        'handoffs': handoffs,
        'top_handoff_reasons': [for (final r in topHandoffReasons) {'reason': r.$1, 'count': r.$2}],
        'top_sources': [for (final s in topSources) {'kb_id': s.$1, 'title': s.$2, 'count': s.$3}],
        'daily': [for (final d in daily) {'date': d.$1.toIso8601String().substring(0, 10), 'answered': d.$2, 'handoffs': d.$3}],
      };
}

@immutable
class AiReadinessFacts {
  const AiReadinessFacts({this.kbEntries = 0, this.kbMin = 10, this.hoursSet = false, this.handoffSet = false, this.tested = false});

  final int kbEntries;
  final int kbMin;
  final bool hoursSet;
  final bool handoffSet;
  final bool tested;

  AiReadinessFacts copyWith({bool? hoursSet, bool? handoffSet, bool? tested}) => AiReadinessFacts(
        kbEntries: kbEntries,
        kbMin: kbMin,
        hoursSet: hoursSet ?? this.hoursSet,
        handoffSet: handoffSet ?? this.handoffSet,
        tested: tested ?? this.tested,
      );

  factory AiReadinessFacts.fromJson(Map<String, dynamic> j) => AiReadinessFacts(
        kbEntries: _int(j['kb_entries']),
        kbMin: _int(j['kb_min'], 10),
        hoursSet: j['hours_set'] == true,
        handoffSet: j['handoff_set'] == true,
        tested: j['tested'] == true,
      );
  Map<String, Object?> toJson() =>
      {'kb_entries': kbEntries, 'kb_min': kbMin, 'hours_set': hoursSet, 'handoff_set': handoffSet, 'tested': tested};
}

@immutable
class AiUsage {
  const AiUsage({required this.used, this.limit, this.resetsAt});

  final int used;

  /// null = unlimited.
  final int? limit;
  final DateTime? resetsAt;

  double? get share => (limit ?? 0) > 0 ? used / limit! : null;
  bool get exhausted => limit != null && used >= limit!;

  factory AiUsage.fromJson(Map<String, dynamic> j) => AiUsage(
        used: _int(j['used']),
        limit: (j['limit'] as num?)?.toInt(),
        resetsAt: DateTime.tryParse('${j['resets_at']}'),
      );
  Map<String, Object?> toJson() => {'used': used, 'limit': limit, 'resets_at': resetsAt?.toIso8601String().substring(0, 10)};
}

/// The whole AI agent configuration + facts. Editable fields have wire
/// names in [AiAgentConfig.toPatch].
@immutable
class AiAgentConfig {
  const AiAgentConfig({
    required this.version,
    required this.enabled,
    required this.mode,
    required this.tone,
    this.useCustomerName = true,
    this.language = LanguagePolicy.customer,
    this.arabicStyle = ArabicStyle.msa,
    this.autoReplyDelaySeconds = 0,
    required this.hours,
    required this.handoff,
    this.channels = const {},
    this.customInstructions = '',
    this.allowOutsideKb = false,
    this.confidence = ConfidenceLevel.medium,
    this.rewriteStyles = const [],
    this.stats = const AiWeekStats(),
    this.readiness = const AiReadinessFacts(),
    this.usage = const AiUsage(used: 0),
    this.handlingNow = 0,
    this.planAllowsAi = true,
    this.canEdit = false,
    this.unansweredCount = 0,
    this.autoConfirmed = false,
    this.replyWhenClaimed = false,
    this.suggestionCount = 3,
    this.answerSource = 'knowledge',
    this.answerSources = const ['knowledge'],
    this.serverHasWebSettings = true,
  });

  final int version;
  final bool enabled;
  final AiMode mode;
  final AiTone tone;
  final bool useCustomerName;
  final LanguagePolicy language;
  final ArabicStyle arabicStyle;
  final int autoReplyDelaySeconds;
  final WorkingHours hours;
  final HandoffRules handoff;

  /// channel key (whatsapp, web, messenger) → enabled. Ordered as received.
  final Map<String, bool> channels;
  final String customInstructions;
  final bool allowOutsideKb;
  final ConfidenceLevel confidence;
  final List<RewriteStyle> rewriteStyles;
  final AiWeekStats stats;
  final AiReadinessFacts readiness;
  final AiUsage usage;
  final int handlingNow;
  final bool planAllowsAi;
  final bool canEdit;

  /// Unanswered KB questions (performance row).
  final int unansweredCount;

  /// The first-time auto-reply confirmation (§6.3) was accepted before.
  final bool autoConfirmed;

  /// Web: the AI still answers when an agent has taken the conversation.
  final bool replyWhenClaimed;

  /// Web: suggestions offered per customer message (1–5).
  final int suggestionCount;

  /// knowledge | flow (bot organisation; only when [answerSources] has it).
  final String answerSource;
  final List<String> answerSources;

  /// The server knows the web panel's extra settings (hybrid mode, every web
  /// language, suggestion count, reply when claimed). An older server
  /// rejects them (422), so the screen hides them there.
  final bool serverHasWebSettings;

  AiAgentConfig copyWith({
    int? version,
    bool? enabled,
    AiMode? mode,
    AiTone? tone,
    bool? useCustomerName,
    LanguagePolicy? language,
    ArabicStyle? arabicStyle,
    int? autoReplyDelaySeconds,
    WorkingHours? hours,
    HandoffRules? handoff,
    Map<String, bool>? channels,
    String? customInstructions,
    bool? allowOutsideKb,
    ConfidenceLevel? confidence,
    List<RewriteStyle>? rewriteStyles,
    AiReadinessFacts? readiness,
    bool? autoConfirmed,
    bool? replyWhenClaimed,
    int? suggestionCount,
    String? answerSource,
  }) =>
      AiAgentConfig(
        version: version ?? this.version,
        enabled: enabled ?? this.enabled,
        mode: mode ?? this.mode,
        tone: tone ?? this.tone,
        useCustomerName: useCustomerName ?? this.useCustomerName,
        language: language ?? this.language,
        arabicStyle: arabicStyle ?? this.arabicStyle,
        autoReplyDelaySeconds: autoReplyDelaySeconds ?? this.autoReplyDelaySeconds,
        hours: hours ?? this.hours,
        handoff: handoff ?? this.handoff,
        channels: channels ?? this.channels,
        customInstructions: customInstructions ?? this.customInstructions,
        allowOutsideKb: allowOutsideKb ?? this.allowOutsideKb,
        confidence: confidence ?? this.confidence,
        rewriteStyles: rewriteStyles ?? this.rewriteStyles,
        stats: stats,
        readiness: readiness ?? this.readiness,
        usage: usage,
        handlingNow: handlingNow,
        planAllowsAi: planAllowsAi,
        canEdit: canEdit,
        unansweredCount: unansweredCount,
        autoConfirmed: autoConfirmed ?? this.autoConfirmed,
        replyWhenClaimed: replyWhenClaimed ?? this.replyWhenClaimed,
        suggestionCount: suggestionCount ?? this.suggestionCount,
        answerSource: answerSource ?? this.answerSource,
        answerSources: answerSources,
        serverHasWebSettings: serverHasWebSettings,
      );

  factory AiAgentConfig.fromJson(Map<String, dynamic> j) {
    final lang = _map(j['language']);
    return AiAgentConfig(
      version: _int(j['version'], 1),
      enabled: j['enabled'] == true,
      mode: AiMode.parse(j['mode']),
      tone: AiTone.parse(j['tone']),
      useCustomerName: j['use_customer_name'] != false,
      language: LanguagePolicy.parse(lang['policy']),
      arabicStyle: ArabicStyle.parse(lang['arabic_style']),
      autoReplyDelaySeconds: _int(j['auto_reply_delay_seconds']),
      hours: WorkingHours.fromJson(_map(j['hours'])),
      handoff: HandoffRules.fromJson(_map(j['handoff'])),
      channels: {for (final c in _list(j['channels'])) '${c['channel']}': c['enabled'] == true},
      customInstructions: '${j['custom_instructions'] ?? ''}',
      allowOutsideKb: j['allow_outside_kb'] == true,
      confidence: ConfidenceLevel.parse(j['confidence_threshold']),
      rewriteStyles: [for (final s in _list(j['rewrite_styles'])) RewriteStyle.fromJson(s)],
      stats: AiWeekStats.fromJson(_map(j['stats_week'])),
      readiness: AiReadinessFacts.fromJson(_map(j['readiness'])),
      usage: AiUsage.fromJson(_map(j['usage'])),
      handlingNow: _int(j['handling_now']),
      planAllowsAi: j['plan_allows_ai'] != false,
      canEdit: _map(j['permissions'])['can_edit'] == true,
      unansweredCount: _int(j['unanswered_count']),
      autoConfirmed: j['auto_confirmed'] == true,
      replyWhenClaimed: j['reply_when_claimed'] == true,
      suggestionCount: _int(j['suggestion_count'], 3).clamp(1, 5),
      answerSource: '${j['answer_source'] ?? 'knowledge'}',
      answerSources: [for (final s in _list(j['answer_sources'])) '$s'],
      serverHasWebSettings: j.containsKey('suggestion_count'),
    );
  }

  Map<String, Object?> toJson() => {
        'version': version,
        'enabled': enabled,
        'mode': mode.wire,
        'tone': tone.name,
        'use_customer_name': useCustomerName,
        'language': {'policy': language.name, 'arabic_style': arabicStyle.name},
        'auto_reply_delay_seconds': autoReplyDelaySeconds,
        'hours': hours.toJson(),
        'handoff': handoff.toJson(),
        'channels': [for (final e in channels.entries) {'channel': e.key, 'enabled': e.value}],
        'custom_instructions': customInstructions,
        'allow_outside_kb': allowOutsideKb,
        'confidence_threshold': confidence.name,
        'rewrite_styles': [for (final s in rewriteStyles) s.toJson()],
        'stats_week': stats.toJson(),
        'readiness': readiness.toJson(),
        'usage': usage.toJson(),
        'handling_now': handlingNow,
        'plan_allows_ai': planAllowsAi,
        'permissions': {'can_edit': canEdit},
        'unanswered_count': unansweredCount,
        'auto_confirmed': autoConfirmed,
        'reply_when_claimed': replyWhenClaimed,
        'suggestion_count': suggestionCount,
        'answer_source': answerSource,
        'answer_sources': answerSources,
      };

  /// Editable fields only, wire names (the PATCH body adds `version`).
  Map<String, Object?> editable() {
    final j = toJson();
    final keys = [
      'enabled', 'mode', 'tone', 'use_customer_name', 'language', 'auto_reply_delay_seconds', 'hours', 'handoff',
      'channels', 'custom_instructions', 'allow_outside_kb', 'confidence_threshold', 'auto_confirmed',
      'answer_source',
      if (serverHasWebSettings) ...['reply_when_claimed', 'suggestion_count'],
    ];
    return {for (final k in keys) k: j[k]};
  }
}

/// `POST ai-agent/test` answer.
@immutable
class AiTestReply {
  const AiTestReply({
    required this.id,
    required this.reply,
    this.sources = const [],
    this.confidence,
    this.ruleTriggered,
    this.handoff = false,
    required this.tone,
  });

  final String id;
  final String reply;

  /// (kb_id, title)
  final List<(String, String)> sources;

  /// 0..1
  final double? confidence;

  /// e.g. "human_request", "keyword:محامي", "no_answer".
  final String? ruleTriggered;
  final bool handoff;
  final AiTone tone;

  factory AiTestReply.fromJson(Map<String, dynamic> j) => AiTestReply(
        id: '${j['reply_id'] ?? j['id'] ?? ''}',
        reply: '${j['reply'] ?? ''}',
        sources: [for (final s in _list(j['sources'])) ('${s['kb_id']}', '${s['title'] ?? ''}')],
        confidence: _double(j['confidence']),
        ruleTriggered: j['rule_triggered'] as String?,
        handoff: j['handoff'] == true,
        tone: AiTone.parse(j['tone']),
      );
}

/// One `GET ai-agent/audit` row.
@immutable
class AiAuditEntry {
  const AiAuditEntry({required this.id, required this.actorName, required this.at, required this.changes});

  final String id;
  final String actorName;
  final DateTime at;

  /// Field keys that changed (wire names, e.g. "mode", "hours").
  final List<String> changes;

  factory AiAuditEntry.fromJson(Map<String, dynamic> j) => AiAuditEntry(
        id: '${j['id']}',
        actorName: '${_map(j['actor'])['name'] ?? ''}',
        at: DateTime.tryParse('${j['at']}')?.toLocal() ?? DateTime.now(),
        changes: [for (final c in (j['changes'] as List? ?? const [])) '$c'],
      );
}
