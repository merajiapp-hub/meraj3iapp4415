import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/results_service.dart';
import '../screens/results/student_detail_screen.dart';

class TopStudentsSection extends StatelessWidget {
  final List<StudentResult> students;
  final Gradient gradient;
  final String emoji;
  final double passScore;
  final double maxScore;
  final String scoreLabel;
  final ExamType examType;

  const TopStudentsSection({
    super.key,
    required this.students,
    required this.gradient,
    required this.emoji,
    required this.passScore,
    required this.maxScore,
    required this.scoreLabel,
    required this.examType,
  });

  List<StudentResult> _getTop3() {
    if (students.isEmpty) return [];
    List<StudentResult> sorted;
    if (examType == ExamType.bac || examType == ExamType.complementary) {
      final withNational = students
          .where((r) => r.score != null)
          .toList()
        ..sort((a, b) {
          final na = int.tryParse(a.nationalRank) ?? 999999;
          final nb = int.tryParse(b.nationalRank) ?? 999999;
          return na.compareTo(nb);
        });
      sorted = withNational;
    } else {
      sorted = students.where((r) => r.score != null).toList()
        ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    }
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topStudents = _getTop3();
    if (topStudents.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                examType == ExamType.bac || examType == ExamType.complementary
                    ? 'الأوائل وطنياً'
                    : 'أوائل المسابقة',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (topStudents.isNotEmpty)
                  _buildTopStudentRow(context, topStudents[0], 1, isDark),
                if (topStudents.length > 1) ...[
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  _buildTopStudentRow(context, topStudents[1], 2, isDark),
                ],
                if (topStudents.length > 2) ...[
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                  _buildTopStudentRow(context, topStudents[2], 3, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStudentRow(BuildContext context, StudentResult student, int rank, bool isDark) {
    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? Colors.grey[400]!
            : const Color(0xFFCD7F32);

    final displayScore = student.score != null ? student.score!.toStringAsFixed(2) : '—';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailScreen(
              student: student,
              gradient: gradient,
              emoji: emoji,
              passScore: passScore,
              maxScore: maxScore,
              scoreLabel: scoreLabel,
              allResults: students,
              examType: examType,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rankColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: rankColor),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name.isNotEmpty ? student.name : 'مترشح رقم ${student.id}',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (student.school.isNotEmpty || student.wilaya.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      [if (student.school.isNotEmpty) student.school, if (student.wilaya.isNotEmpty) student.wilaya].join(' • '),
                      style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    displayScore,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: (gradient as LinearGradient).colors.first,
                    ),
                  ),
                  Text(
                    scoreLabel,
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.7),
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
}
