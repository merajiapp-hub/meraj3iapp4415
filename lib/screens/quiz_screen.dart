import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/quiz_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int? _selectedOption;
  bool _isAnswered = false;
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;
  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _cardFadeAnim;

  // Timer
  int _secondsLeft = 30;
  Timer? _timer;
  final bool _timerEnabled = true;

  // Stats for final report
  int _correctAnswers = 0;
  int _wrongAnswers = 0;
  final List<Map<String, dynamic>> _answerHistory = [];
  late DateTime _quizStartTime;

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _cardAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cardFadeAnim = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    );

    _headerAnimController.forward();
    _cardAnimController.forward();
    _startTimer();
  }

  void _startTimer() {
    if (!_timerEnabled) return;
    _timer?.cancel();
    _secondsLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_isAnswered) _autoSubmitTimeout();
      }
    });
  }

  void _autoSubmitTimeout() {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    final question = provider.dailyQuestions[_currentIndex];
    _answerHistory.add({
      'question': question,
      'selected': -1,
      'isCorrect': false,
      'timeout': true,
    });
    setState(() {
      _isAnswered = true;
      _wrongAnswers++;
    });
    provider.answerQuestion(question.id, false);
  }

  void _nextQuestion(QuizProvider provider) {
    if (_currentIndex < provider.dailyQuestions.length - 1) {
      _cardAnimController.reset();
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
      _cardAnimController.forward();
      _startTimer();
    } else {
      _timer?.cancel();
      _showResultScreen(provider);
    }
  }

  void _submitAnswer(QuizProvider provider) {
    if (_selectedOption == null) return;
    _timer?.cancel();
    final question = provider.dailyQuestions[_currentIndex];
    final isCorrect = _selectedOption == question.correctIndex;
    _answerHistory.add({
      'question': question,
      'selected': _selectedOption,
      'isCorrect': isCorrect,
      'timeout': false,
    });
    if (isCorrect) {
      _correctAnswers++;
    } else {
      _wrongAnswers++;
    }

    provider.answerQuestion(question.id, isCorrect);
    setState(() => _isAnswered = true);
  }

  void _showResultScreen(QuizProvider provider) {
    final elapsed = DateTime.now().difference(_quizStartTime);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final total = provider.dailyQuestions.length;
    final pct = (_correctAnswers / total * 100).round();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizResultScreen(
          correctAnswers: _correctAnswers,
          wrongAnswers: _wrongAnswers,
          total: total,
          percentage: pct,
          timeStr: '$minutes\u062f $seconds\u062b',
          answerHistory: _answerHistory,
          onRetry: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const QuizScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  Color _getDifficultyColor(QuestionDifficulty diff) {
    switch (diff) {
      case QuestionDifficulty.easy:
        return const Color(0xFF10B981);
      case QuestionDifficulty.medium:
        return const Color(0xFFF59E0B);
      case QuestionDifficulty.hard:
        return const Color(0xFFEF4444);
      case QuestionDifficulty.veryHard:
        return const Color(0xFF8B5CF6);
    }
  }

  String _getDifficultyLabel(QuestionDifficulty diff) {
    switch (diff) {
      case QuestionDifficulty.easy:
        return 'سهل';
      case QuestionDifficulty.medium:
        return 'متوسط';
      case QuestionDifficulty.hard:
        return 'صعب';
      case QuestionDifficulty.veryHard:
        return 'صعب جداً';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quizProvider = Provider.of<QuizProvider>(context);
    final questions = quizProvider.dailyQuestions;

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    final currentQuestion = questions[_currentIndex];
    final total = questions.length;
    final progress = (_currentIndex + (_isAnswered ? 1 : 0)) / total;
    final diffColor = _getDifficultyColor(currentQuestion.difficulty);
    final timerPct = _secondsLeft / 30;
    final timerColor = _secondsLeft > 10
        ? const Color(0xFF10B981)
        : _secondsLeft > 5
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: Column(
        children: [
          // ─── رأس الصفحة المنحنية ───────────────────────────────────
          FadeTransition(
            opacity: _headerFadeAnim,
            child: _buildCurvedHeader(
              isDark: isDark,
              provider: quizProvider,
              current: _currentIndex + 1,
              total: total,
              progress: progress,
              diffColor: diffColor,
              diffLabel: _getDifficultyLabel(currentQuestion.difficulty),
              timerPct: timerPct,
              timerColor: timerColor,
            ),
          ),

          // ─── محتوى الاختبار ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SlideTransition(
                position: _cardSlideAnim,
                child: FadeTransition(
                  opacity: _cardFadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // بطاقة السؤال
                      _buildQuestionCard(
                        isDark: isDark,
                        question: currentQuestion,
                        diffColor: diffColor,
                      ),
                      const SizedBox(height: 20),
                      // الخيارات
                      ..._buildOptions(isDark, currentQuestion, quizProvider),
                      // شرح الإجابة
                      if (_isAnswered &&
                          currentQuestion.explanation != null) ...[
                        const SizedBox(height: 16),
                        _buildExplanationCard(
                          isDark,
                          currentQuestion.explanation!,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── زر التحقق / التالي ───────────────────────────────────
          _buildFooter(isDark, quizProvider),
        ],
      ),
    );
  }

  Widget _buildCurvedHeader({
    required bool isDark,
    required QuizProvider provider,
    required int current,
    required int total,
    required double progress,
    required Color diffColor,
    required String diffLabel,
    required double timerPct,
    required Color timerColor,
  }) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              children: [
                // شريط العنوان
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'اختبار المعلومات',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // المؤقت
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: timerColor, width: 2),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: timerPct,
                              strokeWidth: 2,
                              color: timerColor,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          Text(
                            '$_secondsLeft',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // إحصائيات مصغرة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderStat(
                      Icons.bolt,
                      '${provider.xp} XP',
                      Colors.amber,
                    ),
                    _buildHeaderStat(
                      Icons.local_fire_department,
                      '${provider.streak} يوم',
                      Colors.orange,
                    ),
                    _buildHeaderStat(
                      Icons.check_circle_outline_rounded,
                      '$current/$total',
                      Colors.white,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: diffColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        diffLabel,
                        style: GoogleFonts.tajawal(
                          color: diffColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // شريط التقدم
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard({
    required bool isDark,
    required QuizQuestion question,
    required Color diffColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  question.category,
                  style: GoogleFonts.tajawal(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.6,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(
    bool isDark,
    QuizQuestion question,
    QuizProvider provider,
  ) {
    return question.options.asMap().entries.map((entry) {
      final idx = entry.key;
      final val = entry.value;
      final letter = String.fromCharCode(0x0041 + idx); // A, B, C, D

      Color borderColor;
      Color bgColor;
      Color textColor;
      Widget? trailing;

      if (_isAnswered) {
        if (idx == question.correctIndex) {
          borderColor = const Color(0xFF10B981);
          bgColor = const Color(
            0xFF10B981,
          ).withValues(alpha: isDark ? 0.15 : 0.08);
          textColor = const Color(0xFF10B981);
          trailing = const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 22,
          );
        } else if (_selectedOption == idx) {
          borderColor = const Color(0xFFEF4444);
          bgColor = const Color(
            0xFFEF4444,
          ).withValues(alpha: isDark ? 0.15 : 0.08);
          textColor = const Color(0xFFEF4444);
          trailing = const Icon(
            Icons.cancel_rounded,
            color: Color(0xFFEF4444),
            size: 22,
          );
        } else {
          borderColor = isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0);
          bgColor = isDark ? AppTheme.surfaceDark : Colors.white;
          textColor = isDark ? Colors.white60 : Colors.grey[500]!;
        }
      } else if (_selectedOption == idx) {
        borderColor = AppTheme.primaryColor;
        bgColor = AppTheme.primaryColor.withValues(alpha: 0.08);
        textColor = AppTheme.primaryColor;
        trailing = null;
      } else {
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0);
        bgColor = isDark ? AppTheme.surfaceDark : Colors.white;
        textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        trailing = null;
      }

      return GestureDetector(
        onTap: _isAnswered ? null : () => setState(() => _selectedOption = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: GoogleFonts.outfit(
                      color: borderColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  val,
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExplanationCard(bool isDark, String explanation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'شرح الإجابة',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark, QuizProvider provider) {
    final questions = provider.dailyQuestions;
    final isLast = _currentIndex == questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: (_selectedOption == null && !_isAnswered)
              ? null
              : (_isAnswered
                    ? () => _nextQuestion(provider)
                    : () => _submitAnswer(provider)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            decoration: BoxDecoration(
              gradient: (_selectedOption == null && !_isAnswered)
                  ? null
                  : LinearGradient(
                      colors: _isAnswered
                          ? (isLast
                                ? [
                                    const Color(0xFF10B981),
                                    const Color(0xFF059669),
                                  ]
                                : [
                                    AppTheme.primaryColor,
                                    const Color(0xFF0891B2),
                                  ])
                          : [AppTheme.primaryColor, const Color(0xFF0891B2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: (_selectedOption == null && !_isAnswered)
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9))
                  : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: (_selectedOption != null || _isAnswered)
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isAnswered
                        ? (isLast ? 'عرض النتيجة' : 'السؤال التالي')
                        : 'تحقق من الإجابة',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: (_selectedOption == null && !_isAnswered)
                          ? (isDark ? Colors.white38 : Colors.grey[400])
                          : Colors.white,
                    ),
                  ),
                  if (_isAnswered) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isLast
                          ? Icons.emoji_events_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── شاشة النتيجة ─────────────────────────────────────────────────────────────
class _QuizResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int wrongAnswers;
  final int total;
  final int percentage;
  final String timeStr;
  final List<Map<String, dynamic>> answerHistory;
  final VoidCallback onRetry;

  const _QuizResultScreen({
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.total,
    required this.percentage,
    required this.timeStr,
    required this.answerHistory,
    required this.onRetry,
  });

  @override
  State<_QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<_QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getResultColor() {
    if (widget.percentage >= 80) return const Color(0xFF10B981);
    if (widget.percentage >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getResultMessage() {
    if (widget.percentage >= 90) return 'ممتاز! أداء استثنائي 🏆';
    if (widget.percentage >= 80) return 'جيد جداً! استمر في التفوق 🌟';
    if (widget.percentage >= 60) return 'جيد! يمكنك التحسين 💪';
    return 'واصل المذاكرة، ستتحسن 📚';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultColor = _getResultColor();

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── الرأس ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      resultColor.withValues(alpha: 0.9),
                      resultColor.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.percentage}%',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getResultMessage(),
                      style: GoogleFonts.tajawal(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // ─── إحصائيات ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            isDark: isDark,
                            icon: Icons.check_circle_rounded,
                            label: 'صحيحة',
                            value: '${widget.correctAnswers}',
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isDark: isDark,
                            icon: Icons.cancel_rounded,
                            label: 'خاطئة',
                            value: '${widget.wrongAnswers}',
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isDark: isDark,
                            icon: Icons.timer_rounded,
                            label: 'الوقت',
                            value: widget.timeStr,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ─── شريط التقدم ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'معدل النجاح',
                                style: GoogleFonts.tajawal(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${widget.percentage}%',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: resultColor,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: widget.percentage / 100,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                resultColor,
                              ),
                              minHeight: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── مراجعة الإجابات ────────────────────────────
                    GestureDetector(
                      onTap: () => setState(() => _showReview = !_showReview),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.rate_review_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'مراجعة الإجابات',
                                style: GoogleFonts.tajawal(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              _showReview
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showReview) ...[
                      const SizedBox(height: 12),
                      ...widget.answerHistory.map((item) {
                        final q = item['question'] as QuizQuestion;
                        final isCorrect = item['isCorrect'] as bool;
                        final isTimeout = item['timeout'] as bool;
                        final selected = item['selected'] as int;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCorrect
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.4)
                                  : const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: isCorrect
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      q.question,
                                      style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isTimeout)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '⏰ انتهى الوقت',
                                    style: GoogleFonts.tajawal(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'إجابتك: ${q.options[selected]}',
                                  style: GoogleFonts.tajawal(
                                    color: isCorrect
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontSize: 12,
                                  ),
                                ),
                                if (!isCorrect)
                                  Text(
                                    'الصحيحة: ${q.options[q.correctIndex]}',
                                    style: GoogleFonts.tajawal(
                                      color: const Color(0xFF10B981),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                              if (q.explanation != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '💡 ${q.explanation}',
                                    style: GoogleFonts.tajawal(
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 20),

                    // ─── أزرار ────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'الرئيسية',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              final provider = Provider.of<QuizProvider>(
                                context,
                                listen: false,
                              );
                              provider.generateNewQuiz();
                              widget.onRetry();
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    Color(0xFF0891B2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'اختبار جديد',
                                      style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─── Header Clipper ──────────────────────────────────────────────────────────
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
