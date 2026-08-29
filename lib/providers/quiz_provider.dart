import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/quiz_models.dart';
import '../data/quiz_bank.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QuizProvider extends ChangeNotifier {
  int _xp = 0;
  int _streak = 0;
  DateTime? _lastQuizDate;
  List<QuizQuestion> _currentQuiz = [];
  final Map<String, bool> _answeredQuestions = {};
  final List<String> _usedQuestionIds = [];

  int get xp => _xp;
  int get streak => _streak;
  List<QuizQuestion> get dailyQuestions => _currentQuiz;
  int get totalQuestions => QuizBank.allQuestions.length;
  int get correctCount => _answeredQuestions.values.where((v) => v).length;
  int get wrongCount => _answeredQuestions.values.where((v) => !v).length;

  QuizProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('quiz_xp') ?? 0;
    _streak = prefs.getInt('quiz_streak') ?? 0;
    final lastDateStr = prefs.getString('last_quiz_date');
    if (lastDateStr != null) {
      _lastQuizDate = DateTime.parse(lastDateStr);
    }
    final usedIds = prefs.getStringList('used_question_ids') ?? [];
    _usedQuestionIds.addAll(usedIds);
    generateNewQuiz();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_xp', _xp);
    await prefs.setInt('quiz_streak', _streak);
    if (_lastQuizDate != null) {
      await prefs.setString('last_quiz_date', _lastQuizDate!.toIso8601String());
    }
    await prefs.setStringList('used_question_ids', _usedQuestionIds);
  }

  Future<void> generateNewQuiz({
    int count = 15,
    String? category,
    QuestionDifficulty? difficulty,
  }) async {
    // 1. Check internet connectivity
    var connectivityResults = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none) || connectivityResults.length > 1 || (connectivityResults.isNotEmpty && connectivityResults.first != ConnectivityResult.none);

    // 1. Fetch from Firebase
    List<QuizQuestion> combined = [];
    if (hasInternet) {
      try {
        Query query = FirebaseFirestore.instance.collection('quizzes');
        if (category != null) query = query.where('category', isEqualTo: category);
        if (difficulty != null) query = query.where('difficulty', isEqualTo: difficulty.name);

        final snapshot = await query.limit(50).get();
        combined.addAll(snapshot.docs.map((doc) => QuizQuestion.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      } catch (e) {
        debugPrint('Error fetching quizzes from Firebase: $e');
      }
    }

    // 2. Fetch from local QuizBank to increase the pool
    var allLocal = QuizBank.allQuestions;
    if (category != null) {
      allLocal = allLocal.where((q) => q.category == category).toList();
    }
    if (difficulty != null) {
      allLocal = allLocal.where((q) => q.difficulty.name == difficulty.name).toList();
    }
    
    // Combine avoiding duplicates
    final Set<String> seenIds = {};
    List<QuizQuestion> finalAvailable = [];
    for (var q in combined) {
      if (!seenIds.contains(q.id)) {
        finalAvailable.add(q);
        seenIds.add(q.id);
      }
    }
    for (var q in allLocal) {
      if (!seenIds.contains(q.id)) {
        finalAvailable.add(q);
        seenIds.add(q.id);
      }
    }

    // Filter out previously used questions if possible
    var unusedAvailable = finalAvailable.where((q) => !_usedQuestionIds.contains(q.id)).toList();
    if (unusedAvailable.length < count) {
      // If we don't have enough unused, we have to reuse questions. Reset history.
      _usedQuestionIds.clear();
      unusedAvailable = List<QuizQuestion>.from(finalAvailable);
    }

    // If we STILL don't have enough to meet the count (because the category is very specific and has few questions),
    // we duplicate them so the user gets the number of questions they asked for.
    if (unusedAvailable.isNotEmpty && unusedAvailable.length < count) {
      List<QuizQuestion> duplicated = [];
      while(duplicated.length < count) {
        for(var q in unusedAvailable) {
          if (duplicated.length >= count) break;
          // Assign a unique ID for the duplicated instance so UI keys don't conflict
          final newId = '${q.id}_dup_${duplicated.length}';
          duplicated.add(QuizQuestion(
            id: newId,
            question: q.question,
            options: q.options,
            correctIndex: q.correctIndex,
            category: q.category,
            explanation: q.explanation,
            difficulty: q.difficulty,
          ));
        }
      }
      unusedAvailable = duplicated;
    }

    // Shuffle and pick the requested count
    unusedAvailable.shuffle(Random());
    _currentQuiz = unusedAvailable.take(count).map<QuizQuestion>(_shuffleOptions).toList();
    _answeredQuestions.clear();

    for (final q in _currentQuiz) {
      _usedQuestionIds.add(q.id);
    }
    _saveProgress();
    notifyListeners();
  }

  QuizQuestion _shuffleOptions(QuizQuestion q) {
    final correctAnswer = q.options[q.correctIndex];
    final shuffled = List<String>.from(q.options)..shuffle(Random());
    return QuizQuestion(
      id: q.id,
      question: q.question,
      options: shuffled,
      correctIndex: shuffled.indexOf(correctAnswer),
      category: q.category,
      explanation: q.explanation,
      difficulty: q.difficulty,
    );
  }

  void answerQuestion(String id, bool isCorrect) {
    if (_answeredQuestions.containsKey(id)) return;
    _answeredQuestions[id] = isCorrect;
    if (isCorrect) {
      _xp += 10;
      _updateStreak();
    }
    _saveProgress();
    notifyListeners();
  }

  void _updateStreak() {
    final now = DateTime.now();
    if (_lastQuizDate == null) {
      _streak = 1;
    } else {
      final diff = now.difference(_lastQuizDate!).inDays;
      if (diff == 1) {
        _streak++;
      } else if (diff > 1) {
        _streak = 1;
      }
    }
    _lastQuizDate = now;
  }
}
