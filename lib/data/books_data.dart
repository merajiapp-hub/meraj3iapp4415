import '../models/book.dart';
import 'primary_books.dart';
import 'middle_books.dart';
import 'high_school_books.dart';
import 'competitions_books.dart';
import 'swedd_books.dart';

class BooksData {
  static const String sPrimary = 'المرحلة الابتدائية';
  static const String sMiddle = 'المرحلة الإعدادية';
  static const String sHighSc = 'المرحلة الثانوية - الشعب العلمية';
  static const String sHighMath = 'المرحلة الثانوية - شعبة الرياضيات';
  static const String sHighLit = 'المرحلة الثانوية - شعبة الآداب العصرية';
  static const String sHighOrig = 'المرحلة الثانوية - شعبة الآداب الأصلية';
  static const String sCompetitions =
      'الامتحانات الوطنية (Concours / Brevet / BAC)';
  static const String sSwedd = 'SWEDD';

  static final List<Book> allBooks = [
    ...PrimaryBooks.books,
    ...MiddleBooks.books,
    ...HighSchoolBooks.books,
    ...CompetitionsBooks.books,
    ...SweddBooks.books,
  ];
}
