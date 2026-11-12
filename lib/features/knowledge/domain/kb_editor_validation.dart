/// Entry editor rules — same limits as the web form / mobile API
/// (title required ≤ 200, content required ≤ 20000).
enum KbeFieldError { questionShort, answerShort, answerLong, datePast }

abstract final class KbEditorValidation {
  static const questionMin = 2;
  static const questionMax = 200;
  static const answerMin = 2;
  static const answerMax = 20000;

  /// "{n}/2000" appears from here on (§4.5).
  static const answerCounterFrom = 1600;
  static const maxPhrasings = 15;
  static const phrasingMax = 120;

  /// Suggest phrasings / duplicate check need this much question (§4.4, §4.7).
  static const aiMinQuestion = 10;

  static int _len(String s) => s.trim().runes.length;

  static KbeFieldError? question(String q) => _len(q) < questionMin ? KbeFieldError.questionShort : null;

  static KbeFieldError? answer(String a) {
    final n = _len(a);
    if (n < answerMin) return KbeFieldError.answerShort;
    if (n > answerMax) return KbeFieldError.answerLong;
    return null;
  }

  /// Expiry must be after today (date-only compare).
  static KbeFieldError? expiry(DateTime? d, DateTime now) {
    if (d == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day).isAfter(today) ? null : KbeFieldError.datePast;
  }

  static bool canSave({required String question, required String answer, DateTime? expiresAt, required DateTime now}) =>
      KbEditorValidation.question(question) == null &&
      KbEditorValidation.answer(answer) == null &&
      expiry(expiresAt, now) == null;

  /// Bucket for the `kbe_save` event — no text in analytics (§13).
  static String lengthBucket(String answer) {
    final n = _len(answer);
    if (n < 100) return '<100';
    if (n < 300) return '100-300';
    if (n < 800) return '300-800';
    return '800+';
  }
}
