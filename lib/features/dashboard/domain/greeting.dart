/// Time-of-day greeting (Dashboard v2 §4.1.1), local time:
/// 04:00–11:59 morning, 12:00–17:59 afternoon, otherwise evening.
enum GreetingPart { morning, afternoon, evening }

abstract final class Greeting {
  static GreetingPart partOf(DateTime local) {
    final h = local.hour;
    if (h >= 4 && h < 12) return GreetingPart.morning;
    if (h >= 12 && h < 18) return GreetingPart.afternoon;
    return GreetingPart.evening;
  }

  /// `user.gender` → feminine labels (متاحة / مشغولة). Unknown → masculine.
  static bool isFeminine(String? gender) => const {'f', 'female', 'woman', 'أنثى'}.contains(gender?.trim().toLowerCase());

  /// First word of the full name.
  static String firstName(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }
}
