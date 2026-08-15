import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/books_data.dart';

class StatisticsProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── إحصائيات الكتب العامة ──────────────────────────────
  int totalBooks = 0;
  int uploadedBooksCount = 0;
  int staticBooksCount = 0;
  Map<String, int> booksByStage = {};

  // ─── إحصائيات المستخدم الحقيقية ────────────────────────
  // يتم تحديثها من الـ Providers الأخرى عند استدعاء refreshFromProviders
  int userReadBooks = 0;       // من ReadingProvider
  int userCompletedBooks = 0;  // من ReadingProvider
  int userDownloadedBooks = 0; // من DownloadsProvider
  int userFavoriteBooks = 0;   // من FavoritesProvider
  int userCompletedTasks = 0;  // من TaskProvider
  int userTestsTaken = 0;      // من QuizProvider (XP يعكس عدد الإجابات الصحيحة)
  int userCorrectAnswers = 0;  // من QuizProvider
  int userWrongAnswers = 0;    // من QuizProvider
  int userAddedBooks = 0;      // من Firestore
  int userStreakDays = 0;      // من QuizProvider
  int totalReadingSeconds = 0; // من ReadingProvider

  // تحديثات يدوية (Firestore)
  double userAvgScore = 0.0;

  bool isLoading = false;

  StatisticsProvider() {
    _initStaticStats();
  }

  void _initStaticStats() {
    staticBooksCount = BooksData.allBooks.length;
    booksByStage = {
      'الابتدائية': 0,
      'الإعدادية': 0,
      'الثانوية': 0,
      'الوطنية': 0,
      'SWEDD': 0,
    };
    for (var book in BooksData.allBooks) {
      if (book.section == BooksData.sPrimary) {
        booksByStage['الابتدائية'] = (booksByStage['الابتدائية'] ?? 0) + 1;
      } else if (book.section == BooksData.sMiddle) {
        booksByStage['الإعدادية'] = (booksByStage['الإعدادية'] ?? 0) + 1;
      } else if (book.section.contains('الثانوية')) {
        booksByStage['الثانوية'] = (booksByStage['الثانوية'] ?? 0) + 1;
      } else if (book.section == BooksData.sCompetitions) {
        booksByStage['الوطنية'] = (booksByStage['الوطنية'] ?? 0) + 1;
      } else if (book.section == BooksData.sSwedd) {
        booksByStage['SWEDD'] = (booksByStage['SWEDD'] ?? 0) + 1;
      }
    }
    totalBooks = staticBooksCount;
  }

  /// يُستدعى من الصفحات التي تحتاج إحصائيات محدثة
  /// يجب تمرير البيانات من الـ Providers الأخرى مباشرة
  void refreshFromProviders({
    required int readBooks,
    required int completedBooks,
    required int downloadedBooks,
    required int favoriteBooks,
    required int completedTasks,
    required int correctAnswers,
    required int wrongAnswers,
    required int streakDays,
    required int readingSeconds,
  }) {
    userReadBooks = readBooks;
    userCompletedBooks = completedBooks;
    userDownloadedBooks = downloadedBooks;
    userFavoriteBooks = favoriteBooks;
    userCompletedTasks = completedTasks;
    userCorrectAnswers = correctAnswers;
    userWrongAnswers = wrongAnswers;
    userTestsTaken = correctAnswers + wrongAnswers > 0 ? 1 : 0;
    userStreakDays = streakDays;
    totalReadingSeconds = readingSeconds;

    // حساب متوسط الدرجات
    final total = correctAnswers + wrongAnswers;
    if (total > 0) {
      userAvgScore = (correctAnswers / total) * 100;
    } else {
      userAvgScore = 0.0;
    }

    notifyListeners();
  }

  Future<void> refreshGlobalStats() async {
    isLoading = true;
    notifyListeners();
    try {
      final aggregateQuery =
          await _firestore.collection('uploaded_books').count().get();
      uploadedBooksCount = aggregateQuery.count ?? 0;
      totalBooks = staticBooksCount + uploadedBooksCount;

      final user = _auth.currentUser;
      if (user != null) {
        final userUploadsQuery = await _firestore
            .collection('uploaded_books')
            .where('uploaderId', isEqualTo: user.uid)
            .count()
            .get();
        userAddedBooks = userUploadsQuery.count ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching global stats: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── حفظ إحصائيات في SharedPreferences للعمل أوفلاين ──
  Future<void> saveLocalStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stat_readBooks', userReadBooks);
    await prefs.setInt('stat_completedBooks', userCompletedBooks);
    await prefs.setInt('stat_downloadedBooks', userDownloadedBooks);
    await prefs.setInt('stat_favoriteBooks', userFavoriteBooks);
    await prefs.setInt('stat_completedTasks', userCompletedTasks);
    await prefs.setInt('stat_correctAnswers', userCorrectAnswers);
    await prefs.setInt('stat_wrongAnswers', userWrongAnswers);
    await prefs.setInt('stat_streakDays', userStreakDays);
    await prefs.setInt('stat_readingSeconds', totalReadingSeconds);
  }

  // ─── مساعدات للعرض ─────────────────────────────────────
  String get formattedReadingTime {
    if (totalReadingSeconds == 0) return '—';
    final hours = totalReadingSeconds ~/ 3600;
    final minutes = (totalReadingSeconds % 3600) ~/ 60;
    if (hours > 0) return '$hours س $minutes د';
    return '$minutes دقيقة';
  }

  double get accuracyRate {
    final total = userCorrectAnswers + userWrongAnswers;
    if (total == 0) return 0;
    return userCorrectAnswers / total;
  }

  bool get hasAnyData =>
      userReadBooks > 0 ||
      userCompletedTasks > 0 ||
      userCorrectAnswers > 0 ||
      userFavoriteBooks > 0 ||
      userDownloadedBooks > 0;

  // ─── مُحدِّث إحصائيات Firestore القديم (للتوافق) ──────
  Future<void> incrementBookStat(String uniqueKey, String field,
      {bool isUploaded = false, String? docId}) async {
    try {
      if (isUploaded && docId != null) {
        await _firestore.collection('uploaded_books').doc(docId).update({
          field: FieldValue.increment(1),
        });
      } else {
        await _firestore.collection('book_stats').doc(uniqueKey).set({
          field: FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error incrementing book stat: $e');
    }
  }

  Future<void> decrementBookStat(String uniqueKey, String field,
      {bool isUploaded = false, String? docId}) async {
    try {
      if (isUploaded && docId != null) {
        await _firestore.collection('uploaded_books').doc(docId).update({
          field: FieldValue.increment(-1),
        });
      } else {
        await _firestore.collection('book_stats').doc(uniqueKey).set({
          field: FieldValue.increment(-1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error decrementing book stat: $e');
    }
  }

  Future<void> incrementUserStat(String field, {int value = 1}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('stats')
          .set({
        field: FieldValue.increment(value),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error incrementing user stat: $e');
    }
  }

  Future<void> decrementUserStat(String field, {int value = 1}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('stats')
          .set({
        field: FieldValue.increment(-value),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error decrementing user stat: $e');
    }
  }
}
