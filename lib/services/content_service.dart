import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../data/books_data.dart';

/// الخدمة المركزية لجلب المحتوى من Firestore
/// تدعم الجلب بحسب المرحلة والتصنيف مع fallback للبيانات المحلية
class ContentService {
  static final _db = FirebaseFirestore.instance;

  // ── ثوابت أسماء المجموعات في Firestore ─────────────────────────
  static const String _booksCol = 'books';
  static const String _examsCol = 'national_exams';
  static const String _sweddCol = 'swedd_content';
  static const String _refsCol = 'references';

  static String _normalizeComparable(String? value) =>
      (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool _matchesSection(Book book, String section) {
    final normalizedSection = _normalizeComparable(section);
    if (normalizedSection.isEmpty) return true;
    final sectionValues = [
      book.section,
      book.grade,
      book.category,
      book.subject,
    ].map(_normalizeComparable);

    return sectionValues.any((value) => value == normalizedSection) ||
        _normalizeComparable(book.section) == normalizedSection;
  }

  static bool _matchesCategory(Book book, String? category) {
    if (category == null || category.trim().isEmpty) return true;
    final normalizedCategory = _normalizeComparable(category);
    return _normalizeComparable(book.category) == normalizedCategory ||
        _normalizeComparable(book.subject) == normalizedCategory;
  }

  static int _compareBooksByOrder(Book a, Book b) {
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) return orderCompare;
    return _normalizeComparable(
      a.title,
    ).compareTo(_normalizeComparable(b.title));
  }

  // ── الحصول على كتب المراحل الدراسية من Firestore ────────────────
  static Stream<List<Book>> watchBooksBySection(
    String section, {
    String? category,
  }) {
    return _db.collection(_booksCol).snapshots().map((snapshot) {
      final books = snapshot.docs
          .map((d) => Book.fromMap(d.data(), d.id))
          .where((book) => book.isActive)
          .where((book) => _matchesSection(book, section))
          .where((book) => _matchesCategory(book, category))
          .toList();

      books.sort(_compareBooksByOrder);
      return books;
    });
  }

  /// جلب الكتب مرة واحدة (للعرض السريع)
  static Future<List<Book>> fetchBooksBySection(
    String section, {
    String? category,
  }) async {
    try {
      final snap = await _db.collection(_booksCol).get();
      final firestoreBooks = snap.docs
          .map((d) => Book.fromMap(d.data(), d.id))
          .where((book) => book.isActive)
          .where((book) => _matchesSection(book, section))
          .where((book) => _matchesCategory(book, category))
          .toList();

      firestoreBooks.sort(_compareBooksByOrder);
      if (firestoreBooks.isNotEmpty) return firestoreBooks;

      // fallback للبيانات المحلية إذا لم تكن Firestore مُهيأة بعد
      return _localFallback(section, category);
    } catch (e) {
      // عند أي خطأ، استخدم البيانات المحلية
      return _localFallback(section, category);
    }
  }

  static List<Book> _localFallback(String section, String? category) {
    final books = BooksData.allBooks.where((b) {
      if (b.section != section) return false;
      if (category != null && category.isNotEmpty) {
        if (category == 'الدروس' || category == 'التمارين') {
          return b.category.contains('التمارين') ||
              b.category.contains('الدروس');
        }
        return b.category.contains(category);
      }
      return true;
    }).toList();
    return books;
  }

  // ── الامتحانات الوطنية من Firestore ─────────────────────────────
  static Stream<List<Map<String, dynamic>>> watchNationalExams({
    String? competitionType,
    String? branch,
    String? subject,
    int? year,
  }) {
    Query query = _db
        .collection(_examsCol)
        .where('isActive', isEqualTo: true)
        .orderBy('year', descending: true)
        .orderBy('order');

    if (competitionType != null) {
      query = query.where('competitionType', isEqualTo: competitionType);
    }
    if (branch != null) {
      query = query.where('branch', isEqualTo: branch);
    }
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject);
    }
    if (year != null) {
      query = query.where('year', isEqualTo: year);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList(),
    );
  }

  // ── محتوى SWEDD من Firestore ─────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> watchSweddContent({
    String? category,
  }) {
    Query query = _db
        .collection(_sweddCol)
        .where('isActive', isEqualTo: true)
        .orderBy('order');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList(),
    );
  }

  // ── المراجع الأخرى من Firestore ──────────────────────────────────
  static Stream<List<Map<String, dynamic>>> watchReferences({
    String? category,
  }) {
    Query query = _db
        .collection(_refsCol)
        .where('isActive', isEqualTo: true)
        .orderBy('order');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'id': d.id})
          .toList(),
    );
  }

  // ── إحصاءات عامة ─────────────────────────────────────────────────
  static Future<int> countBooks() async {
    try {
      final snap = await _db
          .collection(_booksCol)
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return snap.count ?? 0;
    } catch (_) {
      return BooksData.allBooks.where((b) => b.isActive).length;
    }
  }
}
