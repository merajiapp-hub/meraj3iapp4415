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
  int userReadBooks = 0; // من ReadingProvider
  int userCompletedBooks = 0; // من ReadingProvider
  int userDownloadedBooks = 0; // من DownloadsProvider
  int userFavoriteBooks = 0; // من FavoritesProvider
  int userCompletedTasks = 0; // من TaskProvider
  int userTestsTaken = 0; // من QuizProvider (XP يعكس عدد الإجابات الصحيحة)
  int userCorrectAnswers = 0; // من QuizProvider
  int userWrongAnswers = 0; // من QuizProvider
  int userAddedBooks = 0; // من Firestore
  int userStreakDays = 0; // من QuizProvider
  int totalReadingSeconds = 0; // من ReadingProvider

  // تحديثات يدوية (Firestore)
  double userAvgScore = 0.0;

  bool isLoading = false;
  String? _leaderboardSyncedUid;

  static int calculateLeaderboardPoints({
    required int correctAnswers,
    required int completedBooks,
    required int completedTasks,
    int storedPoints = 0,
    int legacyPoints = 0,
  }) {
    final calculatedPoints =
        correctAnswers * 10 + completedBooks * 50 + completedTasks * 5;
    return [
      calculatedPoints,
      storedPoints,
      legacyPoints,
    ].reduce((left, right) => left > right ? left : right);
  }

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

  // ─── جلب الإحصائيات الحقيقية من Firebase ──────────────
  Future<void> fetchUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      // نجلب من كلا المصدرين في آنٍ واحد لأفضل أداء
      final results = await Future.wait([
        _firestore
            .collection('users')
            .doc(user.uid)
            .collection('data')
            .doc('stats')
            .get(),
        _firestore.collection('users').doc(user.uid).get(),
      ]);

      final statsDoc = results[0];
      final userDoc = results[1];
      final statsData = statsDoc.data() ?? <String, dynamic>{};
      final userData = userDoc.data() ?? <String, dynamic>{};

      if (statsDoc.exists) {
        userReadBooks = statsData['readBooks'] ?? 0;
        totalReadingSeconds = statsData['readingSeconds'] ?? 0;
        userCompletedTasks = statsData['completedTasks'] ?? 0;
        userCorrectAnswers = statsData['correctAnswers'] ?? 0;
        userWrongAnswers = statsData['wrongAnswers'] ?? 0;
        userFavoriteBooks = statsData['favoriteBooks'] ?? 0;
        userDownloadedBooks = statsData['downloadedBooks'] ?? 0;
        userStreakDays = statsData['streakDays'] ?? 0;
        userCompletedBooks = statsData['completedBooks'] ?? 0;
      } else if (userDoc.exists) {
        // استخدام بيانات الوثيقة الرئيسية كاحتياطي
        userReadBooks = (userData['booksRead'] ?? 0) as int;
        userCorrectAnswers = (userData['correctAnswers'] ?? 0) as int;
        userWrongAnswers = (userData['wrongAnswers'] ?? 0) as int;
        userCompletedTasks = (userData['completedTasks'] ?? 0) as int;
        userStreakDays = (userData['streakDays'] ?? 0) as int;
        userCompletedBooks = userReadBooks;
      }

      // حساب متوسط الدرجات
      final total = userCorrectAnswers + userWrongAnswers;
      if (total > 0) {
        userAvgScore = (userCorrectAnswers / total) * 100;
        userTestsTaken = total;
      } else {
        userAvgScore = 0.0;
        userTestsTaken = 0;
      }

      if (_leaderboardSyncedUid != user.uid) {
        try {
          await _syncLeaderboard(statsData: statsData, userData: userData);
          _leaderboardSyncedUid = user.uid;
        } catch (e) {
          debugPrint('Error syncing leaderboard after stats fetch: $e');
        }
      }

      notifyListeners();
      saveLocalStats();
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
    }
  }

  /// يُستدعى من الصفحات التي تحتاج إحصائيات محدثة
  /// يجب تمرير البيانات من الـ Providers الأخرى مباشرة (طريقة احتياطية)
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
    saveLocalStats();

    final user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('stats')
          .set({
            'readBooks': userReadBooks,
            'completedBooks': userCompletedBooks,
            'downloadedBooks': userDownloadedBooks,
            'favoriteBooks': userFavoriteBooks,
            'completedTasks': userCompletedTasks,
            'correctAnswers': userCorrectAnswers,
            'wrongAnswers': userWrongAnswers,
            'streakDays': userStreakDays,
            'readingSeconds': totalReadingSeconds,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .then(
            (_) => _syncLeaderboard(
              statsData: {
                'readBooks': userReadBooks,
                'completedBooks': userCompletedBooks,
                'downloadedBooks': userDownloadedBooks,
                'favoriteBooks': userFavoriteBooks,
                'completedTasks': userCompletedTasks,
                'correctAnswers': userCorrectAnswers,
                'wrongAnswers': userWrongAnswers,
                'streakDays': userStreakDays,
                'readingSeconds': totalReadingSeconds,
              },
              userData: const {},
            ),
          )
          .catchError((e) {
            debugPrint('Error syncing stats to Firestore: $e');
          });
    }
  }

  Future<void> refreshGlobalStats() async {
    isLoading = true;
    notifyListeners();
    try {
      final snapshots = await Future.wait([
        _firestore.collection('books').get(),
        _firestore.collection('uploaded_books').get(),
      ]);
      final uniqueBooks =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final title = (data['title'] ?? data['name'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final url =
              (data['url'] ?? data['drive_link'] ?? data['pdfUrl'] ?? '')
                  .toString()
                  .trim();
          final identity = title.isNotEmpty
              ? '$title|$url|${data['section'] ?? data['stage']}|${data['grade'] ?? data['year']}'
              : doc.id;
          uniqueBooks.putIfAbsent(identity, () => doc);
        }
      }
      uploadedBooksCount = uniqueBooks.length;
      totalBooks = staticBooksCount + uploadedBooksCount;

      final user = _auth.currentUser;
      if (user != null) {
        userAddedBooks = uniqueBooks.values
            .where(
              (doc) =>
                  (doc.data()['uploaderId'] ?? doc.data()['userId']) ==
                  user.uid,
            )
            .length;
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

  void _updateLocalUserStat(String field, int value) {
    switch (field) {
      case 'readBooks':
        userReadBooks += value;
        break;
      case 'completedBooks':
        userCompletedBooks += value;
        break;
      case 'readingSeconds':
        totalReadingSeconds += value;
        break;
      case 'completedTasks':
        userCompletedTasks += value;
        break;
      case 'correctAnswers':
        userCorrectAnswers += value;
        break;
      case 'wrongAnswers':
        userWrongAnswers += value;
        break;
      case 'favoriteBooks':
        userFavoriteBooks += value;
        break;
      case 'downloadedBooks':
        userDownloadedBooks += value;
        break;
      case 'streakDays':
        userStreakDays += value;
        break;
    }

    final total = userCorrectAnswers + userWrongAnswers;
    if (total > 0) {
      userAvgScore = (userCorrectAnswers / total) * 100;
    } else {
      userAvgScore = 0.0;
    }

    notifyListeners();
  }

  Future<void> incrementUserStat(String field, {int value = 1}) async {
    _updateLocalUserStat(field, value); // تحديث فوري للواجهة

    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _syncLeaderboard(
        statsData: const {},
        userData: const {},
        changedField: field,
        delta: value,
      );
    } catch (e) {
      debugPrint('Error syncing incremented user stat: $e');
    }
  }

  Future<void> decrementUserStat(String field, {int value = 1}) async {
    _updateLocalUserStat(field, -value); // تحديث فوري للواجهة

    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _syncLeaderboard(
        statsData: const {},
        userData: const {},
        changedField: field,
        delta: -value,
      );
    } catch (e) {
      debugPrint('Error syncing decremented user stat: $e');
    }
  }

  Future<void> _syncLeaderboard({
    required Map<String, dynamic> statsData,
    required Map<String, dynamic> userData,
    String? changedField,
    int? delta,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    int asInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final statsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('data')
        .doc('stats');
    final userRef = _firestore.collection('users').doc(user.uid);
    final leaderboardRef = _firestore.collection('leaderboard').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final statsSnapshot = await transaction.get(statsRef);
      final userSnapshot = await transaction.get(userRef);
      final existing = await transaction.get(leaderboardRef);
      final currentStats = <String, dynamic>{
        ...statsData,
        ...?statsSnapshot.data(),
      };
      final currentUserData = <String, dynamic>{
        ...userData,
        ...?userSnapshot.data(),
      };
      if (changedField != null && delta != null) {
        currentStats[changedField] = asInt(currentStats[changedField]) + delta;
        transaction.set(statsRef, {
          changedField: currentStats[changedField],
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      final existingData = existing.data() ?? <String, dynamic>{};
      final currentName =
          (currentUserData['fullName'] ??
                  currentUserData['name'] ??
                  user.displayName ??
                  'طالب متميز')
              .toString()
              .trim();
      int stat(String key, {String? fallback}) {
        return asInt(
          currentStats[key] ??
              existingData[key] ??
              (fallback == null ? null : currentUserData[fallback]),
        );
      }

      final correctAnswers = stat('correctAnswers');
      final completedBooks = stat('completedBooks', fallback: 'booksRead');
      final completedTasks = stat('completedTasks');
      final completedTests = stat('completedTests', fallback: 'quizzesTaken');
      final totalAnswers = correctAnswers + stat('wrongAnswers');
      final avgScore = totalAnswers == 0
          ? 0.0
          : correctAnswers * 100 / totalAnswers;
      transaction.set(leaderboardRef, {
        'name': currentName.isEmpty ? 'طالب متميز' : currentName,
        'points': calculateLeaderboardPoints(
          correctAnswers: correctAnswers,
          completedBooks: completedBooks,
          completedTasks: completedTasks,
          storedPoints: stat('points'),
          legacyPoints: asInt(existingData['points']),
        ),
        'booksRead': stat('readBooks', fallback: 'booksRead'),
        'completedTasks': completedTasks,
        'quizzesTaken': completedTests,
        'progressLevel': currentStats['progressLevel'] is num
            ? (currentStats['progressLevel'] as num).toDouble()
            : 0.0,
        'avgScore': avgScore,
        'profileImageUrl':
            currentUserData['profileImageUrl'] ?? user.photoURL ?? '',
        'streakDays': stat('streakDays'),
        'lastActivity': FieldValue.serverTimestamp(),
        if (existingData['createdAt'] != null)
          'createdAt': existingData['createdAt'],
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
