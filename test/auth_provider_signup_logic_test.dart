import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/providers/auth_provider.dart';

void main() {
  group('AuthProvider signup identity checks', () {
    test('normalizes phone values consistently across repeated attempts', () {
      expect(AuthProvider.normalizePhoneValue('0661234567'), '+222661234567');
      expect(AuthProvider.normalizePhoneValue('+222 661 234 567'), '+222661234567');
      expect(AuthProvider.normalizePhoneValue('00 222 661234567'), '+222661234567');
    });

    test('generated phone email is stable for the same phone', () {
      final first = AuthProvider.canonicalRegistrationEmail('', '0661234567');
      final second = AuthProvider.canonicalRegistrationEmail('', '+222661234567');
      final third = AuthProvider.canonicalRegistrationEmail('  ', '00 222 661234567');

      expect(first, 'phone.222661234567@auth.meraj3i.invalid');
      expect(second, first);
      expect(third, first);
    });
  });
}
