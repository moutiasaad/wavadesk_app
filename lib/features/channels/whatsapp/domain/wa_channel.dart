import 'package:flutter/foundation.dart';

import 'wa_status.dart';

/// `GET /mobile/v1/channels/whatsapp` (WhatsApp spec §8).

DateTime? _date(Object? v) => v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;
int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};
List<String> _strings(Object? v) => v is List ? [for (final s in v) '$s'] : const [];

enum WaConnectionType {
  linkedDevice('linked_device'),
  cloudApi('cloud_api');

  const WaConnectionType(this.wire);
  final String wire;

  static WaConnectionType parse(Object? v) => v == 'cloud_api' ? cloudApi : linkedDevice;
}

enum WaQualityRating {
  high,
  medium,
  low;

  static WaQualityRating? parse(Object? v) => switch ('$v'.toLowerCase()) {
        'high' || 'green' => high,
        'medium' || 'yellow' => medium,
        'low' || 'red' => low,
        _ => null,
      };
}

@immutable
class WaDevice {
  const WaDevice({this.model, this.waApp, this.waVersion});

  static WaDevice? fromJson(Object? j) {
    if (j is! Map) return null;
    return WaDevice(model: j['model'] as String?, waApp: j['wa_app'] as String?, waVersion: j['wa_version'] as String?);
  }

  final String? model;

  /// `business` | `personal`.
  final String? waApp;
  final String? waVersion;

  bool get isBusiness => waApp == 'business';

  Map<String, Object?> toJson() => {'model': model, 'wa_app': waApp, 'wa_version': waVersion};
}

@immutable
class WaStatsToday {
  const WaStatsToday({this.messages = 0, this.inbound = 0, this.outbound = 0});

  factory WaStatsToday.fromJson(Map<String, dynamic> m) =>
      WaStatsToday(messages: _int(m['messages']), inbound: _int(m['inbound']), outbound: _int(m['outbound']));

  final int messages;
  final int inbound;
  final int outbound;

  Map<String, Object?> toJson() => {'messages': messages, 'inbound': inbound, 'outbound': outbound};
}

@immutable
class WaQuality {
  const WaQuality({this.rating, this.stable, this.messagingTier, this.dailyUsed = 0, this.dailyLimit = 0, this.trend = const []});

  factory WaQuality.fromJson(Map<String, dynamic> m) => WaQuality(
        rating: WaQualityRating.parse(m['rating']),
        stable: switch (m['stability']) { 'stable' => true, 'unstable' => false, _ => null },
        messagingTier: m['messaging_tier'] as String?,
        dailyUsed: _int(m['daily_used']),
        dailyLimit: _int(m['daily_limit']),
        trend: [for (final v in (m['trend'] as List? ?? const [])) WaQualityRating.parse(v is Map ? v['rating'] : v) ?? WaQualityRating.medium],
      );

  final WaQualityRating? rating;

  /// linked_device: stable / unstable connection (null = unknown).
  final bool? stable;

  /// `1K` | `10K` | `100K` (cloud_api).
  final String? messagingTier;
  final int dailyUsed;
  final int dailyLimit;

  /// Last 7 days, oldest first (cloud_api).
  final List<WaQualityRating> trend;

  double get limitUsage => dailyLimit <= 0 ? 0 : dailyUsed / dailyLimit;

  Map<String, Object?> toJson() => {
        'rating': rating?.name,
        'stability': stable == null ? null : (stable! ? 'stable' : 'unstable'),
        'messaging_tier': messagingTier,
        'daily_used': dailyUsed,
        'daily_limit': dailyLimit,
        'trend': [for (final r in trend) r.name],
      };
}

enum WaWelcomeTrigger {
  firstMessage('first_message'),
  newConversation('new_conversation'),
  after24h('after_24h');

  const WaWelcomeTrigger(this.wire);
  final String wire;

  static WaWelcomeTrigger parse(Object? v) => values.firstWhere((t) => t.wire == v, orElse: () => firstMessage);
}

enum WaAwayWhen {
  outsideHours('outside_hours'),
  teamAway('team_away');

  const WaAwayWhen(this.wire);
  final String wire;

  static WaAwayWhen parse(Object? v) => v == 'team_away' ? teamAway : outsideHours;
}

@immutable
class WaWelcome {
  const WaWelcome({
    this.enabled = false,
    this.text = '',
    this.trigger = WaWelcomeTrigger.firstMessage,
    this.delaySeconds = 0,
    this.buttons = const [],
  });

  factory WaWelcome.fromJson(Map<String, dynamic> m) => WaWelcome(
        enabled: m['enabled'] == true,
        text: '${m['text'] ?? ''}',
        trigger: WaWelcomeTrigger.parse(m['trigger']),
        delaySeconds: _int(m['delay_seconds']),
        buttons: _strings(m['buttons']),
      );

  final bool enabled;
  final String text;
  final WaWelcomeTrigger trigger;
  final int delaySeconds;
  final List<String> buttons;

  WaWelcome copyWith({bool? enabled, String? text, WaWelcomeTrigger? trigger, int? delaySeconds, List<String>? buttons}) => WaWelcome(
        enabled: enabled ?? this.enabled,
        text: text ?? this.text,
        trigger: trigger ?? this.trigger,
        delaySeconds: delaySeconds ?? this.delaySeconds,
        buttons: buttons ?? this.buttons,
      );

  Map<String, Object?> toJson() =>
      {'enabled': enabled, 'text': text, 'trigger': trigger.wire, 'delay_seconds': delaySeconds, 'buttons': buttons};
}

@immutable
class WaAway {
  const WaAway({this.enabled = false, this.text = '', this.when = WaAwayWhen.outsideHours, this.cooldownHours = 6, this.handledByAi = false});

  factory WaAway.fromJson(Map<String, dynamic> m) => WaAway(
        enabled: m['enabled'] == true,
        text: '${m['text'] ?? ''}',
        when: WaAwayWhen.parse(m['when']),
        cooldownHours: _int(m['cooldown_hours'], 6),
        handledByAi: m['handled_by_ai'] == true,
      );

  final bool enabled;
  final String text;
  final WaAwayWhen when;
  final int cooldownHours;

  /// AI auto mode covers after-hours (AI Agent spec): the away message is
  /// read-only and its switch disabled.
  final bool handledByAi;

  WaAway copyWith({bool? enabled, String? text, WaAwayWhen? when, int? cooldownHours}) => WaAway(
        enabled: enabled ?? this.enabled,
        text: text ?? this.text,
        when: when ?? this.when,
        cooldownHours: cooldownHours ?? this.cooldownHours,
        handledByAi: handledByAi,
      );

  /// `handled_by_ai` is server-owned, never written.
  Map<String, Object?> toJson() => {'enabled': enabled, 'text': text, 'when': when.wire, 'cooldown_hours': cooldownHours};
}

@immutable
class WaAdvanced {
  const WaAdvanced({this.sendReadReceipts = true, this.markReadOnOpen = true, this.autoTranscribeVoice = true, this.ignoreGroups = true});

  factory WaAdvanced.fromJson(Map<String, dynamic> m) => WaAdvanced(
        sendReadReceipts: m['send_read_receipts'] != false,
        markReadOnOpen: m['mark_read_on_open'] != false,
        autoTranscribeVoice: m['auto_transcribe_voice'] != false,
        ignoreGroups: m['ignore_groups'] != false,
      );

  final bool sendReadReceipts;
  final bool markReadOnOpen;
  final bool autoTranscribeVoice;
  final bool ignoreGroups;

  WaAdvanced copyWith({bool? sendReadReceipts, bool? markReadOnOpen, bool? autoTranscribeVoice, bool? ignoreGroups}) => WaAdvanced(
        sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
        markReadOnOpen: markReadOnOpen ?? this.markReadOnOpen,
        autoTranscribeVoice: autoTranscribeVoice ?? this.autoTranscribeVoice,
        ignoreGroups: ignoreGroups ?? this.ignoreGroups,
      );

  Map<String, Object?> toJson() => {
        'send_read_receipts': sendReadReceipts,
        'mark_read_on_open': markReadOnOpen,
        'auto_transcribe_voice': autoTranscribeVoice,
        'ignore_groups': ignoreGroups,
      };
}

@immutable
class WaNumber {
  const WaNumber({required this.id, required this.phone, this.displayName, this.status = WaStatus.connected});

  factory WaNumber.fromJson(Map<String, dynamic> m) => WaNumber(
        id: '${m['id']}',
        phone: '${m['phone'] ?? ''}',
        displayName: m['display_name'] as String?,
        status: WaStatus.parse(m['status']),
      );

  final String id;
  final String phone;
  final String? displayName;
  final WaStatus status;

  Map<String, Object?> toJson() => {'id': id, 'phone': phone, 'display_name': displayName, 'status': status.wire};
}

@immutable
class WaPermissions {
  const WaPermissions({this.canConnect = false, this.canDisconnect = false, this.canEditAuto = false, this.canEditAdvanced = false});

  factory WaPermissions.fromJson(Map<String, dynamic> m) => WaPermissions(
        canConnect: m['can_connect'] == true,
        canDisconnect: m['can_disconnect'] == true,
        canEditAuto: m['can_edit_auto'] == true || m['can_edit_auto_messages'] == true,
        canEditAdvanced: m['can_edit_advanced'] == true || (!m.containsKey('can_edit_advanced') && m['can_connect'] == true),
      );

  final bool canConnect;
  final bool canDisconnect;
  final bool canEditAuto;
  final bool canEditAdvanced;

  /// Owner/admin view: numbers, advanced, disconnect, ⋮ menu.
  bool get isAdmin => canConnect;

  Map<String, Object?> toJson() =>
      {'can_connect': canConnect, 'can_disconnect': canDisconnect, 'can_edit_auto': canEditAuto, 'can_edit_advanced': canEditAdvanced};
}

@immutable
class WaChannel {
  const WaChannel({
    required this.id,
    this.connectionType = WaConnectionType.linkedDevice,
    this.status = WaStatus.pending,
    this.statusSince,
    this.displayName,
    this.phone,
    this.linkedAt,
    this.device,
    this.statsToday = const WaStatsToday(),
    this.quality = const WaQuality(),
    this.welcome = const WaWelcome(),
    this.away = const WaAway(),
    this.quickRepliesCount = 0,
    this.advanced = const WaAdvanced(),
    this.numbers = const [],
    this.extraNumbersAllowed = 0,
    this.upgradeUrl,
    this.templatesSupported = false,
    this.permissions = const WaPermissions(),
    this.openConversations = 0,
    this.appOutdated = false,
    this.planHasWhatsApp = true,
    this.lastActivityAt,
    this.phoneNumberId,
    this.fetchedAt,
  });

  factory WaChannel.fromJson(Map<String, dynamic> j) {
    final auto = _map(j['auto_messages']);
    final plan = _map(j['plan']);
    return WaChannel(
      id: '${j['id'] ?? 'ch_wa'}',
      connectionType: WaConnectionType.parse(j['connection_type']),
      status: WaStatus.parse(j['status']),
      statusSince: _date(j['status_since']),
      displayName: j['display_name'] as String?,
      phone: j['phone'] as String?,
      linkedAt: _date(j['linked_at']),
      device: WaDevice.fromJson(j['device']),
      statsToday: WaStatsToday.fromJson(_map(j['stats_today'])),
      quality: WaQuality.fromJson(_map(j['quality'])),
      welcome: WaWelcome.fromJson(_map(auto['welcome'])),
      away: WaAway.fromJson(_map(auto['away'])),
      quickRepliesCount: _int(j['quick_replies_count']),
      advanced: WaAdvanced.fromJson(_map(j['advanced'])),
      numbers: [for (final n in (j['numbers'] as List? ?? const [])) WaNumber.fromJson(_map(n))],
      extraNumbersAllowed: _int(plan['extra_numbers_allowed']),
      upgradeUrl: plan['upgrade_url'] as String?,
      templatesSupported: j['templates_supported'] == true,
      permissions: WaPermissions.fromJson(_map(j['permissions'])),
      openConversations: _int(j['open_conversations'] ?? _map(j['disconnect'])['open_conversations']),
      appOutdated: j['app_outdated'] == true,
      planHasWhatsApp: plan['whatsapp'] != false && j['plan_allows'] != false,
      lastActivityAt: _date(j['last_activity_at']),
      phoneNumberId: j['phone_number_id'] as String?,
      fetchedAt: DateTime.now(),
    );
  }

  final String id;
  final WaConnectionType connectionType;
  final WaStatus status;
  final DateTime? statusSince;
  final String? displayName;

  /// E.164.
  final String? phone;
  final DateTime? linkedAt;
  final WaDevice? device;
  final WaStatsToday statsToday;
  final WaQuality quality;
  final WaWelcome welcome;
  final WaAway away;
  final int quickRepliesCount;
  final WaAdvanced advanced;

  /// Additional numbers (beyond this one).
  final List<WaNumber> numbers;
  final int extraNumbersAllowed;
  final String? upgradeUrl;
  final bool templatesSupported;
  final WaPermissions permissions;

  /// Extra (not in §8's sample): open chats that stop on disconnect (§6.2).
  final int openConversations;

  /// Extra: WhatsApp app outdated / multi-device off (§4.3).
  final bool appOutdated;

  /// "Plan without WhatsApp" state (§7).
  final bool planHasWhatsApp;
  final DateTime? lastActivityAt;

  /// cloud_api phone number id (details sheet, copyable).
  final String? phoneNumberId;

  /// When this copy was fetched ("آخر تحديث {t}" offline).
  final DateTime? fetchedAt;

  bool get isCloud => connectionType == WaConnectionType.cloudApi;
  bool get isPending => status == WaStatus.pending;

  /// Last 4 digits for the disconnect check (§6.2).
  String get last4 {
    final d = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return d.length <= 4 ? d : d.substring(d.length - 4);
  }

  int? get linkedDays => linkedAt == null ? null : DateTime.now().difference(linkedAt!).inDays;

  WaChannel copyWith({
    WaStatus? status,
    DateTime? statusSince,
    WaWelcome? welcome,
    WaAway? away,
    WaAdvanced? advanced,
    int? quickRepliesCount,
    String? phone,
    String? displayName,
    DateTime? linkedAt,
    WaStatsToday? statsToday,
  }) =>
      WaChannel(
        id: id,
        connectionType: connectionType,
        status: status ?? this.status,
        statusSince: statusSince ?? this.statusSince,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        linkedAt: linkedAt ?? this.linkedAt,
        device: device,
        statsToday: statsToday ?? this.statsToday,
        quality: quality,
        welcome: welcome ?? this.welcome,
        away: away ?? this.away,
        quickRepliesCount: quickRepliesCount ?? this.quickRepliesCount,
        advanced: advanced ?? this.advanced,
        numbers: numbers,
        extraNumbersAllowed: extraNumbersAllowed,
        upgradeUrl: upgradeUrl,
        templatesSupported: templatesSupported,
        permissions: permissions,
        openConversations: openConversations,
        appOutdated: appOutdated,
        planHasWhatsApp: planHasWhatsApp,
        lastActivityAt: lastActivityAt,
        phoneNumberId: phoneNumberId,
        fetchedAt: fetchedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'connection_type': connectionType.wire,
        'status': status.wire,
        'status_since': statusSince?.toUtc().toIso8601String(),
        'display_name': displayName,
        'phone': phone,
        'linked_at': linkedAt?.toUtc().toIso8601String(),
        'device': device?.toJson(),
        'stats_today': statsToday.toJson(),
        'quality': quality.toJson(),
        'auto_messages': {'welcome': welcome.toJson(), 'away': {...away.toJson(), 'handled_by_ai': away.handledByAi}},
        'quick_replies_count': quickRepliesCount,
        'advanced': advanced.toJson(),
        'numbers': [for (final n in numbers) n.toJson()],
        'plan': {'extra_numbers_allowed': extraNumbersAllowed, 'upgrade_url': upgradeUrl, 'whatsapp': planHasWhatsApp},
        'templates_supported': templatesSupported,
        'permissions': permissions.toJson(),
        'open_conversations': openConversations,
        'app_outdated': appOutdated,
        'last_activity_at': lastActivityAt?.toUtc().toIso8601String(),
        'phone_number_id': phoneNumberId,
      };
}

// ---- Connect flow ------------------------------------------------------------------

enum WaConnectMethod { phone, qr }

/// `POST connect/pairing-code` → `{code, expires_at, session_id}`;
/// `POST connect/qr` → `{qr_payload, expires_at, session_id}`.
@immutable
class WaConnectSession {
  const WaConnectSession({required this.sessionId, required this.expiresAt, this.code, this.qrPayload, this.qrIsImage = false});

  factory WaConnectSession.fromJson(Map<String, dynamic> m) => WaConnectSession(
        sessionId: '${m['session_id'] ?? ''}',
        expiresAt: _date(m['expires_at']) ?? DateTime.now().add(const Duration(seconds: 160)),
        code: m['code'] as String?,
        qrPayload: m['qr_payload'] as String?,
        qrIsImage: m['qr_format'] == 'image_data_uri' || '${m['qr_payload'] ?? ''}'.startsWith('data:image'),
      );

  final String sessionId;
  final DateTime expiresAt;
  final String? code;

  /// Raw QR text (render with qr_flutter) or, when [qrIsImage], a PNG data
  /// URI from the gateway. Often null at first: the session poll fills it.
  final String? qrPayload;
  final bool qrIsImage;

  WaConnectSession withQr(String payload) => WaConnectSession(
        sessionId: sessionId,
        expiresAt: expiresAt,
        code: code,
        qrPayload: payload,
        qrIsImage: qrIsImage || payload.startsWith('data:image'),
      );
}

enum WaSessionStatus {
  waiting,
  linked,
  expired,
  failed;

  static WaSessionStatus parse(Object? v) => values.asNameMap()['$v'] ?? waiting;
}

@immutable
class WaSessionState {
  const WaSessionState({required this.status, this.errorCode, this.backlogSynced = false, this.qrPayload, this.phone});

  factory WaSessionState.fromJson(Map<String, dynamic> m) => WaSessionState(
        status: WaSessionStatus.parse(m['status']),
        errorCode: m['error_code'] as String?,
        backlogSynced: m['backlog_synced'] == true,
        qrPayload: m['qr_payload'] as String?,
        phone: m['phone'] as String?,
      );

  final WaSessionStatus status;

  /// Latest QR while waiting (QR method).
  final String? qrPayload;

  /// The linked number (linked).
  final String? phone;

  /// `number_taken` | `rate_limited` | `multi_device_unsupported` | …
  final String? errorCode;
  final bool backlogSynced;
}

// ---- Log + templates ---------------------------------------------------------------

enum WaLogKind {
  connected,
  disconnected,
  disconnectedBy,
  reconnected,
  connectStarted,
  recovered,
  other;

  static WaLogKind parse(Object? v) => switch ('$v') {
        'connected' => connected,
        'disconnected' => disconnected,
        'disconnected_by' => disconnectedBy,
        'reconnected' || 'reconnected_by' => reconnected,
        'connect_started' => connectStarted,
        'recovered' || 'messages_recovered' => recovered,
        _ => other,
      };
}

@immutable
class WaLogEntry {
  const WaLogEntry({required this.id, required this.kind, required this.at, this.durationSeconds, this.reason, this.by, this.count});

  factory WaLogEntry.fromJson(Map<String, dynamic> m) => WaLogEntry(
        id: '${m['id']}',
        kind: WaLogKind.parse(m['kind'] ?? m['type']),
        at: _date(m['at']) ?? DateTime.now(),
        durationSeconds: m['duration_seconds'] == null ? null : _int(m['duration_seconds']),
        reason: m['reason'] as String?,
        by: m['by'] is Map ? '${(m['by'] as Map)['name']}' : m['by'] as String?,
        count: m['count'] == null ? null : _int(m['count']),
      );

  final String id;
  final WaLogKind kind;
  final DateTime at;
  final int? durationSeconds;

  /// `phone_offline` | `logged_out` | `update` | free text.
  final String? reason;
  final String? by;
  final int? count;
}

enum WaTemplateCategory {
  marketing,
  utility,
  authentication;

  static WaTemplateCategory parse(Object? v) => switch ('$v'.toLowerCase()) {
        'marketing' => marketing,
        'authentication' || 'auth' => authentication,
        _ => utility,
      };
}

enum WaTemplateStatus {
  approved,
  pending,
  rejected;

  static WaTemplateStatus parse(Object? v) => switch ('$v'.toLowerCase()) {
        'approved' => approved,
        'rejected' => rejected,
        _ => pending,
      };
}

@immutable
class WaTemplate {
  const WaTemplate({
    required this.id,
    required this.name,
    this.displayName,
    required this.category,
    required this.status,
    this.body = '',
    this.language,
    this.buttons = const [],
  });

  factory WaTemplate.fromJson(Map<String, dynamic> m) => WaTemplate(
        id: '${m['id']}',
        name: '${m['name'] ?? ''}',
        displayName: m['display_name'] as String?,
        category: WaTemplateCategory.parse(m['category']),
        status: WaTemplateStatus.parse(m['status']),
        body: '${m['body'] ?? ''}',
        language: m['language'] as String?,
        buttons: _strings(m['buttons']),
      );

  final String id;

  /// Meta template name (LTR id, e.g. `order_shipped`).
  final String name;
  final String? displayName;
  final WaTemplateCategory category;
  final WaTemplateStatus status;

  /// With `{{1}}` placeholders.
  final String body;
  final String? language;
  final List<String> buttons;
}

/// A blocked contact (§4.7 "حظر الأرقام").
@immutable
class WaBlockedContact {
  const WaBlockedContact({required this.id, required this.phone, this.name, this.blockedAt});

  factory WaBlockedContact.fromJson(Map<String, dynamic> m) => WaBlockedContact(
        id: '${m['id']}',
        phone: '${m['phone'] ?? ''}',
        name: m['name'] as String?,
        blockedAt: _date(m['blocked_at']),
      );

  final String id;
  final String phone;
  final String? name;
  final DateTime? blockedAt;
}
