import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/services/note_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('plainTextFromQuill preserves paragraphs and full content', () {
    final deltaJson = jsonEncode([
      {'insert': 'أول سطر\n'},
      {'insert': 'سطر ثانٍ\n'},
      {'insert': 'سطر ثالث\n'},
      {'insert': 'آخر نص مهم'},
    ]);

    final result = NoteExportService.plainTextFromQuill(deltaJson);

    expect(result, 'أول سطر\nسطر ثانٍ\nسطر ثالث\nآخر نص مهم');
  });

  test('pdf export does not fail for full Arabic note content', () async {
    final bytes = await NoteExportService.pdfBytes(
      title: 'ملاحظة اختبار',
      content: jsonEncode([
        {'insert': 'محتوى أول\n'},
        {'insert': 'محتوى ثاني\n'},
        {'insert': 'محتوى ثالث'},
      ]),
    );

    expect(bytes, isNotEmpty);
  });
}
