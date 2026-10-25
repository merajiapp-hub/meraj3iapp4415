import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/books_data.dart';
import '../services/drive_url_service.dart';

class StatisticsProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _booksSubscription;

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

  StatisticsProvider() {
    staticBooksCount = 0;
    booksByStage = {
      'الابتدائية': 0,
      'الإعدادية': 0,
      'الثانوية': 0,
      'الوطنية': 0,
      'SWEDD': 0,
    };
    loadLocalStats();
    _initRealtimeBooks();
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    super.dispose();
  }

  /// الاستماع في الوقت الفعلي للكتب المتاحة حالياً والمضافة مستقبلاً
  void _initRealtimeBooks() {
    _booksSubscription?.cancel();
    _booksSubscription = _firestore
        .collection('books')
        .snapshots()
        .listen(
          (snapshot) {
            _processBooksSnapshot(snapshot.docs);
          },
          onError: (e) {
            debugPrint('Error listening to books in StatisticsProvider: $e');
          },
        );
  }

  static String _canonicalBookKey({
    required String title,
    required String url,
    required String section,
    required String grade,
    String? id,
  }) {
    final fileId = DriveUrlService.extractFileId(url);
    if (fileId != null && fileId.isNotEmpty) {
      return 'file_$fileId';
    }
    final cleanTitle = title.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final cleanSection = section.trim().toLowerCase();
    final cleanGrade = grade.trim().toLowerCase();
    if (cleanTitle.isNotEmpty) {
      return 't_${cleanSection}_${cleanGrade}_$cleanTitle';
    }
    return 'id_${id ?? url}';
  }

  void _processBooksSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final uniqueMap = <String, Map<String, dynamic>>{};
    for (final doc in docs) {
      final data = doc.data();
      final isActive = data['isActive'] != false;
      if (!isActive) continue;

      final title = (data['title'] ?? data['name'] ?? '').toString().trim();
      final url = (data['url'] ?? data['drive_link'] ?? data['pdfUrl'] ?? '')
          .toString()
          .trim();
      final section = (data['section'] ?? data['stage'] ?? '')
          .toString()
          .trim();
      final grade = (data['grade'] ?? data['year'] ?? '').toString().trim();

      final identity = _canonicalBookKey(
        title: title,
        url: url,
        section: section,
        grade: grade,
        id: doc.id,
      );

      uniqueMap[identity] = {
        'section': section,
        'grade': grade,
        'title': title,
        'uploaderId': data['uploaderId'] ?? data['userId'],
      };
    }

    uploadedBooksCount = uniqueMap.length;
    totalBooks = uniqueMap.length;

    // إعادة احتساب توزيع الكتب حسب المراحل لتشمل الكتب الحالية والمضافة مستقبلاً
    final newBooksByStage = {
      'الابتدائية': 0,
      'الإعدادية': 0,
      'الثانوية': 0,
      'الوطنية': 0,
      'SWEDD': 0,
    };

    for (final entry in uniqueMap.values) {
      final s = entry['section']?.toString() ?? '';
      if (s == BooksData.sPrimary || s.contains('ابتدائي')) {
        newBooksByStage['الابتدائية'] =
            (newBooksByStage['الابتدائية'] ?? 0) + 1;
      } else if (s == BooksData.sMiddle ||
          s.contains('إعدادي') ||
          s.contains('اعدادي')) {
        newBooksByStage['الإعدادية'] = (newBooksByStage['الإعدادية'] ?? 0) + 1;
      } else if (s.contains('ثانوي') || s == BooksData.sSecondary) {
        newBooksByStage['الثانوية'] = (newBooksByStage['الثانوية'] ?? 0) + 1;
      } else if (s == BooksData.sCompetitions ||
          s.contains('مسابق') ||
          s.contains('وطني')) {
        newBooksByStage['الوطنية'] = (newBooksByStage['الوطنية'] ?? 0) + 1;
      } else if (s == BooksData.sSwedd || s.toUpperCase().contains('SWEDD')) {
        newBooksByStage['SWEDD'] = (newBooksByStage['SWEDD'] ?? 0) + 1;
      }
    }

    booksByStage = newBooksByStage;

    final user = _auth.currentUser;
    if (user != null) {
      userAddedBooks = uniqueMap.values
          .where((item) => item['uploaderId'] == user.uid)
          .length;
    }

    notifyListeners();
  }

  // ─── جلب الإحصائيات الحقيقية والمصححة من Firebase ──────────────
  Future<void> fetchUserStats() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
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
        userReadBooks = (statsData['readBooks'] ?? 0) as int;
        totalReadingSeconds = (statsData['readingSeconds'] ?? 0) as int;
        userCompletedTasks = (statsData['completedTasks'] ?? 0) as int;
        userCorrectAnswers = (statsData['correctAnswers'] ?? 0) as int;
        userWrongAnswers = (statsData['wrongAnswers'] ?? 0) as int;
        userFavoriteBooks = (statsData['favoriteBooks'] ?? 0) as int;
        userDownloadedBooks = (statsData['downloadedBooks'] ?? 0) as int;
        userStreakDays = (statsData['streakDays'] ?? 0) as int;
        userCompletedBooks =
            (statsData['completedBooks'] ?? userReadBooks) as int;
        userTestsTaken =
            (statsData['completedTests'] ?? statsData['quizzesTaken'] ?? 0)
                as int;
      } else if (userDoc.exists) {
        userReadBooks = (userData['booksRead'] ?? 0) as int;
        userCorrectAnswers = (userData['correctAnswers'] ?? 0) as int;
        userWrongAnswers = (userData['wrongAnswers'] ?? 0) as int;
        userCompletedTasks = (userData['completedTasks'] ?? 0) as int;
        userStreakDays = (userData['streakDays'] ?? 0) as int;
        userCompletedBooks = userReadBooks;
        userTestsTaken = (userData['quizzesTaken'] ?? 0) as int;
      }

      // مطابقة واسترجاع محاولات الاختبارات للتأكد من دقة عدد الاختبارات والإجابات
      try {
        final attemptsSnap = await _firestore
            .collection('exam_attempts')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'completed')
            .get();

        if (attemptsSnap.docs.isNotEmpty) {
          final attemptsCount = attemptsSnap.docs.length;
          int sumCorrect = 0;
          int sumWrong = 0;
          for (final doc in attemptsSnap.docs) {
            final d = doc.data();
            sumCorrect += (d['correctAnswers'] as num?)?.toInt() ?? 0;
            sumWrong += (d['wrongAnswers'] as num?)?.toInt() ?? 0;
          }
          if (attemptsCount > userTestsTaken) {
            userTestsTaken = attemptsCount;
          }
          if (sumCorrect > userCorrectAnswers) {
            userCorrectAnswers = sumCorrect;
          }
          if (sumWrong > userWrongAnswers) {
            userWrongAnswers = sumWrong;
          }
        }
      } catch (e) {
        debugPrint('Error reconciling exam attempts: $e');
      }

      // مطابقة جلسات القراءة المكتملة للتأكد من دقة عدد الكتب المقروءة وساعات القراءة
      try {
        final readingSnap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reading_sessions')
            .get();

        int completedFromSessions = 0;
        int totalSecondsFromSessions = 0;
        for (final doc in readingSnap.docs) {
          final data = doc.data();
          final session = data['session'];
          if (session is Map<String, dynamic>) {
            if (session['status'] == 'completed') {
              completedFromSessions++;
            }
            totalSecondsFromSessions +=
                (session['readingTimeSeconds'] as num?)?.toInt() ?? 0;
          }
        }
        if (completedFromSessions > userCompletedBooks) {
          userCompletedBooks = completedFromSessions;
        }
        if (completedFromSessions > userReadBooks) {
          userReadBooks = completedFromSessions;
        }
        if (totalSecondsFromSessions > totalReadingSeconds) {
          totalReadingSeconds = totalSecondsFromSessions;
        }
      } catch (e) {
        debugPrint('Error reconciling reading sessions: $e');
      }

      // حساب المعدل ونسبة الدقة بدقة
      final total = userCorrectAnswers + userWrongAnswers;
      if (total > 0) {
        userAvgScore = (userCorrectAnswers / total) * 100;
      } else {
        userAvgScore = 0.0;
      }

      notifyListeners();
      await saveLocalStats();
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
    }
  }

  /// تسجيل نتيجة اختبار مكتمل وحفظها في إحصائيات المستخدم ولوحة الشرف فوراً
  Future<void> recordExamResult({
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    userTestsTaken += 1;
    userCorrectAnswers += correctAnswers;
    userWrongAnswers += wrongAnswers;

    final total = userCorrectAnswers + userWrongAnswers;
    if (total > 0) {
      userAvgScore = (userCorrectAnswers / total) * 100;
    } else {
      userAvgScore = 0.0;
    }

    notifyListeners();
    await saveLocalStats();

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final statsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('stats');

      await statsRef.set({
        'completedTests': FieldValue.increment(1),
        'correctAnswers': FieldValue.increment(correctAnswers),
        'wrongAnswers': FieldValue.increment(wrongAnswers),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording exam result: $e');
    }
  }

  /// مزامنة إحصائيات القراءة بدقة
  void syncReadingStats({
    required int completedBooks,
    required int readBooks,
    required int readingSeconds,
  }) {
    bool changed = false;
    if (completedBooks > userCompletedBooks) {
      userCompletedBooks = completedBooks;
      changed = true;
    }
    if (readBooks > userReadBooks) {
      userReadBooks = readBooks;
      changed = true;
    }
    if (readingSeconds > totalReadingSeconds) {
      totalReadingSeconds = readingSeconds;
      changed = true;
    }
    if (changed) {
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
              'completedBooks': userCompletedBooks,
              'readBooks': userReadBooks,
              'readingSeconds': totalReadingSeconds,
              'lastUpdated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    }
  }

  /// يُستدعى من الصفحات التي تحتاج إحصائيات محدثة
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
    userStreakDays = streakDays;
    totalReadingSeconds = readingSeconds;

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
      final allDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final s in snapshots) {
        allDocs.addAll(s.docs);
      }
      _processBooksSnapshot(allDocs);
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
    await prefs.setInt('stat_completedTests', userTestsTaken);
    await prefs.setInt('stat_streakDays', userStreakDays);
    await prefs.setInt('stat_readingSeconds', totalReadingSeconds);
  }

  Future<void> loadLocalStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userReadBooks = prefs.getInt('stat_readBooks') ?? userReadBooks;
      userCompletedBooks =
          prefs.getInt('stat_completedBooks') ?? userCompletedBooks;
      userDownloadedBooks =
          prefs.getInt('stat_downloadedBooks') ?? userDownloadedBooks;
      userFavoriteBooks =
          prefs.getInt('stat_favoriteBooks') ?? userFavoriteBooks;
      userCompletedTasks =
          prefs.getInt('stat_completedTasks') ?? userCompletedTasks;
      userCorrectAnswers =
          prefs.getInt('stat_correctAnswers') ?? userCorrectAnswers;
      userWrongAnswers = prefs.getInt('stat_wrongAnswers') ?? userWrongAnswers;
      userTestsTaken = prefs.getInt('stat_completedTests') ?? userTestsTaken;
      userStreakDays = prefs.getInt('stat_streakDays') ?? userStreakDays;
      totalReadingSeconds =
          prefs.getInt('stat_readingSeconds') ?? totalReadingSeconds;

      final total = userCorrectAnswers + userWrongAnswers;
      if (total > 0) {
        userAvgScore = (userCorrectAnswers / total) * 100;
      }
      notifyListeners();
    } catch (_) {}
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
      userDownloadedBooks > 0 ||
      userTestsTaken > 0;

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
      case 'completedTests':
      case 'quizzesTaken':
        userTestsTaken += value;
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
      await _updateUserStat(field, value);
    } catch (e) {
      debugPrint('Error syncing incremented user stat: $e');
    }
  }

  Future<void> decrementUserStat(String field, {int value = 1}) async {
    _updateLocalUserStat(field, -value); // تحديث فوري للواجهة

    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _updateUserStat(field, -value);
    } catch (e) {
      debugPrint('Error syncing decremented user stat: $e');
    }
  }

  Future<void> _updateUserStat(String field, int delta) async {
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
    await _firestore.runTransaction((transaction) async {
      final statsSnapshot = await transaction.get(statsRef);
      final current = asInt(statsSnapshot.data()?[field]);
      transaction.set(statsRef, {
        field: current + delta,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
