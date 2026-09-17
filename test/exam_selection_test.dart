import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/data/exam_selection_utils.dart';

void main() {
  group('ExamSelectionUtils', () {
    test('collects subjects and chapters without mixing data across subjects', () {
      final docs = [
        {'subject': 'الرياضيات', 'chapter': 'الدرس الأول'},
        {'subject': 'الرياضيات', 'chapter': 'الدرس الثاني'},
        {'subject': 'اللغة العربية', 'chapter': 'النصوص'},
        {'subject': 'اللغة العربية', 'chapter': ''},
        {'subject': '', 'chapter': 'محتوى غير مصنف'},
      ];

      expect(ExamSelectionUtils.subjectsFromDocs(docs), ['الرياضيات', 'اللغة العربية']);
      expect(ExamSelectionUtils.chaptersForSubject(docs, 'الرياضيات'), ['الدرس الأول', 'الدرس الثاني']);
      expect(ExamSelectionUtils.chaptersForSubject(docs, 'اللغة العربية'), ['النصوص']);
    });
  });
}
