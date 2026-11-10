import 'package:intl/intl.dart' as intl;

import '../../../l10n/app_localizations.dart';

/// Inbox timestamps (Inbox spec §4.5.1). Digits are always Latin (0-9) in
/// both locales — product decision, consistent with phone numbers.
abstract final class RelativeTimeFormatter {
  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  /// `h:mm ص/م` (ar) or `h:mm AM/PM` (en), Latin digits.
  static String clock12(DateTime t, AppLocalizations l) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? l.inbox_am : l.inbox_pm}';
  }

  /// `d MMM` (+ year when not the current year), Latin day/year digits.
  static String dayMonth(DateTime t, DateTime now, String locale) {
    final month = intl.DateFormat.MMMM(locale).format(t);
    return t.year == now.year ? '${t.day} $month' : '${t.day} $month ${t.year}';
  }

  static String format(DateTime t, DateTime now, AppLocalizations l, String locale) {
    final age = now.difference(t);
    if (age.inSeconds < 60) return l.inbox_now;
    if (age.inMinutes < 60) return l.inbox_min(age.inMinutes);
    if (_sameDay(t, now)) {
      return age.inHours < 6 ? l.inbox_hour(age.inHours) : clock12(t, l);
    }
    if (_sameDay(t, now.subtract(const Duration(days: 1)))) return l.inbox_yesterday;
    if (age.inDays < 7) return intl.DateFormat.EEEE(locale).format(t);
    return dayMonth(t, now, locale);
  }

  /// "مؤجلة حتى {t}": time today, otherwise weekday + time this week, else date.
  static String until(DateTime t, DateTime now, AppLocalizations l, String locale) {
    if (_sameDay(t, now)) return clock12(t, l);
    if (t.difference(now).inDays < 7) return '${intl.DateFormat.EEEE(locale).format(t)} ${clock12(t, l)}';
    return dayMonth(t, now, locale);
  }
}
