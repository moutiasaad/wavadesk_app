/// Quick-reply shortcut rules (WhatsApp spec §5.4): `/` prefix, then
/// a–z 0–9 _ -, unique in its scope.
enum ShortcutError { empty, invalid, tooLong, taken }

abstract final class ShortcutValidator {
  static const maxLength = 30;
  static final _allowed = RegExp(r'^[a-z0-9_-]+$');

  /// Strips the `/` (the wire value has none; the UI shows `/x`) and folds
  /// to lower case.
  static String normalize(String input) => input.trim().replaceFirst(RegExp(r'^/+'), '').toLowerCase();

  /// [existing] = other shortcuts in the same scope (normalized or not).
  static ShortcutError? validate(String input, {Iterable<String> existing = const []}) {
    final s = normalize(input);
    if (s.isEmpty) return ShortcutError.empty;
    if (s.length > maxLength) return ShortcutError.tooLong;
    if (!_allowed.hasMatch(s)) return ShortcutError.invalid;
    if (existing.any((e) => normalize(e) == s)) return ShortcutError.taken;
    return null;
  }
}
