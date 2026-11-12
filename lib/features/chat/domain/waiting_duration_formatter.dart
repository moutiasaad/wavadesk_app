import '../../../l10n/app_localizations.dart';

enum WaitingLevel { underSla, overSla }

/// Wait chip content (Claim v2 §4.3.1).
class WaitingInfo {
  const WaitingInfo({required this.label, required this.a11yLabel, required this.level, required this.refresh});

  /// Compact: "الآن" / "9 د" / "2 س".
  final String label;

  /// Full words for screen readers: "ينتظر منذ 9 دقائق".
  final String a11yLabel;
  final WaitingLevel level;

  /// When the label next changes (the minute boundary, then every minute).
  final Duration refresh;
}

abstract final class WaitingDurationFormatter {
  /// [since] = first unanswered customer message (`waiting_since`); null →
  /// chip hidden.
  static WaitingInfo? format(DateTime? since, DateTime now, AppLocalizations l, {int slaSeconds = 300}) {
    if (since == null) return null;
    final d = now.difference(since);
    final secs = d.inSeconds < 0 ? 0 : d.inSeconds;
    final level = secs >= slaSeconds ? WaitingLevel.overSla : WaitingLevel.underSla;
    final String label;
    final String a11y;
    if (secs < 60) {
      label = l.claim_wait_now;
      a11y = l.claim_a11y_wait_sec(secs);
    } else if (secs < 3600) {
      label = l.claim_wait_min(secs ~/ 60);
      a11y = l.claim_a11y_wait_min(secs ~/ 60);
    } else {
      label = l.claim_wait_hr(secs ~/ 3600);
      a11y = l.claim_a11y_wait_hm(secs ~/ 3600, (secs % 3600) ~/ 60);
    }
    return WaitingInfo(
      label: label,
      a11yLabel: a11y,
      level: level,
      refresh: Duration(seconds: 60 - secs % 60),
    );
  }
}
