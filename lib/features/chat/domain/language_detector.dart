/// Local source-language heuristic for the AI Rewrite sheet (Rewrite spec
/// §5.4.1): Arabic-script letters above 40% of all letters → Arabic.
abstract final class LanguageDetector {
  static const arabicThreshold = 0.4;

  /// Arabic, Arabic Supplement, Arabic Extended-A, presentation forms A/B.
  static bool _isArabic(int r) =>
      (r >= 0x0600 && r <= 0x06FF) ||
      (r >= 0x0750 && r <= 0x077F) ||
      (r >= 0x08A0 && r <= 0x08FF) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF);

  /// Basic + extended Latin letters.
  static bool _isLatin(int r) => (r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A) || (r >= 0xC0 && r <= 0x024F);

  /// Share of Arabic letters among all letters (0 when there are none).
  static double arabicRatio(String text) {
    var arabic = 0;
    var letters = 0;
    for (final r in text.runes) {
      if (_isArabic(r)) {
        arabic++;
        letters++;
      } else if (_isLatin(r)) {
        letters++;
      }
    }
    return letters == 0 ? 0 : arabic / letters;
  }

  /// "ar" or "en". Text with no letters at all counts as Arabic (the
  /// product default).
  static String detect(String text) {
    final hasLetters = text.runes.any((r) => _isArabic(r) || _isLatin(r));
    if (!hasLetters) return 'ar';
    return arabicRatio(text) > arabicThreshold ? 'ar' : 'en';
  }

  static bool isArabic(String text) => detect(text) == 'ar';
}
