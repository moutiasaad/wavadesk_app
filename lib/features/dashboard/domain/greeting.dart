/// Time-of-day greeting (Dashboard spec §4.1): morning 05:00–11:59,
/// evening 12:00–04:59, in the user's timezone.
enum GreetingPart { morning, evening }

abstract final class Greeting {
  static GreetingPart partOf(DateTime local) => local.hour >= 5 && local.hour < 12 ? GreetingPart.morning : GreetingPart.evening;

  /// `user.gender` → feminine labels (متاحة / مشغولة). Unknown → masculine.
  static bool isFeminine(String? gender) => const {'f', 'female', 'woman', 'أنثى'}.contains(gender?.trim().toLowerCase());

  /// First word of the full name.
  static String firstName(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }
}
