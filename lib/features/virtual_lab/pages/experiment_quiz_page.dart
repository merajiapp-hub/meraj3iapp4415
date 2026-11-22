import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../models/experiment_model.dart';
import '../providers/virtual_lab_provider.dart';

class ExperimentQuizPage extends StatefulWidget {
  final ExperimentModel experiment;

  const ExperimentQuizPage({
    super.key,
    required this.experiment,
  });

  @override
  State<ExperimentQuizPage> createState() => _ExperimentQuizPageState();
}

class _ExperimentQuizPageState extends State<ExperimentQuizPage> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> chosenOptionIndex
  bool _isFinished = false;

  int get _score {
    int count = 0;
    final questions = widget.experiment.quizQuestions;
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i].correctIndex) {
        count++;
      }
    }
    return count;
  }

  int get _percentage {
    if (widget.experiment.quizQuestions.isEmpty) return 100;
    return ((_score / widget.experiment.quizQuestions.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final questions = widget.experiment.quizQuestions;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'التقييم العلمي للتجربة',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isFinished ? _buildResultView(isDark) : _buildQuestionsView(isDark, cardBg, questions),
      ),
    );
  }

  Widget _buildQuestionsView(bool isDark, Color cardBg, List<QuizQuestion> questions) {
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'لا توجد أسئلة تقييمية لهذه التجربة',
          style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    final q = questions[_currentIndex];
    final selectedOption = _selectedAnswers[_currentIndex];
    final hasAnswered = selectedOption != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linear Progress Bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / questions.length,
            backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(widget.experiment.subjectColor),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 14),

          // Question header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_currentIndex + 1} من ${questions.length}',
                style: GoogleFonts.tajawal(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: widget.experiment.subjectColor,
                ),
              ),
              Text(
                widget.experiment.title,
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question text card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              q.question,
              style: GoogleFonts.tajawal(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Options list
          ...List.generate(q.options.length, (optIdx) {
            final optionText = q.options[optIdx];
            final isChosen = selectedOption == optIdx;
            final isCorrect = q.correctIndex == optIdx;

            Color borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
            Color fillBg = cardBg;

            if (hasAnswered) {
              if (isCorrect) {
                borderColor = const Color(0xFF10B981);
                fillBg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1);
              } else if (isChosen) {
                borderColor = const Color(0xFFEF4444);
                fillBg = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.1);
              }
            } else if (isChosen) {
              borderColor = widget.experiment.subjectColor;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: hasAnswered
                    ? null
                    : () {
                        setState(() {
                          _selectedAnswers[_currentIndex] = optIdx;
                        });
                      },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isChosen
                              ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              : (isDark ? Colors.white10 : Colors.grey[200]),
                        ),
                        child: Center(
                          child: hasAnswered && isCorrect
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                              : (hasAnswered && isChosen
                                  ? const Icon(Icons.close_rounded, color: Colors.white, size: 18)
                                  : Text(
                                      String.fromCharCode(65 + optIdx),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionText,
                          style: GoogleFonts.tajawal(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Scientific Explanation (shown after answering)
          if (hasAnswered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'التفسير العلمي:',
                        style: GoogleFonts.tajawal(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.explanation,
                    style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white70, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Next / Finish Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  if (_currentIndex < questions.length - 1) {
                    setState(() => _currentIndex++);
                  } else {
                    _finishQuiz();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: widget.experiment.subjectColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentIndex < questions.length - 1 ? 'السؤال التالي' : 'إنهاء الاختبار وعرض النتيجة',
                  style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _finishQuiz() {
    setState(() => _isFinished = true);
    final user = context.read<AuthProvider>().user;
    context.read<VirtualLabProvider>().completeExperiment(
          userId: user?.uid,
          experimentId: widget.experiment.id,
          quizScore: _percentage,
        );
  }

  Widget _buildResultView(bool isDark) {
    final passed = _percentage >= 60;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.15),
              ),
              child: Icon(
                passed ? Icons.workspace_premium_rounded : Icons.replay_rounded,
                size: 58,
                color: passed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              passed ? 'تهانينا! لقد أتقنت التجربة بنجاح 🎉' : 'تجربة جيدة! يمكنك المحاولة مجدداً لتثبيت المفاهيم',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الدرجة المحققة: $_score من أصل ${widget.experiment.quizQuestions.length} ($_percentage%)',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: passed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                widget.experiment.conclusion,
                style: GoogleFonts.tajawal(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _selectedAnswers.clear();
                        _isFinished = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'إعادة الاختبار',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Back to Lab main page
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'العودة للمختبر',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
