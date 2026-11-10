import '../../../l10n/app_localizations.dart';
import '../../../core/utils/span_format.dart';

enum WaitingLevel { underSla, overSla }

/// Waiting tag content (Claim spec §4.2.2).
class WaitingInfo {
  const WaitingInfo({required this.label, required this.a11yLabel, required this.level, required this.refresh});

  /// Compact: "45 ث" / "9 د" / "1 س 12 د".
  final String label;

  /// Full words for screen readers: "ينتظر منذ 9 دقائق".
  final String a11yLabel;
  final WaitingLevel level;

  /// 10s while under 2 minutes (seconds are shown), then 60s.
  final Duration refresh;
}

abstract final class WaitingDurationFormatter {
  /// [since] = first unanswered inbound; null → tag hidden.
  static WaitingInfo? format(DateTime? since, DateTime now, AppLocalizations l, {int slaSeconds = 300}) {
    if (since == null) return null;
    final d = now.difference(since);
    final secs = d.inSeconds < 0 ? 0 : d.inSeconds;
    final level = secs >= slaSeconds ? WaitingLevel.overSla : WaitingLevel.underSla;
    final String label;
    if (secs < 60) {
      label = l.claim_wait_sec(secs);
    } else if (secs < 3600) {
      label = l.claim_wait_min(secs ~/ 60);
    } else if (secs < 86400) {
      label = l.claim_wait_hm(secs ~/ 3600, (secs % 3600) ~/ 60);
    } else {
      label = SpanFormat.compact(secs, l);
    }
    final String a11y = secs < 60
        ? l.claim_a11y_wait_sec(secs)
        : secs < 3600
        ? l.claim_a11y_wait_min(secs ~/ 60)
        : secs < 86400
        ? l.claim_a11y_wait_hm(secs ~/ 3600, (secs % 3600) ~/ 60)
        : l.claim_a11y_wait_span(SpanFormat.compact(secs, l));
    return WaitingInfo(
      label: label,
      a11yLabel: a11y,
      level: level,
      refresh: secs < 120 ? const Duration(seconds: 10) : const Duration(minutes: 1),
    );
  }
}
