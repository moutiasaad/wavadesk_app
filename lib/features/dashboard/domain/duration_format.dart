/// First-reply tile format (Dashboard v2 §4.2): under 60 s → `45` + seconds;
/// under 60 min → `m:ss` + minutes; otherwise `h:mm` + hours.
enum DurationUnit { seconds, minutes, hours }

abstract final class DurationFormat {
  static (String value, DurationUnit unit) of(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    if (s < 60) return ('$s', DurationUnit.seconds);
    if (s < 3600) return ('${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}', DurationUnit.minutes);
    return ('${s ~/ 3600}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}', DurationUnit.hours);
  }
}
