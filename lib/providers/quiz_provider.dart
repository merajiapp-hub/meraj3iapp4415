import 'dart:async';
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
  final List<QuizQuestion> _publishedQuestions = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _publishedSubscription;

  int _lastCount = 15;
  String? _lastCategory;
  QuestionDifficulty? _lastDifficulty;

  int get xp => _xp;
  int get streak => _streak;
  List<QuizQuestion> get dailyQuestions => _currentQuiz;
  int get totalQuestions => QuizBank.allQuestions.length;
  int get correctCount => _answeredQuestions.values.where((v) => v).length;
  int get wrongCount => _answeredQuestions.values.where((v) => !v).length;

  QuizProvider() {
    _listenToPublishedQuestions();
    _loadProgress();
  }

  void _listenToPublishedQuestions() {
    _publishedSubscription = FirebaseFirestore.instance.collection('quizzes').snapshots().listen((snapshot) {
      _publishedQuestions
        ..clear()
        ..addAll(snapshot.docs.map((doc) => (doc.id, doc.data())).where((item) {
          final data = item.$2;
          return data['kind'] == 'question' &&
              data['status'] == 'published' &&
              data['isActive'] == true &&
              data['options'] is List &&
              (data['options'] as List).length >= 2;
        }).map((item) => QuizQuestion.fromMap(item.$2, item.$1)));
      notifyListeners();
    });
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

  Future<void> regenerateQuiz() async {
    await generateNewQuiz(
      count: _lastCount,
      category: _lastCategory,
      difficulty: _lastDifficulty,
    );
  }

  void startPublishedQuiz(List<QuizQuestion> questions) {
    _currentQuiz = questions.map(_shuffleOptions).toList();
    _answeredQuestions.clear();
    notifyListeners();
  }

  Future<void> generateNewQuiz({
    int count = 15,
    String? category,
    QuestionDifficulty? difficulty,
  }) async {
    _lastCount = count;
    _lastCategory = category;
    _lastDifficulty = difficulty;

    // 1. Check internet connectivity
    var connectivityResults = await (Connectivity().checkConnectivity());
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none) || connectivityResults.length > 1 || (connectivityResults.isNotEmpty && connectivityResults.first != ConnectivityResult.none);

    // 1. Fetch from Firebase
    List<QuizQuestion> combined = List<QuizQuestion>.from(_publishedQuestions);
    if (hasInternet) {
      try {
        final snapshot = await FirebaseFirestore.instance.collection('quizzes').limit(200).get();
        if (combined.isEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final isPublishedQuestion = data['kind'] == 'question' &&
                data['status'] == 'published' &&
                data['isActive'] == true &&
                (data['options'] is List) &&
                (data['options'] as List).length >= 2;
            if (!isPublishedQuestion) continue;
            final question = QuizQuestion.fromMap(data, doc.id);
            if (category != null && question.category != category) continue;
            if (difficulty != null && question.difficulty != difficulty) continue;
            combined.add(question);
          }
        }
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
    
    // Merge remote and local pools by content, because the same question can
    // have different document IDs in Firestore and in the bundled bank.
    final Set<String> seenQuestions = {};
    List<QuizQuestion> finalAvailable = [];
    for (var q in combined) {
      final key = _questionKey(q);
      if (seenQuestions.add(key)) {
        finalAvailable.add(q);
      }
    }
    for (var q in allLocal) {
      final key = _questionKey(q);
      if (seenQuestions.add(key)) {
        finalAvailable.add(q);
      }
    }

    // Filter out previously used questions if possible
    var unusedAvailable = finalAvailable.where((q) => !_usedQuestionIds.contains(q.id)).toList();
    if (unusedAvailable.length < count) {
      // Start a new cycle only after exhausting the current pool.
      _usedQuestionIds.clear();
      unusedAvailable = List<QuizQuestion>.from(finalAvailable);
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

  @override
  void dispose() {
    _publishedSubscription?.cancel();
    super.dispose();
  }

  String _questionKey(QuizQuestion question) {
    final normalizedQuestion = question.question.trim().toLowerCase();
    final normalizedOptions = question.options
        .map((option) => option.trim().toLowerCase())
        .join('|');
    return '$normalizedQuestion::$normalizedOptions';
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
