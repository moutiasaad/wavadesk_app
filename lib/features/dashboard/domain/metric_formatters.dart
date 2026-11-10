/// Number rules of Dashboard spec §7: Latin digits, `,` thousands, integer
/// percents, `m:ss` under an hour, true minus sign on deltas.
abstract final class MetricFormat {
  static const minus = '−';

  /// 1240 → "1,240"; ≥ 10,000 → "10.2k" / "10.2 ألف" ([thousandWord]).
  static String count(int n, {String thousandWord = 'k'}) {
    if (n.abs() >= 10000) {
      final k = n / 1000;
      final s = k.toStringAsFixed(k.abs() >= 100 ? 0 : 1).replaceFirst(RegExp(r'\.0$'), '');
      return thousandWord == 'k' ? '${s}k' : '$s $thousandWord';
    }
    return grouped(n);
  }

  static String grouped(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return n < 0 ? '$minus$b' : b.toString();
  }

  /// 0.64 → "64%".
  static String percent(double share) => '${(share * 100).round()}%';

  /// < 1 h → `m:ss`; ≥ 1 h → `{h} س {m} د` ([hourUnit] / [minuteUnit]).
  static String duration(int seconds, {String hourUnit = 'س', String minuteUnit = 'د'}) {
    final s = seconds < 0 ? 0 : seconds;
    if (s < 3600) return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return m == 0 ? '$h $hourUnit' : '$h $hourUnit $m $minuteUnit';
  }

  /// +3 / −2 / null when there is no delta (or it's zero → "0").
  static String? delta(int? d) {
    if (d == null) return null;
    if (d > 0) return '+${grouped(d)}';
    if (d < 0) return '$minus${grouped(-d)}';
    return '0';
  }

  /// Seconds delta as signed `m:ss` (first response).
  static String? durationDelta(int? d) {
    if (d == null || d == 0) return null;
    return '${d > 0 ? '+' : minus}${duration(d.abs())}';
  }

  /// Whole minutes, rounded up from seconds (oldest wait "أقدمها {m} د").
  static int minutes(int seconds) => (seconds / 60).ceil();
}
