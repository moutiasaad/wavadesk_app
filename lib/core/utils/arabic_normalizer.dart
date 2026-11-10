/// Search folding shared by Assign (spec 07 §5.2) and Search (spec 08 §4.1):
/// أ/إ/آ/ٱ→ا، ة→ه، ى→ي، tashkeel + tatweel removed, Arabic-Indic and
/// Persian digits → Latin, Latin lower-cased.
abstract final class ArabicNormalizer {
  static bool _dropped(int r) => (r >= 0x064B && r <= 0x0652) || r == 0x0670 || r == 0x0640;

  static int _fold(int r) {
    if (r >= 0x0660 && r <= 0x0669) return 0x30 + (r - 0x0660); // ٠-٩
    if (r >= 0x06F0 && r <= 0x06F9) return 0x30 + (r - 0x06F0); // ۰-۹
    return switch (r) {
      0x0623 || 0x0625 || 0x0622 || 0x0671 => 0x0627,
      0x0629 => 0x0647,
      0x0649 => 0x064A,
      _ => r,
    };
  }

  static String normalize(String input) {
    final out = StringBuffer();
    for (final r in input.toLowerCase().runes) {
      if (_dropped(r)) continue;
      out.writeCharCode(_fold(r));
    }
    return out.toString().trim();
  }

  static bool matches(String haystack, String normalizedQuery) =>
      normalizedQuery.isEmpty || normalize(haystack).contains(normalizedQuery);

  /// Every [start, end) range in [text] whose folded form equals
  /// [normalizedQuery] — for highlighting on the original string.
  static List<(int, int)> matchRanges(String text, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return const [];
    final map = <int>[]; // folded code-unit index → original index
    final folded = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final u = text.codeUnitAt(i);
      if (_dropped(u)) continue;
      final f = String.fromCharCode(_fold(u)).toLowerCase();
      folded.write(f);
      for (var k = 0; k < f.length; k++) {
        map.add(i);
      }
    }
    final s = folded.toString();
    final out = <(int, int)>[];
    var from = 0;
    while (true) {
      final at = s.indexOf(normalizedQuery, from);
      if (at < 0) break;
      final endIdx = at + normalizedQuery.length - 1;
      if (endIdx >= map.length) break;
      out.add((map[at], map[endIdx] + 1));
      from = at + normalizedQuery.length;
    }
    return out;
  }

  static (int, int)? matchRange(String text, String normalizedQuery) {
    final r = matchRanges(text, normalizedQuery);
    return r.isEmpty ? null : r.first;
  }
}
