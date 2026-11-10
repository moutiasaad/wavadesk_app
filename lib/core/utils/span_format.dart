import '../../l10n/app_localizations.dart';

/// Human time spans — never a raw minute total ("1440 د"):
/// `9 د` · `3 س 20 د` · `2 ي 4 س` (zero parts dropped).
abstract final class SpanFormat {
  static String compact(int seconds, AppLocalizations l) {
    final s = seconds < 0 ? 0 : seconds;
    final d = s ~/ 86400;
    final h = (s % 86400) ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (d > 0) return h == 0 ? '$d ${l.time_unit_day}' : '$d ${l.time_unit_day} $h ${l.time_unit_hour}';
    if (h > 0) return m == 0 ? '$h ${l.time_unit_hour}' : '$h ${l.time_unit_hour} $m ${l.time_unit_min}';
    return '${m < 1 ? 1 : m} ${l.time_unit_min}';
  }

  static String minutes(int minutes, AppLocalizations l) => compact(minutes * 60, l);
}
