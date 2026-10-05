import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/exam_selection_utils.dart';
import '../data/quiz_models.dart';
import '../theme/app_theme.dart';
import 'exam_result_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  شاشة أداء الاختبار — مع حفظ تلقائي وإمكانية الاستكمال
// ─────────────────────────────────────────────────────────────────────────────

class ExamTakingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int durationMinutes;
  final List<QuizQuestion> questions;
  final String? uid;
  final String? resumeAttemptId; // معرف محاولة سابقة للاستكمال

  const ExamTakingScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.durationMinutes,
    required this.questions,
    this.uid,
    this.resumeAttemptId,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _answers = {}; // questionIndex → selectedOptionIndex
  late int _secondsLeft;
  Timer? _timer;
  Timer? _autoSaveTimer;
  bool _isSubmitting = false;
  String? _attemptId; // معرف المحاولة في Firestore

  late AnimationController _timerAnimController;
  late AnimationController _progressAnimController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMinutes * 60;

    _timerAnimController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _secondsLeft),
    )..forward();

    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _initAttempt();
    _startTimer();
  }

  // ── تهيئة المحاولة (جديدة أو استكمال) ─────────────────────────────────────
  Future<void> _initAttempt() async {
    if (widget.uid == null) return;

    if (widget.resumeAttemptId != null) {
      // استعادة محاولة سابقة
      _attemptId = widget.resumeAttemptId;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('exam_attempts')
            .doc(_attemptId)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          // استعادة الإجابات السابقة
          final savedAnswers =
              (data['answers'] as Map<String, dynamic>? ?? {});
          final remainingSeconds =
              (data['remainingSeconds'] as num?)?.toInt();
          final lastQuestion =
              (data['currentQuestion'] as num?)?.toInt() ?? 0;

          if (mounted) {
            setState(() {
              for (final entry in savedAnswers.entries) {
                final idx = int.tryParse(entry.key);
                if (idx != null && entry.value is int) {
                  _answers[idx] = entry.value as int;
                }
              }
              if (remainingSeconds != null && remainingSeconds > 0) {
                _secondsLeft = remainingSeconds;
              }
            });
            // الانتقال إلى السؤال الأخير
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && lastQuestion > 0 && lastQuestion < widget.questions.length) {
                _pageController.jumpToPage(lastQuestion);
                setState(() => _currentPage = lastQuestion);
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Failed to restore attempt: $e');
      }
    } else {
      // إنشاء محاولة جديدة
      try {
        final ref =
            await FirebaseFirestore.instance.collection('exam_attempts').add({
          'userId': widget.uid,
          'quizId': widget.quizId,
          'quizTitle': widget.quizTitle,
          'status': 'in_progress',
          'answers': <String, int>{},
          'currentQuestion': 0,
          'remainingSeconds': _secondsLeft,
          'totalQuestions': widget.questions.length,
          'startedAt': FieldValue.serverTimestamp(),
          'lastSavedAt': FieldValue.serverTimestamp(),
        });
        _attemptId = ref.id;
      } catch (e) {
        debugPrint('Failed to create attempt: $e');
      }
    }

    // حفظ تلقائي كل 15 ثانية
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _autoSave();
    });
  }

  // ── حفظ تلقائي ────────────────────────────────────────────────────────────
  Future<void> _autoSave() async {
    if (_attemptId == null || widget.uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('exam_attempts')
          .doc(_attemptId)
          .update({
        'answers': {
          for (final e in _answers.entries) '${e.key}': e.value
        },
        'currentQuestion': _currentPage,
        'remainingSeconds': _secondsLeft,
        'lastSavedAt': FieldValue.serverTimestamp(),
        'status': 'in_progress',
      });
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  // ── التايمر ────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _submitExam(autoSubmit: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _timerAnimController.dispose();
    _progressAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    final pct = _secondsLeft / (widget.durationMinutes * 60);
    if (pct > 0.5) return AppTheme.primaryColor;
    if (pct > 0.25) return Colors.orange;
    return Colors.redAccent;
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    setState(() => _answers[questionIndex] = optionIndex);
    // حفظ فوري عند كل إجابة
    _autoSave();
  }

  void _goToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── إنهاء الاختبار ────────────────────────────────────────────────────────
  Future<void> _submitExam({bool autoSubmit = false}) async {
    if (_isSubmitting) return;

    if (!autoSubmit) {
      final unanswered = widget.questions.length - _answers.length;
      if (unanswered > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('إنهاء الاختبار؟',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            content: Text(
              'لم تجب على $unanswered سؤال بعد.\nهل أنت متأكد من إنهاء الاختبار؟',
              style: GoogleFonts.cairo(),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('متابعة', style: GoogleFonts.cairo())),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('إنهاء',
                    style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();
    _autoSaveTimer?.cancel();

    // حساب النتائج
    int correct = 0;
    int wrong = 0;
    final List<Map<String, dynamic>> reviewData = [];

    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      final selected = _answers[i];
      final isCorrect = selected == q.correctIndex;
      if (selected != null) {
        if (isCorrect) {
          correct++;
        } else {
          wrong++;
        }
      }
      reviewData.add({
        'question': q.question,
        'options': q.options,
        'correctIndex': q.correctIndex,
        'selectedIndex': selected,
        'explanation': q.explanation,
        'isCorrect': selected != null && isCorrect,
      });
    }

    final unanswered = widget.questions.length - _answers.length;
    final timeTaken =
        widget.durationMinutes * 60 - _secondsLeft;
    final score = widget.questions.isEmpty
        ? 0
        : (correct / widget.questions.length * 100).round();
    final stars = ExamSelectionUtils.starsForScore(score);

    // حفظ النتيجة النهائية في Firestore
    if (widget.uid != null) {
      try {
        final payload = {
          'userId': widget.uid,
          'quizId': widget.quizId,
          'quizTitle': widget.quizTitle,
          'correctAnswers': correct,
          'wrongAnswers': wrong,
          'unanswered': unanswered,
          'totalQuestions': widget.questions.length,
          'score': score,
          'stars': stars,
          'timeTakenSeconds': timeTaken,
          'answers': {for (final e in _answers.entries) '${e.key}': e.value},
          'status': 'completed',
          'submittedAt': FieldValue.serverTimestamp(),
          'lastSavedAt': FieldValue.serverTimestamp(),
        };

        if (_attemptId != null) {
          // تحديث المحاولة الموجودة
          await FirebaseFirestore.instance
              .collection('exam_attempts')
              .doc(_attemptId)
              .update(payload);
        } else {
          // إنشاء مستند جديد
          await FirebaseFirestore.instance
              .collection('exam_attempts')
              .add({...payload, 'startedAt': FieldValue.serverTimestamp()});
        }
      } catch (e) {
        debugPrint('Failed to save final attempt: $e');
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExamResultScreen(
          quizTitle: widget.quizTitle,
          correct: correct,
          wrong: wrong,
          unanswered: unanswered,
          total: widget.questions.length,
          timeTakenSeconds: timeTaken,
          reviewData: reviewData,
          score: score,
          stars: stars,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.questions.length;
    final progress = total == 0 ? 0.0 : _answers.length / total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('الخروج من الاختبار؟',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            content: Text('سيتم حفظ تقدمك تلقائياً، يمكنك الاستكمال لاحقاً.',
                style: GoogleFonts.cairo(),
                textDirection: TextDirection.rtl),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('متابعة', style: GoogleFonts.cairo())),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor),
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    Text('حفظ وخروج', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true && mounted) {
          await _autoSave(); // حفظ قبل الخروج
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark, progress),
              _buildQuestionNavigator(isDark),
              Expanded(child: _buildQuestionsPageView(isDark)),
              _buildBottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, double progress) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // التايمر
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _timerColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _timerColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          color: _timerColor, size: 16),
                      const SizedBox(width: 4),
                      Text(_formattedTime,
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ),
                const Spacer(),
                // عنوان الاختبار
                Flexible(
                  child: Text(widget.quizTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                const Spacer(),
                // رقم السؤال الحالي
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${widget.questions.length}',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // شريط التقدم
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'تم الإجابة على ${_answers.length} من ${widget.questions.length} سؤال',
                  style: GoogleFonts.cairo(
                      color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator(bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final isAnswered = _answers.containsKey(index);
          final isCurrent = index == _currentPage;
          Color bg;
          if (isCurrent) {
            bg = AppTheme.primaryColor;
          } else if (isAnswered) {
            bg = const Color(0xFF10B981);
          } else {
            bg = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;
          }
          return GestureDetector(
            onTap: () => _goToQuestion(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: isCurrent
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                boxShadow: isCurrent
                    ? [BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 6)]
                    : null,
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: GoogleFonts.cairo(
                        color: (isCurrent || isAnswered)
                            ? Colors.white
                            : (isDark ? Colors.white54 : Colors.black54),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionsPageView(bool isDark) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        final q = widget.questions[index];
        final selected = _answers[index];
        return _QuestionCard(
          question: q,
          index: index,
          total: widget.questions.length,
          selectedOption: selected,
          isDark: isDark,
          onSelect: (optIdx) => _selectAnswer(index, optIdx),
        );
      },
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed:
                _currentPage > 0 ? () => _goToQuestion(_currentPage - 1) : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            label: Text('السابق', style: GoogleFonts.cairo()),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const Spacer(),
          if (_currentPage < widget.questions.length - 1)
            ElevatedButton.icon(
              onPressed: () => _goToQuestion(_currentPage + 1),
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 14, color: Colors.white),
              label: Text('التالي',
                  style: GoogleFonts.cairo(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitExam,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white),
              label: Text('إنهاء الاختبار',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  بطاقة السؤال
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final int total;
  final int? selectedOption;
  final bool isDark;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
    required this.selectedOption,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // نص السؤال
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السؤال ${index + 1} من $total',
                  style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(question.question,
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.6),
                    textDirection: TextDirection.rtl),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // الخيارات
          ...question.options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final isSelected = selectedOption == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.10)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : Colors.grey.shade100),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.black12),
                      ),
                      child: Center(
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : Text(
                                String.fromCharCode(0x0041 + i), // A,B,C,D...
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black38),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(opt,
                          style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black87)),
                          textDirection: TextDirection.rtl),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
