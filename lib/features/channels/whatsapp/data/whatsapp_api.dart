import 'dart:async';
import 'dart:math';

import '../../../../core/api/wd_api.dart';
import '../domain/wa_channel.dart';
import '../domain/wa_status.dart';

class WaApiException implements Exception {
  const WaApiException(this.status, {this.code, this.message, this.details = const {}});

  /// 0 = network.
  final int status;
  final String? code;
  final String? message;
  final Map<String, dynamic> details;

  /// 409 `invalid_state` {reason: handled_by_ai}: the AI answers after hours.
  bool get handledByAi => status == 409 && details['reason'] == 'handled_by_ai';

  bool get isNetwork => status == 0;

  @override
  String toString() => 'WaApiException($status $code)';
}

/// WhatsApp spec §8.
abstract interface class WhatsAppApi {
  Future<WaChannel> fetch();
  Future<WaChannel> patchAutoMessages({WaWelcome? welcome, WaAway? away});
  Future<WaChannel> patchAdvanced(WaAdvanced advanced);
  Future<WaConnectSession> pairingCode(String phone);
  Future<WaConnectSession> qr();
  Future<WaSessionState> session(String sessionId);

  /// `confirm_last4` = the digits the admin typed.
  Future<void> disconnect(String confirmLast4);
  Future<WaChannel> refreshStatus();

  /// (rows, nextCursor)
  Future<(List<WaLogEntry>, String?)> log({String? cursor});
  Future<List<WaTemplate>> templates();
  Future<void> notifyAdmin();

  /// Not in §8: `GET channels/whatsapp/blocked` (empty when the server
  /// doesn't have it) + `DELETE channels/whatsapp/blocked/{id}`.
  Future<List<WaBlockedContact>> blocked();
  Future<void> unblock(String id);
}

class HttpWhatsAppApi implements WhatsAppApi {
  HttpWhatsAppApi(this._api);

  final WdApi _api;
  static const _base = 'channels/whatsapp';

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on WdApiException catch (e) {
      throw WaApiException(e.status, code: e.code, message: e.message, details: e.details);
    }
  }

  @override
  Future<WaChannel> fetch() => _guard(() async => WaChannel.fromJson((await _api.get(_base)).map));

  @override
  Future<WaChannel> patchAutoMessages({WaWelcome? welcome, WaAway? away}) => _guard(() async {
        final r = await _api.patch('$_base/auto-messages', body: {'welcome': ?welcome?.toJson(), 'away': ?away?.toJson()});
        // Older servers answer only the auto messages: reload the channel then.
        return r.map.containsKey('status') ? WaChannel.fromJson(r.map) : fetch();
      });

  @override
  Future<WaChannel> patchAdvanced(WaAdvanced advanced) => _guard(() async {
        final r = await _api.patch('$_base/advanced', body: advanced.toJson());
        return r.map.containsKey('status') ? WaChannel.fromJson(r.map) : fetch();
      });

  @override
  Future<WaConnectSession> pairingCode(String phone) =>
      _guard(() async => WaConnectSession.fromJson((await _api.post('$_base/connect/pairing-code', body: {'phone': phone})).map));

  @override
  Future<WaConnectSession> qr() =>
      _guard(() async => WaConnectSession.fromJson((await _api.post('$_base/connect/qr', body: const <String, Object?>{})).map));

  @override
  Future<WaSessionState> session(String sessionId) =>
      _guard(() async => WaSessionState.fromJson((await _api.get('$_base/connect/$sessionId')).map));

  @override
  Future<void> disconnect(String confirmLast4) => _guard(() => _api.post('$_base/disconnect', body: {'confirm_last4': confirmLast4}));

  @override
  Future<WaChannel> refreshStatus() => _guard(() async {
        final r = await _api.post('$_base/refresh-status', body: const <String, Object?>{});
        return r.map.containsKey('status') ? WaChannel.fromJson(r.map) : fetch();
      });

  @override
  Future<(List<WaLogEntry>, String?)> log({String? cursor}) => _guard(() async {
        final r = await _api.get('$_base/log', query: {'cursor': ?cursor});
        return ([for (final m in r.list) WaLogEntry.fromJson(m)], r.nextCursor);
      });

  @override
  Future<List<WaTemplate>> templates() => _guard(() async => [for (final m in (await _api.get('whatsapp/templates')).list) WaTemplate.fromJson(m)]);

  @override
  Future<void> notifyAdmin() => _guard(() => _api.post('$_base/notify-admin', body: const <String, Object?>{}));

  @override
  Future<List<WaBlockedContact>> blocked() async {
    try {
      return [for (final m in (await _api.get('$_base/blocked')).list) WaBlockedContact.fromJson(m)];
    } on WdApiException catch (e) {
      if (e.status == 404 || e.status == 501) return const [];
      throw WaApiException(e.status, code: e.code, message: e.message);
    }
  }

  @override
  Future<void> unblock(String id) => _guard(() => _api.delete('$_base/blocked/$id'));
}

/// Demo states the sample backend can show (⋮ → "Demo state" in sample mode).
enum WaDemoScenario { connected, phoneOffline, disconnected, pending, cloudApi, restricted }

/// In-memory backend for sample mode. Pairing codes link after ~6 s; the
/// number +966500000000 answers `number_taken`.
class SampleWhatsAppApi implements WhatsAppApi {
  SampleWhatsAppApi({required this.isAdmin}) {
    _channel = _build(scenario);
  }

  final bool isAdmin;

  static WaDemoScenario scenario = WaDemoScenario.connected;

  late WaChannel _channel;
  final _sessions = <String, DateTime>{};
  final _rng = Random();

  static const _latency = Duration(milliseconds: 450);

  Future<void> _wait([Duration d = _latency]) => Future<void>.delayed(d);

  WaChannel _build(WaDemoScenario s) {
    final now = DateTime.now();
    final cloud = s == WaDemoScenario.cloudApi || s == WaDemoScenario.restricted;
    final status = switch (s) {
      WaDemoScenario.connected || WaDemoScenario.cloudApi => WaStatus.connected,
      WaDemoScenario.phoneOffline => WaStatus.phoneOffline,
      WaDemoScenario.disconnected => WaStatus.disconnected,
      WaDemoScenario.pending => WaStatus.pending,
      WaDemoScenario.restricted => WaStatus.restricted,
    };
    final pending = s == WaDemoScenario.pending;
    return WaChannel(
      id: 'ch_wa_1',
      connectionType: cloud ? WaConnectionType.cloudApi : WaConnectionType.linkedDevice,
      status: status,
      statusSince: now.subtract(Duration(minutes: s == WaDemoScenario.disconnected ? 42 : 60 * 26)),
      displayName: pending ? null : 'متجر لمسة',
      phone: pending ? null : '+966501234567',
      linkedAt: pending ? null : now.subtract(const Duration(days: 26)),
      device: cloud || pending ? null : const WaDevice(model: 'iPhone 15', waApp: 'business', waVersion: '2.24.21'),
      statsToday: pending ? const WaStatsToday() : const WaStatsToday(messages: 186, inbound: 102, outbound: 84),
      quality: cloud
          ? WaQuality(
              rating: s == WaDemoScenario.restricted ? WaQualityRating.low : WaQualityRating.high,
              messagingTier: '1K',
              dailyUsed: s == WaDemoScenario.restricted ? 870 : 120,
              dailyLimit: 1000,
              trend: const [
                WaQualityRating.high,
                WaQualityRating.high,
                WaQualityRating.medium,
                WaQualityRating.high,
                WaQualityRating.high,
                WaQualityRating.high,
                WaQualityRating.high,
              ],
            )
          : WaQuality(stable: s != WaDemoScenario.phoneOffline),
      welcome: _channelOrNull?.welcome ??
          const WaWelcome(
            enabled: true,
            text: 'أهلًا بك في متجر لمسة 🌸 كيف نقدر نساعدك اليوم؟',
            buttons: ['تتبع طلبي', 'الأسعار', 'التحدث مع موظف'],
          ),
      away: _channelOrNull?.away ??
          const WaAway(
            text: 'شكرًا لتواصلك! فريقنا خارج الدوام الآن وسنعود {وقت_العودة}.',
            handledByAi: true,
          ),
      quickRepliesCount: _channelOrNull?.quickRepliesCount ?? 12,
      advanced: _channelOrNull?.advanced ?? const WaAdvanced(),
      numbers: const [],
      extraNumbersAllowed: 0,
      upgradeUrl: 'https://app.wavadesk.com/billing',
      templatesSupported: cloud,
      permissions: WaPermissions(canConnect: isAdmin, canDisconnect: isAdmin && !pending, canEditAuto: isAdmin, canEditAdvanced: isAdmin),
      openConversations: 7,
      lastActivityAt: now.subtract(const Duration(minutes: 3)),
      phoneNumberId: cloud ? '109876543210987' : null,
      fetchedAt: now,
    );
  }

  WaChannel? _channelOrNull;

  /// Switch the demo state (sample mode only).
  void setScenario(WaDemoScenario s) {
    scenario = s;
    _channelOrNull = _channel;
    _channel = _build(s);
  }

  @override
  Future<WaChannel> fetch() async {
    await _wait();
    // Live-ish stats so the 30 s poll visibly does something.
    if (_channel.status == WaStatus.connected && _rng.nextInt(3) == 0) {
      final s = _channel.statsToday;
      _channel = _channel.copyWith(statsToday: WaStatsToday(messages: s.messages + 1, inbound: s.inbound + 1, outbound: s.outbound));
    }
    return _channel;
  }

  @override
  Future<WaChannel> patchAutoMessages({WaWelcome? welcome, WaAway? away}) async {
    await _wait();
    if (!_channel.permissions.canEditAuto) throw const WaApiException(403, code: 'role_forbidden');
    _channel = _channel.copyWith(welcome: welcome, away: away);
    return _channel;
  }

  @override
  Future<WaChannel> patchAdvanced(WaAdvanced advanced) async {
    await _wait();
    _channel = _channel.copyWith(advanced: advanced);
    return _channel;
  }

  String _code() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final s = List.generate(8, (_) => chars[_rng.nextInt(chars.length)]).join();
    return '${s.substring(0, 4)}-${s.substring(4)}';
  }

  @override
  Future<WaConnectSession> pairingCode(String phone) async {
    await _wait(const Duration(milliseconds: 900));
    if (phone.replaceAll(RegExp(r'\D'), '') == '966500000000') {
      throw const WaApiException(409, code: 'number_taken');
    }
    final id = 'wcs_${_rng.nextInt(1 << 30)}';
    _sessions[id] = DateTime.now();
    return WaConnectSession(sessionId: id, code: _code(), expiresAt: DateTime.now().add(const Duration(seconds: 161)));
  }

  @override
  Future<WaConnectSession> qr() async {
    await _wait(const Duration(milliseconds: 700));
    final id = 'wcs_${_rng.nextInt(1 << 30)}';
    _sessions[id] = DateTime.now();
    return WaConnectSession(
      sessionId: id,
      qrPayload: '2@${List.generate(40, (_) => _rng.nextInt(36).toRadixString(36)).join()},wavadesk,${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(seconds: 20)),
    );
  }

  @override
  Future<WaSessionState> session(String sessionId) async {
    await _wait(const Duration(milliseconds: 250));
    final started = _sessions[sessionId];
    if (started == null) return const WaSessionState(status: WaSessionStatus.expired);
    if (DateTime.now().difference(started) < const Duration(seconds: 6)) return const WaSessionState(status: WaSessionStatus.waiting);
    final now = DateTime.now();
    final wasDown = _channel.status != WaStatus.connected;
    scenario = WaDemoScenario.connected;
    _channel = _channel.copyWith(
      status: WaStatus.connected,
      statusSince: now,
      phone: _channel.phone ?? '+966501234567',
      displayName: _channel.displayName ?? 'متجر لمسة',
      linkedAt: _channel.linkedAt ?? now,
    );
    return WaSessionState(status: WaSessionStatus.linked, backlogSynced: wasDown);
  }

  @override
  Future<void> disconnect(String confirmLast4) async {
    await _wait(const Duration(milliseconds: 800));
    if (confirmLast4 != _channel.last4) throw const WaApiException(422, code: 'confirmation_mismatch');
    scenario = WaDemoScenario.disconnected;
    _channel = _channel.copyWith(status: WaStatus.disconnected, statusSince: DateTime.now());
  }

  @override
  Future<WaChannel> refreshStatus() async {
    await _wait(const Duration(milliseconds: 900));
    // "تحقق مجددًا" on a phone-offline demo brings it back.
    if (_channel.status == WaStatus.phoneOffline) {
      scenario = WaDemoScenario.connected;
      _channel = _channel.copyWith(status: WaStatus.connected, statusSince: DateTime.now());
    }
    return _channel;
  }

  @override
  Future<(List<WaLogEntry>, String?)> log({String? cursor}) async {
    await _wait();
    final now = DateTime.now();
    return (
      [
        WaLogEntry(id: 'l1', kind: WaLogKind.recovered, at: now.subtract(const Duration(days: 2, hours: 3)), count: 14),
        WaLogEntry(id: 'l2', kind: WaLogKind.reconnected, at: now.subtract(const Duration(days: 2, hours: 3, minutes: 1)), by: 'نورة'),
        WaLogEntry(
          id: 'l3',
          kind: WaLogKind.disconnected,
          at: now.subtract(const Duration(days: 2, hours: 3, minutes: 19)),
          durationSeconds: 18 * 60,
          reason: 'phone_offline',
        ),
        WaLogEntry(id: 'l4', kind: WaLogKind.disconnected, at: now.subtract(const Duration(days: 11)), durationSeconds: 240, reason: 'update'),
        WaLogEntry(id: 'l5', kind: WaLogKind.connected, at: now.subtract(const Duration(days: 26)), by: 'نورة'),
      ],
      null,
    );
  }

  @override
  Future<List<WaTemplate>> templates() async {
    await _wait();
    if (!_channel.templatesSupported) return const [];
    return const [
      WaTemplate(
        id: 't1',
        name: 'order_shipped',
        displayName: 'تم شحن الطلب',
        category: WaTemplateCategory.utility,
        status: WaTemplateStatus.approved,
        body: 'مرحبًا {{1}}، تم شحن طلبك رقم {{2}} ويصلك خلال 2–3 أيام. تتبّع شحنتك من الرابط: {{3}}',
        language: 'ar',
        buttons: ['تتبع الشحنة'],
      ),
      WaTemplate(
        id: 't2',
        name: 'follow_up_24h',
        displayName: 'متابعة بعد 24 ساعة',
        category: WaTemplateCategory.utility,
        status: WaTemplateStatus.approved,
        body: 'أهلًا {{1}}، نتابع معك بخصوص استفسارك السابق. هل تحتاج مساعدة إضافية؟',
        language: 'ar',
      ),
      WaTemplate(
        id: 't3',
        name: 'white_friday',
        displayName: 'عروض الجمعة البيضاء',
        category: WaTemplateCategory.marketing,
        status: WaTemplateStatus.pending,
        body: 'خصومات حتى 50٪ على تشكيلة الشتاء 🎉 العرض ساري حتى {{1}}.',
        language: 'ar',
        buttons: ['تسوّق الآن'],
      ),
      WaTemplate(
        id: 't4',
        name: 'otp_login',
        displayName: 'رمز الدخول',
        category: WaTemplateCategory.authentication,
        status: WaTemplateStatus.rejected,
        body: 'رمز التحقق الخاص بك هو {{1}}. لا تشاركه مع أحد.',
        language: 'ar',
      ),
    ];
  }

  @override
  Future<void> notifyAdmin() => _wait();

  final _blocked = [
    WaBlockedContact(id: 'b1', phone: '+966555123987', name: 'رقم مزعج', blockedAt: DateTime.now().subtract(const Duration(days: 4))),
    WaBlockedContact(id: 'b2', phone: '+966541112233', blockedAt: DateTime.now().subtract(const Duration(days: 19))),
  ];

  @override
  Future<List<WaBlockedContact>> blocked() async {
    await _wait();
    return List.of(_blocked);
  }

  @override
  Future<void> unblock(String id) async {
    await _wait();
    _blocked.removeWhere((b) => b.id == id);
  }
}
