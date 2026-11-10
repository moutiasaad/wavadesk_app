import 'package:flutter_test/flutter_test.dart';
import 'package:wavadesk/features/auth/domain/identifier.dart';

void main() {
  group('Identifier.parse (Login spec §4.5, §6)', () {
    test('Saudi local 05… normalizes to +9665…', () {
      final r = Identifier.parse('0501234567');
      expect(r.error, isNull);
      expect(r.identifier!.type, IdentifierType.phone);
      expect(r.identifier!.value, '+966501234567');
    });

    test('Arabic-Indic digits are converted before validation', () {
      expect(Identifier.parse('٠٥٠١٢٣٤٥٦٧').identifier!.value, '+966501234567');
      expect(Identifier.parse('۰۵۰۱۲۳۴۵۶۷').identifier!.value, '+966501234567');
    });

    test('00 prefix becomes +', () {
      expect(Identifier.parse('00966501234567').identifier!.value, '+966501234567');
    });

    test('spaces and dashes in phones are ignored', () {
      expect(Identifier.parse('+966 50-123 4567').identifier!.value, '+966501234567');
    });

    test('emails are trimmed and validated with the spec regex', () {
      expect(Identifier.parse('  ahmed@lamsa.sa ').identifier!.value, 'ahmed@lamsa.sa');
      expect(Identifier.parse('ahmed@lamsa').error, IdentifierError.invalidEmail);
      expect(Identifier.parse('ahmed@lamsa.s').error, IdentifierError.invalidEmail);
    });

    test('required and invalid phone', () {
      expect(Identifier.parse('   ').error, IdentifierError.required);
      expect(Identifier.parse('12345').error, IdentifierError.invalidPhone);
      expect(Identifier.parse('+1234567890123456').error, IdentifierError.invalidPhone);
    });
  });

  test('password rules', () {
    expect(validatePassword(''), PasswordError.required);
    expect(validatePassword('1234567'), PasswordError.tooShort);
    expect(validatePassword('12345678'), isNull);
  });
}
