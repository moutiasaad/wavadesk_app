import '../../../core/utils/arabic_normalizer.dart';
import 'search_query.dart';

/// Phone / email / order / mention detection and phone folding (Search spec
/// §4.1, §6.6).
abstract final class SearchIntentDetector {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _order = RegExp(r'^#\d*$|^(طلب|order)\s*#?\d+$', caseSensitive: false);

  static SearchIntent detect(String raw) {
    final q = ArabicNormalizer.normalize(raw);
    if (q.isEmpty) return SearchIntent.text;
    if (_email.hasMatch(q)) return SearchIntent.email;
    if (q.startsWith('@')) return SearchIntent.mention;
    if (_order.hasMatch(q)) return SearchIntent.order;
    final digits = phoneDigits(q);
    final onlyPhoneChars = RegExp(r'^\+?[\d\s\-().]+$').hasMatch(q);
    if (onlyPhoneChars && digits.length >= 7) return SearchIntent.phone;
    return SearchIntent.text;
  }

  /// Digits only (Arabic-Indic already folded by the normalizer).
  static String phoneDigits(String s) => ArabicNormalizer.normalize(s).replaceAll(RegExp(r'\D'), '');

  /// Saudi-style variants so `05XXXXXXXX` ⇄ `+9665XXXXXXXX` both match: the
  /// national significant number without the trunk 0 / country code.
  static String phoneCore(String s) {
    var d = phoneDigits(s);
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('966')) d = d.substring(3);
    if (d.startsWith('0')) d = d.substring(1);
    return d;
  }

  static bool phoneMatches(String candidate, String query) {
    final q = phoneCore(query);
    if (q.length < 3) return false;
    return phoneCore(candidate).contains(q);
  }

  /// §4.1: 2 chars minimum, 1 when it is a digit (or a lone "#").
  static bool longEnough(String raw) {
    final q = raw.trim();
    if (q.length >= 2) return true;
    return q.length == 1 && RegExp(r'[\d٠-٩#]').hasMatch(q);
  }

  /// The order number inside "#2841" / "طلب 2841", if any.
  static String? orderNumber(String raw) => RegExp(r'\d+').firstMatch(ArabicNormalizer.normalize(raw))?.group(0);
}
