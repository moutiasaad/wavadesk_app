import 'wa_channel.dart';

/// Connection status (WhatsApp spec §4.2) and the status → pill / alert
/// mapping (§4.2 table, §4.3 table).
enum WaStatus {
  connected('connected'),
  connecting('connecting'),
  syncing('syncing'),
  phoneOffline('phone_offline'),
  disconnected('disconnected'),
  restricted('restricted'),
  pending('pending');

  const WaStatus(this.wire);
  final String wire;

  /// Also accepts the gateway's raw states (`open`, `qr_pending`, `close`…).
  static WaStatus parse(Object? v) => switch ('$v') {
        'connected' || 'open' || 'online' => connected,
        'connecting' || 'qr_pending' => connecting,
        'syncing' => syncing,
        'phone_offline' => phoneOffline,
        'disconnected' || 'close' || 'closed' || 'logged_out' => disconnected,
        'restricted' || 'flagged' => restricted,
        _ => pending,
      };

  bool get isBusy => this == connecting || this == syncing;
  bool get isHealthy => this == connected || this == syncing;
}

/// Pill palette key (§4.2 "Status pill states").
enum WaPillTone { success, info, warning, error, neutral }

WaPillTone waPillTone(WaStatus s) => switch (s) {
      WaStatus.connected => WaPillTone.success,
      WaStatus.connecting || WaStatus.syncing => WaPillTone.info,
      WaStatus.phoneOffline => WaPillTone.warning,
      WaStatus.disconnected || WaStatus.restricted => WaPillTone.error,
      WaStatus.pending => WaPillTone.neutral,
    };

/// One alert card under the connection card (§4.3).
enum WaAlertKind { disconnected, phoneOffline, qualityLow, limitNear, appOutdated, pending }

/// Alerts in priority order (most urgent first). The screen shows them all;
/// most of the time there is zero or one.
List<WaAlertKind> waAlerts(WaChannel ch) {
  final out = <WaAlertKind>[];
  switch (ch.status) {
    case WaStatus.disconnected:
    case WaStatus.restricted:
      out.add(WaAlertKind.disconnected);
    case WaStatus.phoneOffline:
      out.add(WaAlertKind.phoneOffline);
    case WaStatus.pending:
      out.add(WaAlertKind.pending);
    case WaStatus.connected:
    case WaStatus.connecting:
    case WaStatus.syncing:
      break;
  }
  if (ch.isCloud && ch.quality.rating == WaQualityRating.low) out.add(WaAlertKind.qualityLow);
  if (ch.isCloud && ch.quality.dailyLimit > 0 && ch.quality.limitUsage >= 0.8) out.add(WaAlertKind.limitNear);
  if (!ch.isCloud && ch.appOutdated && !ch.isPending) out.add(WaAlertKind.appOutdated);
  return out;
}

/// "+966 50 123 4567" from E.164 (Saudi grouping; other countries 3-3-4).
String formatWaPhone(String? e164) {
  if (e164 == null || e164.isEmpty) return '';
  final d = e164.replaceAll(RegExp(r'[^\d]'), '');
  if (d.startsWith('966') && d.length == 12) {
    return '+966 ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8)}';
  }
  if (d.length > 10) {
    final cc = d.substring(0, d.length - 9);
    final r = d.substring(d.length - 9);
    return '+$cc ${r.substring(0, 2)} ${r.substring(2, 5)} ${r.substring(5)}';
  }
  return '+$d';
}
