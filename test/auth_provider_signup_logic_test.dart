import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/providers/auth_provider.dart';
import 'package:meraj3i/providers/statistics_provider.dart';

void main() {
  group('AuthProvider signup identity checks', () {
    test('validates Mauritanian numbers and normalizes valid formats', () {
      expect(AuthProvider.isValidMauritanianPhone('26123456'), isTrue);
      expect(AuthProvider.isValidMauritanianPhone('36123456'), isTrue);
      expect(AuthProvider.isValidMauritanianPhone('46123456'), isTrue);
      expect(AuthProvider.isValidMauritanianPhone('66123456'), isFalse);
      expect(AuthProvider.isValidMauritanianPhone('061234567'), isFalse);
      expect(AuthProvider.isValidMauritanianPhone('16123456'), isFalse);
      expect(AuthProvider.isValidMauritanianPhone('6612345'), isFalse);
      expect(AuthProvider.isValidMauritanianPhone('661234567'), isFalse);
      expect(AuthProvider.isValidMauritanianPhone('+3312345678'), isFalse);
      expect(AuthProvider.normalizePhoneValue('26123456'), '+22226123456');
      expect(
        AuthProvider.normalizePhoneValue('+222 26 123 456'),
        '+22226123456',
      );
      expect(
        AuthProvider.normalizePhoneValue('00 222 26123456'),
        '+22226123456',
      );
      expect(AuthProvider.formatPhoneForDisplay('+22226123456'), '26123456');
      expect(AuthProvider.formatPhoneForDisplay('+222026123456'), '26123456');
      expect(AuthProvider.formatPhoneForDisplay('026123456'), '26123456');
    });

    test('generated phone email is stable for the same phone', () {
      final first = AuthProvider.canonicalRegistrationEmail('', '26123456');
      final second = AuthProvider.canonicalRegistrationEmail(
        '',
        '+22226123456',
      );
      final third = AuthProvider.canonicalRegistrationEmail(
        '  ',
        '00 222 26123456',
      );

      expect(first, 'phone.22226123456@auth.meraj3i.invalid');
      expect(second, first);
      expect(third, first);
    });

    test('trusted admin access is limited to explicit admin emails', () {
      expect(AuthProvider.isTrustedAdminEmail('mma831770@gmail.com'), isTrue);
      expect(
        AuthProvider.isTrustedAdminEmail('abdellahismd@gmail.com'),
        isTrue,
      );
      expect(AuthProvider.isTrustedAdminEmail('guest@example.com'), isFalse);
      expect(AuthProvider.isTrustedAdminEmail('admin@meraj3i.com'), isFalse);
      expect(
        AuthProvider.hasAdminAccess(
          'mma831770@gmail.com',
          emailVerified: false,
        ),
        isFalse,
      );
      expect(
        AuthProvider.hasAdminAccess('mma831770@gmail.com', emailVerified: true),
        isTrue,
      );
    });
  });

  group('leaderboard scoring', () {
    test('combines quiz, completed book, and task points', () {
      expect(
        StatisticsProvider.calculateLeaderboardPoints(
          correctAnswers: 4,
          completedBooks: 2,
          completedTasks: 3,
        ),
        155,
      );
    });

    test('preserves higher stored points for existing accounts', () {
      expect(
        StatisticsProvider.calculateLeaderboardPoints(
          correctAnswers: 1,
          completedBooks: 0,
          completedTasks: 0,
          storedPoints: 35,
          legacyPoints: 25,
        ),
        35,
      );
    });
  });
}
