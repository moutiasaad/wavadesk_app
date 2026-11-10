import '../../../core/utils/arabic_normalizer.dart';

/// Alternative-phrasing dedupe (Add Answer spec §4.4): Arabic folding
/// (أ/إ/آ→ا، ة→ه، ى→ي، tashkeel) plus punctuation and spacing.
abstract final class PhrasingNormalizer {
  static final _noise = RegExp(r'[؟?!.,،؛;:«»"()\-\s]+');

  /// The comparison key: folded, punctuation-free, single-spaced.
  static String key(String input) => ArabicNormalizer.normalize(input).replaceAll(_noise, ' ').trim();

  /// True when [candidate] equals the question or one of [existing].
  static bool isDuplicate(String candidate, Iterable<String> existing, {String? question}) {
    final k = key(candidate);
    if (k.isEmpty) return false;
    if (question != null && key(question) == k) return true;
    return existing.any((e) => key(e) == k);
  }

  /// Inline add field: Enter, "،" or "," commit; several at once when pasted.
  static List<String> split(String raw) =>
      [for (final p in raw.split(RegExp(r'[،,\n]'))) if (p.trim().isNotEmpty) p.trim()];

  /// [items] without folded duplicates, first occurrence wins.
  static List<String> dedupe(Iterable<String> items, {String? question}) {
    final seen = <String>{if (question != null) key(question)};
    return [
      for (final s in items)
        if (key(s).isNotEmpty && seen.add(key(s))) s.trim(),
    ];
  }
}
