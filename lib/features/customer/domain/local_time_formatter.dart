/// Contact local time (Profile spec §5.1, §5.6). Uses a small table of
/// fixed UTC offsets for common IANA zones (no tz database in the app;
/// daylight saving is ignored). Unknown zones → null (line hidden).
abstract final class LocalTimeFormatter {
  static const _offsets = <String, Duration>{
    'Asia/Riyadh': Duration(hours: 3),
    'Asia/Kuwait': Duration(hours: 3),
    'Asia/Qatar': Duration(hours: 3),
    'Asia/Bahrain': Duration(hours: 3),
    'Asia/Baghdad': Duration(hours: 3),
    'Asia/Amman': Duration(hours: 3),
    'Asia/Dubai': Duration(hours: 4),
    'Asia/Muscat': Duration(hours: 4),
    'Asia/Karachi': Duration(hours: 5),
    'Asia/Kolkata': Duration(hours: 5, minutes: 30),
    'Africa/Cairo': Duration(hours: 2),
    'Africa/Casablanca': Duration(hours: 1),
    'Africa/Algiers': Duration(hours: 1),
    'Africa/Tunis': Duration(hours: 1),
    'Europe/Istanbul': Duration(hours: 3),
    'Europe/London': Duration.zero,
    'Europe/Paris': Duration(hours: 1),
    'Europe/Berlin': Duration(hours: 1),
    'America/New_York': Duration(hours: -5),
    'America/Chicago': Duration(hours: -6),
    'America/Los_Angeles': Duration(hours: -8),
    'UTC': Duration.zero,
  };

  static Duration? offsetOf(String? timezone) => timezone == null ? null : _offsets[timezone];

  /// Wall-clock time in [timezone], or null when unknown.
  static DateTime? localTime(String? timezone, {DateTime? now}) {
    final off = offsetOf(timezone);
    if (off == null) return null;
    final utc = (now ?? DateTime.now()).toUtc();
    final t = utc.add(off);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute);
  }

  /// Show "{time} بتوقيته" only when the contact's zone differs from the
  /// agent's device zone.
  static bool differsFromDevice(String? timezone, {DateTime? now}) {
    final off = offsetOf(timezone);
    if (off == null) return false;
    return off != (now ?? DateTime.now()).timeZoneOffset;
  }
}
