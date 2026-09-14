import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamResultScreen extends StatefulWidget {
  final String quizTitle;
  final int correct;
  final int wrong;
  final int unanswered;
  final int total;
  final int timeTakenSeconds;
  final List<Map<String, dynamic>> reviewData;

  const ExamResultScreen({
    super.key,
    required this.quizTitle,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.total,
    required this.timeTakenSeconds,
    required this.reviewData,
  });

  @override
  State<ExamResultScreen> createState() => _ExamResultScreenState();
}

class _ExamResultScreenState extends State<ExamResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnim;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get score =>
      widget.total == 0 ? 0 : (widget.correct / widget.total * 100).round();

  Color get scoreColor {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get scoreLabel {
    if (score >= 80) return 'ممتاز! 🎉';
    if (score >= 60) return 'جيد 👍';
    if (score >= 40) return 'مقبول 📚';
    return 'يحتاج مراجعة 💪';
  }

  String get formattedTime {
    final m = (widget.timeTakenSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (widget.timeTakenSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: _showReview
          ? _buildReviewView(isDark)
          : _buildResultView(isDark),
    );
  }

  Widget _buildResultView(bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scoreColor.withValues(alpha: 0.8),
                    scoreColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'نتيجة الاختبار',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.quizTitle,
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 32),
                  // Score circle
                  AnimatedBuilder(
                    animation: _scoreAnim,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: _scoreAnim.value * (score / 100),
                              strokeWidth: 10,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(score * _scoreAnim.value).round()}%',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                scoreLabel,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'صحيحة',
                          value: widget.correct,
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'خاطئة',
                          value: widget.wrong,
                          icon: Icons.cancel_rounded,
                          color: const Color(0xFFEF4444),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'متروكة',
                          value: widget.unanswered,
                          icon: Icons.remove_circle_rounded,
                          color: const Color(0xFF94A3B8),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Time taken
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Color(0xFF6366F1)),
                        const SizedBox(width: 10),
                        Text('الوقت المستغرق',
                            style: GoogleFonts.cairo(
                                color: isDark ? Colors.white70 : Colors.black54)),
                        const Spacer(),
                        Text(
                          formattedTime,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Review button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showReview = true),
                      icon: const Icon(Icons.rate_review_rounded,
                          color: Colors.white),
                      label: Text(
                        'مراجعة الإجابات',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Return button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Pop all screens until the exams list
                        Navigator.of(context).popUntil((route) => route.isFirst
                            || route.settings.name == '/');
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: Text(
                        'العودة للرئيسية',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewView(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => setState(() => _showReview = false),
                ),
                Expanded(
                  child: Text(
                    'مراجعة الإجابات',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '${widget.correct}/${widget.total} ✓',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.reviewData.length,
              itemBuilder: (context, index) {
                final item = widget.reviewData[index];
                return _buildReviewCard(index, item, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
      int index, Map<String, dynamic> item, bool isDark) {
    final isCorrect = item['isCorrect'] as bool;
    final selected = item['selectedIndex'] as int?;
    final correct = item['correctIndex'] as int;
    final options = List<String>.from(item['options'] as List);
    final explanation = item['explanation'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected == null
              ? Colors.grey.withValues(alpha: 0.3)
              : isCorrect
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: selected == null
                        ? Colors.grey.withValues(alpha: 0.15)
                        : isCorrect
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected == null
                            ? Icons.remove_circle_outline
                            : isCorrect
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                        size: 14,
                        color: selected == null
                            ? Colors.grey
                            : isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selected == null
                            ? 'متروكة'
                            : isCorrect
                                ? 'صحيح'
                                : 'خطأ',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selected == null
                              ? Colors.grey
                              : isCorrect
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'السؤال ${index + 1}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item['question'] as String,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.5,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            ...options.asMap().entries.map((entry) {
              final optIdx = entry.key;
              final optText = entry.value;
              final isSelected = selected == optIdx;
              final isCorrectOpt = correct == optIdx;
              Color? bg;
              Color? border;
              if (isCorrectOpt) {
                bg = const Color(0xFF10B981).withValues(alpha: 0.1);
                border = const Color(0xFF10B981);
              } else if (isSelected && !isCorrectOpt) {
                bg = const Color(0xFFEF4444).withValues(alpha: 0.1);
                border = const Color(0xFFEF4444);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bg ?? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: border ?? (isDark ? Colors.white10 : Colors.black12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrectOpt
                          ? Icons.check_circle_rounded
                          : (isSelected ? Icons.cancel_rounded : Icons.circle_outlined),
                      size: 18,
                      color: isCorrectOpt
                          ? const Color(0xFF10B981)
                          : (isSelected ? const Color(0xFFEF4444) : Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        optText,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: (isCorrectOpt || isSelected)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (explanation != null && explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        explanation,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFF4338CA),
                          height: 1.5,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

