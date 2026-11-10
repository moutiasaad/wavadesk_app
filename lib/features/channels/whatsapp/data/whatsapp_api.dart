import 'dart:async';

import '../../../../core/api/wd_api.dart';
import '../domain/wa_channel.dart';

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
