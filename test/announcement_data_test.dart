import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/models/announcement_data.dart';

void main() {
  group('AnnouncementData', () {
    test('treats legacy announcements without an active flag as published', () {
      expect(AnnouncementData.isActive({'title': 'Legacy'}), isTrue);
    });

    test('respects the active flag when explicitly disabled', () {
      expect(AnnouncementData.isActive({'isActive': false}), isFalse);
      expect(AnnouncementData.isActive({'is_active': false}), isFalse);
    });

    test('reads legacy message content when body is absent', () {
      expect(
        AnnouncementData.body({'message': 'Legacy announcement'}),
        'Legacy announcement',
      );
    });

    test('prefers non-empty body over the legacy message field', () {
      expect(
        AnnouncementData.body({
          'body': 'Current body',
          'message': 'Legacy message',
        }),
        'Current body',
      );
    });
  });
}
