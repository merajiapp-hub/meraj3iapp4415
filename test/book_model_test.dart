import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/models/book.dart';
import 'package:meraj3i/services/book_order_service.dart';

void main() {
  test('reads numeric and string order values from Firestore data', () {
    final numeric = Book.fromMap({
      'title': 'كتاب 1',
      'section': 'SWEDD',
      'grade': 'الثالثة',
      'category': 'الكتب المدرسية',
      'url': 'https://example.com/book-1.pdf',
      'order': 4,
    }, 'book-1');

    final stringOrder = Book.fromMap({
      'title': 'كتاب 2',
      'section': 'SWEDD',
      'grade': 'الثالثة',
      'category': 'الكتب المدرسية',
      'url': 'https://example.com/book-2.pdf',
      'order': '2',
    }, 'book-2');

    expect(numeric.order, 4);
    expect(stringOrder.order, 2);
  });

  test('preserves updated order through copyWith', () {
    final book = Book.fromMap({
      'title': 'كتاب',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2025',
      'category': 'الامتحانات',
      'url': 'https://example.com/book.pdf',
      'order': 2,
    }, 'book-1');

    expect(book.copyWith(order: 9).order, 9);
  });

  test('copyWith keeps category ids and resolves the copied document URL', () {
    final book = Book.fromMap({
      'title': 'امتحان وطني',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2025',
      'category': 'الامتحانات',
      'categoryId': 'national-exams',
      'categoryIds': ['national-exams', '2025'],
      'url': 'https://drive.google.com/file/d/EXAM123/view',
      'solutionUrl': 'https://drive.google.com/file/d/SOLUTION456/view',
      'extractedFileId': 'EXAM123',
      'order': 1,
    }, 'book-exam');

    final solutionBook = book.copyWith(
      title: 'حل امتحان وطني',
      url: book.solutionUrl,
      originalDriveUrl: book.solutionUrl,
      extractedFileId: '',
    );

    expect(solutionBook.categoryIds, ['national-exams', '2025']);
    expect(solutionBook.resolvedFileId, 'SOLUTION456');
    expect(solutionBook.uniqueKey, isNot(book.uniqueKey));
  });

  test('reads solution urls from alternative Firestore field names', () {
    final solutionUnderscore = Book.fromMap({
      'title': 'كتاب 1',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2025',
      'category': 'الامتحانات',
      'url': 'https://example.com/book-1.pdf',
      'solution_url': 'https://example.com/solution-1.pdf',
      'order': 1,
    }, 'book-solution-1');

    final answerUrl = Book.fromMap({
      'title': 'كتاب 2',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2025',
      'category': 'الامتحانات',
      'url': 'https://example.com/book-2.pdf',
      'answerUrl': 'https://example.com/answer-2.pdf',
      'order': 2,
    }, 'book-solution-2');

    expect(
      solutionUnderscore.solutionUrl,
      'https://example.com/solution-1.pdf',
    );
    expect(answerUrl.solutionUrl, 'https://example.com/answer-2.pdf');
  });

  test('reads and preserves exam document classification and pairing key', () {
    final solution = Book.fromMap({
      'title': 'حل الامتحان',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2025',
      'category': 'الامتحانات',
      'url': 'https://example.com/solution.pdf',
      'document_type': 'solution',
      'exam_key': 'concours 2025::mathématiques',
    }, 'solution-1');

    final copied = solution.copyWith(url: 'https://example.com/updated.pdf');

    expect(copied.documentType, 'solution');
    expect(copied.examKey, 'concours 2025::mathématiques');
    expect(copied.toMap()['documentType'], 'solution');
    expect(copied.toMap()['examKey'], 'concours 2025::mathématiques');
  });

  test('infers legacy national exam and solution record types', () {
    final exam = Book.fromMap({
      'title': 'Concours 2024 Mathématiques',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2024',
      'category': 'الامتحانات',
      'url': 'https://example.com/exam.pdf',
    }, 'legacy-exam');
    final solution = Book.fromMap({
      'title': 'Concours 2024 Mathématiques',
      'section': 'الامتحانات الوطنية',
      'grade': 'Concours 2024',
      'category': 'الحلول',
      'url': 'https://example.com/solution.pdf',
    }, 'legacy-solution');

    expect(exam.documentType, 'exam');
    expect(solution.documentType, 'solution');
  });

  test(
    'auto assigns next order and reindexes books when inserted in middle',
    () {
      final existingBooks = [
        Book.fromMap({
          'title': 'الكتاب الأول',
          'section': 'المرحلة الإعدادية',
          'grade': 'الثانية',
          'category': 'الكتب المدرسية',
          'url': 'https://example.com/1.pdf',
          'order': 1,
        }, 'book-1'),
        Book.fromMap({
          'title': 'الكتاب الثاني',
          'section': 'المرحلة الإعدادية',
          'grade': 'الثانية',
          'category': 'الكتب المدرسية',
          'url': 'https://example.com/2.pdf',
          'order': 2,
        }, 'book-2'),
        Book.fromMap({
          'title': 'الكتاب الثالث',
          'section': 'المرحلة الإعدادية',
          'grade': 'الثانية',
          'category': 'الكتب المدرسية',
          'url': 'https://example.com/3.pdf',
          'order': 3,
        }, 'book-3'),
      ];

      final nextOrder = BookOrderService.nextOrderForBooks(existingBooks);
      expect(nextOrder, 4);

      final inserted = BookOrderService.insertBookAtOrder(
        existingBooks,
        Book.fromMap({
          'title': 'كتاب الفيزياء الجديد',
          'section': 'المرحلة الإعدادية',
          'grade': 'الثانية',
          'category': 'الكتب المدرسية',
          'url': 'https://example.com/new.pdf',
          'order': 2,
        }, 'book-new'),
        requestedOrder: 2,
      );

      expect(inserted.map((book) => book.title).toList(), [
        'الكتاب الأول',
        'كتاب الفيزياء الجديد',
        'الكتاب الثاني',
        'الكتاب الثالث',
      ]);
      expect(inserted.map((book) => book.order).toList(), [1, 2, 3, 4]);
    },
  );
}
