import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/quiz_models.dart';
import 'exam_taking_screen.dart';
import 'my_exams_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

class PublishedExamsScreen extends StatelessWidget {
  const PublishedExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          CurvedHeader(
            title: 'الاختبارات',
            subtitle: 'اختبر معلوماتك وتحقق من مستواك',
            gradient: AppTheme.brandGradient,
            trailing: IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyExamsScreen())),
            ),
          ),
          Expanded(child: _buildExamsList(isDark)),
        ],
      ),
    );
  }

  Widget _buildExamsList(bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where('kind', isEqualTo: 'quiz')
          .where('status', isEqualTo: 'published')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('تعذر تحميل الاختبارات: ${snapshot.error}',
                style: GoogleFonts.cairo(color: Colors.red)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs
          ..sort((a, b) => ((a.data()['order'] ?? 0) as num)
              .compareTo((b.data()['order'] ?? 0) as num));

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined,
                    size: 72,
                    color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 16),
                Text(
                  'لا توجد اختبارات منشورة حالياً',
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final quizId = docs[index].id;
            return _ExamCard(
              data: data,
              quizId: quizId,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String quizId;
  final bool isDark;

  const _ExamCard({
    required this.data,
    required this.quizId,
    required this.isDark,
  });

  Color get _difficultyColor {
    switch (data['difficulty']?.toString()) {
      case 'سهل':
        return const Color(0xFF10B981);
      case 'صعب':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'اختبار';
    final subject = data['subject']?.toString() ?? '';
    final difficulty = data['difficulty']?.toString() ?? 'متوسط';
    final totalQ = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final duration = (data['duration'] as num?)?.toInt() ?? 0;
    final description = data['description']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _openExam(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top color bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.quiz_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            if (subject.isNotEmpty)
                              Text(
                                subject,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.help_outline_rounded,
                        label: '$totalQ سؤال',
                        color: const Color(0xFF6366F1),
                      ),
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: '$duration دقيقة',
                        color: const Color(0xFF0EA5E9),
                      ),
                      _InfoChip(
                        icon: Icons.bar_chart_rounded,
                        label: difficulty,
                        color: _difficultyColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openExam(context),
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white),
                      label: Text(
                        'ابدأ الاختبار',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Future<void> _openExam(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .orderBy('order')
          .get();

      final questions = snapshot.docs
          .map((doc) => QuizQuestion.fromMap(doc.data(), doc.id))
          .where((q) =>
              q.question.trim().isNotEmpty && q.options.length >= 2)
          .toList();

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الاختبار لا يحتوي على أسئلة مكتملة'),
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamTakingScreen(
            quizId: quizId,
            quizTitle: data['title']?.toString() ?? 'اختبار',
            durationMinutes:
                ((data['duration'] as num?)?.toInt() ?? 30),
            questions: questions,
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الاختبار: $error')),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

