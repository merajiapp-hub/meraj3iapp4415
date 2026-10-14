import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/data/books_data.dart';
import 'package:meraj3i/data/competitions_books.dart';
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
  String subject = '',
  String documentType = 'book',
  String examKey = '',
}) {
  return Book(
    id: id,
    title: title,
    section: section,
    grade: grade,
    category: category,
    subject: subject,
    url: url,
    isActive: isActive,
    documentType: documentType,
    examKey: examKey,
  );
}

void main() {
  group('national competition ordering', () {
    test('orders Concours before Brevet before Bac', () {
      expect(competitionGroupSortOrder('Concours 2025'), 0);
      expect(competitionGroupSortOrder('Brevet 2025'), 1);
      expect(competitionGroupSortOrder('ابريفة 2025'), 1);
      expect(competitionGroupSortOrder('Bac 2025'), 2);
      expect(competitionGroupSortOrder('بكالوريا 2025'), 2);
      expect(competitionGroupSortOrder('السنة السابعة ثانوية'), 2);
      expect(competitionGroupSortOrder('السنة السابعة ثانوية (الباكالوريا)'), 2);
      expect(competitionSubjectSortOrder('اللغة العربية'), 0);
      expect(competitionSubjectSortOrder('اللغة الفرنسية'), 1);
      expect(competitionSubjectSortOrder('الرياضيات'), 2);
      expect(competitionYearSort('Concours 2005'), 2005);
      expect(competitionYearSort('Brevet 2023'), 2023);
    });

    test('fills missing Firestore solution URLs from bundled exam data', () {
      final bundled = CompetitionsBooks.books.firstWhere(
        (book) => book.solutionUrl.isNotEmpty,
      );
      final firestoreBook = Book(
        id: 'firestore-${bundled.id}',
        title: bundled.title,
        section: BooksData.sCompetitions,
        grade: bundled.grade,
        category: bundled.category,
        subject: bundled.subject,
        url: 'https://example.com/exam.pdf',
      );

      final enriched = attachBundledCompetitionSolutions([firestoreBook]);

      expect(enriched.single.id, firestoreBook.id);
      expect(enriched.single.url, firestoreBook.url);
      expect(enriched.single.solutionUrl, bundled.solutionUrl);
    });

    test(
      'keeps existing Firestore solution URLs and does not enrich other pages',
      () {
        final bundled = CompetitionsBooks.books.firstWhere(
          (book) => book.solutionUrl.isNotEmpty,
        );
        final existingSolution = _book(
          id: 'existing-solution',
          section: BooksData.sCompetitions,
          grade: bundled.grade,
          category: bundled.category,
        ).copyWith(solutionUrl: 'https://example.com/firestore-solution.pdf');
        final swedd = _book(
          id: 'swedd-no-solution',
          section: BooksData.sSwedd,
          grade: bundled.grade,
          category: bundled.category,
        );

        final enriched = attachBundledCompetitionSolutions([
          existingSolution,
          swedd,
        ]);

        expect(enriched[0].solutionUrl, existingSolution.solutionUrl);
        expect(enriched[1].solutionUrl, isEmpty);
      },
    );

    test('joins a separately classified solution to its exam and hides it', () {
      const examKey = 'concours 2077::mathematiques';
      final exam = _book(
        id: 'exam-2077',
        section: BooksData.sCompetitions,
        grade: 'Concours 2077',
        category: 'الامتحانات',
        subject: 'Mathématiques',
        documentType: 'exam',
        examKey: examKey,
      );
      final solution = _book(
        id: 'solution-2077',
        section: BooksData.sCompetitions,
        grade: exam.grade,
        category: exam.category,
        subject: exam.subject,
        documentType: 'solution',
        examKey: examKey,
        url: 'https://example.com/solution.pdf',
      );

      final attached = attachBundledCompetitionSolutions([exam, solution]);

      expect(attached, hasLength(1));
      expect(attached.single.id, exam.id);
      expect(attached.single.solutionUrl, solution.url);
      expect(
        filterManagedBooks(
          books: [exam, solution],
          section: BooksData.sCompetitions,
        ).map((book) => book.id),
        [exam.id],
      );
    });

    test('does not fall back to bundled solution after admin disables it', () {
      final bundled = CompetitionsBooks.books.firstWhere(
        (book) => book.solutionUrl.isNotEmpty,
      );
      final examKey =
          '${bundled.grade.trim().toLowerCase()}::${bundled.subject.trim().toLowerCase()}';
      final exam = _book(
        id: 'managed-${bundled.id}',
        section: BooksData.sCompetitions,
        grade: bundled.grade,
        category: bundled.category,
        subject: bundled.subject,
        documentType: 'exam',
        examKey: examKey,
      );
      final disabledSolution = _book(
        id: 'disabled-${bundled.id}',
        section: BooksData.sCompetitions,
        grade: bundled.grade,
        category: bundled.category,
        subject: bundled.subject,
        documentType: 'solution',
        examKey: examKey,
        isActive: false,
        url: 'https://example.com/disabled-solution.pdf',
      );

      final attached = attachBundledCompetitionSolutions([
        exam,
        disabledSolution,
      ]);

      expect(attached.single.solutionUrl, isEmpty);
    });
  });

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
