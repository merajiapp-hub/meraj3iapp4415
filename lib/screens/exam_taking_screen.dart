import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../data/quiz_models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'exam_result_screen.dart';

class ExamTakingScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int durationMinutes;
  final List<QuizQuestion> questions;

  const ExamTakingScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.durationMinutes,
    required this.questions,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, int> _answers = {}; // questionIndex -> selectedOptionIndex
  late int _secondsLeft;
  Timer? _timer;
  bool _isSubmitting = false;

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

    _startTimer();
  }

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
    if (pct > 0.5) return const Color(0xFF8B5CF6);
    if (pct > 0.25) return const Color(0xFFA855F7);
    return const Color(0xFFDB2777);
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    setState(() => _answers[questionIndex] = optionIndex);
  }

  void _goToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _submitExam({bool autoSubmit = false}) async {
    if (_isSubmitting) return;
    // Cache uid before any async gaps
    final uid = context.read<AuthProvider>().user?.uid;
    if (!autoSubmit) {
      final answeredCount = _answers.length;
      final totalCount = widget.questions.length;
      final unanswered = totalCount - answeredCount;

      if (unanswered > 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'إنهاء الاختبار؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            content: Text(
              'لم تجب على $unanswered سؤال بعد.\nهل أنت متأكد من إنهاء الاختبار؟',
              style: GoogleFonts.cairo(),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('متابعة', style: GoogleFonts.cairo()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('إنهاء', style: GoogleFonts.cairo(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }
    }

    setState(() => _isSubmitting = true);
    _timer?.cancel();

    // Calculate results
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

    final int unanswered = widget.questions.length - _answers.length;
    final int timeTakenSeconds = widget.durationMinutes * 60 - _secondsLeft;

    // Save attempt to Firestore
    try {
      if (uid != null) {
        await FirebaseFirestore.instance.collection('exam_attempts').add({
          'userId': uid,
          'quizId': widget.quizId,
          'quizTitle': widget.quizTitle,
          'correctAnswers': correct,
          'wrongAnswers': wrong,
          'unanswered': unanswered,
          'totalQuestions': widget.questions.length,
          'score': widget.questions.isEmpty
              ? 0
              : (correct / widget.questions.length * 100).round(),
          'timeTakenSeconds': timeTakenSeconds,
          'submittedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to save exam attempt: $e');
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
          timeTakenSeconds: timeTakenSeconds,
          reviewData: reviewData,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('الخروج من الاختبار؟',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            content: Text('سيتم فقدان إجاباتك الحالية.',
                style: GoogleFonts.cairo(), textDirection: TextDirection.rtl),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('متابعة', style: GoogleFonts.cairo())),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('خروج',
                      style: GoogleFonts.cairo(color: Colors.white))),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
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
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                // Timer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _timerColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _timerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_rounded, color: _timerColor, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _formattedTime,
                        style: GoogleFonts.outfit(
                          color: _timerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.quizTitle,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // Progress fraction
                Text(
                  '${_currentPage + 1}/${widget.questions.length}',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الإجابات: ${_answers.length}/${widget.questions.length}',
                      style: GoogleFonts.cairo(
                          color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionNavigator(bool isDark) {
    return Container(
      height: 48,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final isAnswered = _answers.containsKey(index);
          final isCurrent = index == _currentPage;
          return GestureDetector(
            onTap: () => _goToQuestion(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? const Color(0xFF7C3AED)
                    : isAnswered
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                border: isCurrent
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.outfit(
                    color: (isCurrent || isAnswered) ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        final q = widget.questions[index];
        return _buildQuestionCard(q, index, isDark);
      },
    );
  }

  Widget _buildQuestionCard(QuizQuestion q, int index, bool isDark) {
    final selectedOption = _answers[index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6D28D9), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'السؤال ${index + 1}',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  q.question,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Options
          ...q.options.asMap().entries.map((entry) {
            final optionIndex = entry.key;
            final optionText = entry.value;
            final isSelected = selectedOption == optionIndex;
            final letter = String.fromCharCode(0x0041 + optionIndex); // A, B, C, D

            return GestureDetector(
              onTap: () => _selectAnswer(index, optionIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E40AF).withValues(alpha: 0.1)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? const Color(0xFF7C3AED)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF7C3AED), size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == widget.questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: () => _goToQuestion(_currentPage - 1),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              label: Text('السابق', style: GoogleFonts.cairo()),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          const Spacer(),
          // Next or Submit
          if (!isLast)
            ElevatedButton.icon(
              onPressed: () => _goToQuestion(_currentPage + 1),
              icon: Text('التالي', style: GoogleFonts.cairo(color: Colors.white)),
              label: const Icon(Icons.arrow_back_ios_rounded,
                  size: 16, color: Colors.white),
              style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : () => _submitExam(),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _isSubmitting ? 'جاري الإرسال...' : 'إنهاء الاختبار',
                style: GoogleFonts.cairo(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
}

