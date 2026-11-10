import 'ai_agent_config.dart';

enum HoursError { endBeforeStart, overlap, tooManyRanges }

/// Working-hours rules (AI Agent spec §5.1): end > start, ≤ 2 ranges per
/// day (split shift), no overlaps.
abstract final class HoursValidator {
  static const maxRanges = 2;
  static const step = 15;

  /// Per day key → first error, only for open days.
  static Map<String, HoursError> validate(WorkingHours h) {
    if (h.is24h) return const {};
    final out = <String, HoursError>{};
    for (final d in h.week) {
      if (!d.open) continue;
      final e = validateDay(d.ranges);
      if (e != null) out[d.day] = e;
    }
    return out;
  }

  static HoursError? validateDay(List<TimeRange> ranges) {
    if (ranges.length > maxRanges) return HoursError.tooManyRanges;
    for (final r in ranges) {
      if (r.end <= r.start) return HoursError.endBeforeStart;
    }
    final sorted = [...ranges]..sort((a, b) => a.start.compareTo(b.start));
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].start < sorted[i - 1].end) return HoursError.overlap;
    }
    return null;
  }

  /// "9 ص – 10 م" style summary input: earliest start / latest end of the
  /// open days, or null when none is open.
  static (int, int)? span(WorkingHours h) {
    int? s;
    int? e;
    for (final d in h.week) {
      if (!d.open) continue;
      for (final r in d.ranges) {
        s = s == null || r.start < s ? r.start : s;
        e = e == null || r.end > e ? r.end : e;
      }
    }
    return s == null ? null : (s, e!);
  }
}
