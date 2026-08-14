import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/books_data.dart';

class StatisticsProvider extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Global Stats
  int totalBooks = 0;
  int uploadedBooksCount = 0;
  int staticBooksCount = 0;
  
  Map<String, int> booksByStage = {};
  
  // User Stats
  int userAddedBooks = 0;
  int userReadBooks = 0;
  int userDownloadedBooks = 0;
  int userFavoriteBooks = 0;
  int userCompletedTasks = 0;
  int userTestsTaken = 0;
  double userAvgScore = 0.0;

  bool isLoading = true;

  StatisticsProvider() {
    _initStaticStats();
    refreshStats();
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
  }

  Future<void> refreshStats() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Global Uploaded Books Count
      final aggregateQuery = await _firestore.collection('uploaded_books').count().get();
      uploadedBooksCount = aggregateQuery.count ?? 0;
      totalBooks = staticBooksCount + uploadedBooksCount;

      // 2. Fetch User Stats
      final user = _auth.currentUser;
      if (user != null) {
        final userStatsDoc = await _firestore.collection('users').doc(user.uid).collection('data').doc('stats').get();
        if (userStatsDoc.exists) {
          final data = userStatsDoc.data()!;
          userAddedBooks = data['addedBooks'] ?? 0;
          userReadBooks = data['readBooks'] ?? 0;
          userDownloadedBooks = data['downloadedBooks'] ?? 0;
          userFavoriteBooks = data['favoriteBooks'] ?? 0;
          userCompletedTasks = data['completedTasks'] ?? 0;
          userTestsTaken = data['testsTaken'] ?? 0;
          userAvgScore = (data['avgScore'] ?? 0.0).toDouble();
        } else {
          // Initialize if empty
          userAddedBooks = 0;
          userReadBooks = 0;
          userDownloadedBooks = 0;
          userFavoriteBooks = 0;
          userCompletedTasks = 0;
          userTestsTaken = 0;
          userAvgScore = 0.0;
        }

        // Double check uploaded books by this user precisely
        final userUploadsQuery = await _firestore
            .collection('uploaded_books')
            .where('uploaderId', isEqualTo: user.uid)
            .count()
            .get();
        userAddedBooks = userUploadsQuery.count ?? userAddedBooks;
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Track Global & User Stats Helpers ---
  Future<void> incrementBookStat(String uniqueKey, String field, {bool isUploaded = false, String? docId}) async {
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

  Future<void> decrementBookStat(String uniqueKey, String field, {bool isUploaded = false, String? docId}) async {
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
      await _firestore.collection('users').doc(user.uid).collection('data').doc('stats').set({
        field: FieldValue.increment(value),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update local value for UI immediately
      if (field == 'readBooks') userReadBooks += value;
      if (field == 'downloadedBooks') userDownloadedBooks += value;
      if (field == 'favoriteBooks') userFavoriteBooks += value;
      if (field == 'completedTasks') userCompletedTasks += value;
      if (field == 'addedBooks') userAddedBooks += value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error incrementing user stat: $e');
    }
  }

  Future<void> decrementUserStat(String field, {int value = 1}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).collection('data').doc('stats').set({
        field: FieldValue.increment(-value),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local value for UI immediately
      if (field == 'readBooks') userReadBooks -= value;
      if (field == 'downloadedBooks') userDownloadedBooks -= value;
      if (field == 'favoriteBooks') userFavoriteBooks -= value;
      if (field == 'completedTasks') userCompletedTasks -= value;
      if (field == 'addedBooks') userAddedBooks -= value;
      notifyListeners();
    } catch (e) {
      debugPrint('Error decrementing user stat: $e');
    }
  }
}
