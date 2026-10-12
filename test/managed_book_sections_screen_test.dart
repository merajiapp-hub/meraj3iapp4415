import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/models/book.dart';
import 'package:meraj3i/screens/managed_book_sections_screen.dart';

Book _book({
  required String id,
  required String section,
  required String grade,
  required String category,
  String title = 'كتاب',
  String url = 'https://example.com/book.pdf',
  bool isActive = true,
}) {
  return Book(
    id: id,
    title: title,
    section: section,
    grade: grade,
    category: category,
    url: url,
    isActive: isActive,
  );
}

void main() {
  group('managed book section filtering', () {
    final national = _book(
      id: 'national-1',
      section: 'الامتحانات الوطنية',
      grade: 'Concours 2025',
      category: 'الامتحانات',
    );
    final swedd = _book(
      id: 'swedd-1',
      section: 'SWEDD',
      grade: 'الثالثة إعدادية',
      category: 'الكتب المدرسية',
    );

    test('keeps page data isolated by its exact section', () {
      expect(
        filterManagedBooks(
          books: [national, swedd],
          section: 'الامتحانات الوطنية',
        ).map((book) => book.id),
        ['national-1'],
      );
      expect(
        filterManagedBooks(
          books: [national, swedd],
          section: 'SWEDD',
        ).map((book) => book.id),
        ['swedd-1'],
      );
    });

    test('hides inactive books and uses the updated Firestore URL', () {
      final disabled = _book(
        id: 'disabled',
        section: national.section,
        grade: national.grade,
        category: national.category,
        isActive: false,
      );
      final updated = _book(
        id: 'updated',
        section: national.section,
        grade: national.grade,
        category: national.category,
        url: 'https://example.com/new-book.pdf',
      );

      final books = filterManagedBooks(
        books: [disabled, updated],
        section: national.section,
      );

      expect(books.map((book) => book.id), ['updated']);
      expect(books.single.url, 'https://example.com/new-book.pdf');
    });

    test(
      'groups each distinct grade/category once and filters exact category',
      () {
        final second = _book(
          id: 'national-2',
          section: national.section,
          grade: national.grade,
          category: national.category,
          title: 'كتاب ثان',
        );
        final duplicate = _book(
          id: 'national-duplicate-copy',
          section: national.section,
          grade: national.grade,
          category: national.category,
        );
        final otherCategory = _book(
          id: 'national-3',
          section: national.section,
          grade: national.grade,
          category: 'الحلول',
        );

        final filtered = filterManagedBooks(
          books: [national, duplicate, second, otherCategory],
          section: national.section,
          grade: national.grade,
          category: national.category,
        );
        final groups = groupManagedBooks(filtered);

        expect(groups, hasLength(1));
        expect(groups.single.grade, national.grade);
        expect(groups.single.category, national.category);
        expect(
          groups.single.books.values.map((book) => book.title),
          containsAll(['كتاب', 'كتاب ثان']),
        );
        expect(groups.single.books, hasLength(2));
      },
    );
  });
}
