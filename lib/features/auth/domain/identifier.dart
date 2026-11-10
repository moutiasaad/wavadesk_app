/// Login identifier: an email or a phone number (Login spec §4.5, §6).
library;

enum IdentifierType { email, phone }

/// Validation failures, mapped to localized messages in the UI.
enum IdentifierError { required, invalidEmail, invalidPhone }

class Identifier {
  const Identifier._(this.type, this.value);

  final IdentifierType type;

  /// Normalized value sent to the API (trimmed email, or E.164 phone).
  final String value;

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _e164 = RegExp(r'^\+[1-9]\d{8,14}$');
  static final _phoneNoise = RegExp(r'[\s\-().]');

  /// Arabic-Indic (U+0660–0669) and Eastern Arabic-Indic (U+06F0–06F9)
  /// digits → Latin, before any validation (§6).
  static String latinDigits(String input) {
    final out = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        out.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        out.writeCharCode(0x30 + rune - 0x06F0);
      } else {
        out.writeCharCode(rune);
      }
    }
    return out.toString();
  }

  /// Phone normalization (§4.5): `00…` → `+…`, Saudi local `05XXXXXXXX` →
  /// `+9665XXXXXXXX`, bare international digits get a leading `+`.
  static String normalizePhone(String input) {
    var p = latinDigits(input).replaceAll(_phoneNoise, '');
    if (p.startsWith('00')) {
      p = '+${p.substring(2)}';
    } else if (RegExp(r'^05\d{8}$').hasMatch(p)) {
      p = '+966${p.substring(1)}';
    } else if (!p.startsWith('+') && RegExp(r'^[1-9]\d+$').hasMatch(p)) {
      p = '+$p';
    }
    return p;
  }

  /// Parses raw field input. Returns the identifier or the first error.
  static ({Identifier? identifier, IdentifierError? error}) parse(String raw) {
    final input = latinDigits(raw).trim();
    if (input.isEmpty) return (identifier: null, error: IdentifierError.required);
    if (input.contains('@')) {
      return _email.hasMatch(input)
          ? (identifier: Identifier._(IdentifierType.email, input), error: null)
          : (identifier: null, error: IdentifierError.invalidEmail);
    }
    final phone = normalizePhone(input);
    return _e164.hasMatch(phone)
        ? (identifier: Identifier._(IdentifierType.phone, phone), error: null)
        : (identifier: null, error: IdentifierError.invalidPhone);
  }
}

enum PasswordError { required, tooShort }

PasswordError? validatePassword(String password) {
  if (password.isEmpty) return PasswordError.required;
  if (password.length < 8) return PasswordError.tooShort;
  return null;
}
