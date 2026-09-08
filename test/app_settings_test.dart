import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/core/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('normalizes Firestore settings for maintenance and guest mode', () {
      final settings = AppSettings.fromFirestore({
        'isMaintenance': true,
        'message': 'رسالة الصيانة',
        'registrationOpen': false,
        'allowGuestView': true,
      });

      expect(settings.maintenanceMode, isTrue);
      expect(settings.maintenanceMessage, 'رسالة الصيانة');
      expect(settings.registrationOpen, isFalse);
      expect(settings.allowGuestView, isTrue);
    });

    test('falls back to defaults when Firestore data is empty', () {
      final settings = AppSettings.fromFirestore({});

      expect(settings.maintenanceMode, isFalse);
      expect(settings.maintenanceMessage,
          'نعمل الآن على إجراء بعض التحسينات الهامة.\nسيعود التطبيق للعمل بشكل طبيعي قريباً.');
      expect(settings.registrationOpen, isTrue);
      expect(settings.allowGuestView, isFalse);
    });
  });
}
