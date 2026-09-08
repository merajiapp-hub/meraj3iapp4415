import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/core/content_schema.dart';

void main() {
  group('content schema normalization', () {
    test('normalizes legacy book fields into the unified Firestore schema', () {
      final data = normalizeBookData(
        title: 'كتاب اختبار',
        subject: 'رياضيات',
        stage: 'الابتدائية',
        grade: 'السنة الأولى',
        category: 'كتب مدرسية',
        url: 'https://drive.google.com/file/d/abc123/view?usp=sharing',
        uploaderId: 'uid-1',
        isActive: true,
        isShared: false,
      );

      expect(data['title'], 'كتاب اختبار');
      expect(data['subject'], 'رياضيات');
      expect(data['section'], 'الابتدائية');
      expect(data['stage'], 'الابتدائية');
      expect(data['grade'], 'السنة الأولى');
      expect(data['year'], 'السنة الأولى');
      expect(data['category'], 'كتب مدرسية');
      expect(data['type'], 'كتب مدرسية');
      expect(data['bookType'], 'كتب مدرسية');
      expect(data['url'], contains('drive.google.com/file/d/abc123/view'));
      expect(data['drive_link'], contains('drive.google.com/file/d/abc123/view'));
      expect(data['pdfUrl'], contains('drive.google.com/file/d/abc123/view'));
      expect(data['uploaderId'], 'uid-1');
      expect(data['userId'], 'uid-1');
      expect(data['isActive'], isTrue);
      expect(data['is_active'], isTrue);
    });

    test('keeps legacy-compatible question fields when normalizing', () {
      final data = normalizeQuestionData(
        question: 'ما الناتج؟',
        subject: 'لغة عربية',
        stage: 'الثانوية',
        grade: 'السنة الأولى',
        options: ['أ', 'ب', 'ج', 'د'],
        correctAnswer: 'ب',
        isActive: true,
      );

      expect(data['question'], 'ما الناتج؟');
      expect(data['text'], 'ما الناتج؟');
      expect(data['subject'], 'لغة عربية');
      expect(data['section'], 'الثانوية');
      expect(data['stage'], 'الثانوية');
      expect(data['options'], isA<List>());
      expect(data['correctAnswer'], 'ب');
      expect(data['correctAnswers'], ['ب']);
      expect(data['isActive'], isTrue);
    });
  });
}
