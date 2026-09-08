import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/core/account_status.dart';

void main() {
  group('normalizeAccountStatus', () {
    test('marks account suspended when isSuspended is true', () {
      final result = normalizeAccountStatus({
        'isSuspended': true,
        'accountStatus': 'active',
      });

      expect(result.isSuspended, isTrue);
      expect(result.accountStatus, 'suspended');
    });

    test('returns active when suspension end date has expired', () {
      final result = normalizeAccountStatus({
        'isSuspended': true,
        'accountStatus': 'suspended',
        'suspensionEndAt': DateTime.utc(2020, 1, 1).toIso8601String(),
      }, now: DateTime.utc(2025, 1, 1));

      expect(result.isSuspended, isFalse);
      expect(result.accountStatus, 'active');
    });

    test('keeps reason text when provided', () {
      final result = normalizeAccountStatus({
        'isSuspended': true,
        'suspensionReason': 'مخالفات أمنية',
      });

      expect(result.reason, 'مخالفات أمنية');
    });
  });
}
