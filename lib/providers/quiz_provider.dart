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

    List<QuizQuestion> available = [];

    if (hasInternet) {
      try {
        // Fetch from Firebase
        Query query = FirebaseFirestore.instance.collection('quizzes');
        if (category != null) {
          query = query.where('category', isEqualTo: category);
        }
        if (difficulty != null) {
          query = query.where('difficulty', isEqualTo: difficulty.name);
        }

        final snapshot = await query.limit(50).get();
        final firebaseQuestions = snapshot.docs.map((doc) {
          return QuizQuestion.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        if (firebaseQuestions.isNotEmpty) {
          available = firebaseQuestions.where((q) => !_usedQuestionIds.contains(q.id)).toList();
          
          if (available.length < count) {
            // Reset used IDs if we run out
            _usedQuestionIds.removeWhere((id) => firebaseQuestions.any((q) => q.id == id));
            available = List<QuizQuestion>.from(firebaseQuestions);
          }
        }
      } catch (e) {
        debugPrint('Error fetching quizzes from Firebase: $e');
      }
    }

    // 2. Fallback to local QuizBank if Firebase failed or no internet
    if (available.isEmpty) {
      var all = QuizBank.allQuestions;

      if (category != null) {
        all = all.where((q) => q.category == category).toList();
      }
      if (difficulty != null) {
        all = all.where((q) => q.difficulty.name == difficulty.name).toList();
      }

      available = all.where((q) => !_usedQuestionIds.contains(q.id)).toList();

      if (available.length < count) {
        _usedQuestionIds.removeWhere((id) => all.any((q) => q.id == id));
        available = List<QuizQuestion>.from(all);
      }
    }

    available.shuffle(Random());
    _currentQuiz = available.take(count).map<QuizQuestion>(_shuffleOptions).toList();
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
