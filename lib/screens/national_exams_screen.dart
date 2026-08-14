import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../data/books_data.dart';
import '../models/book.dart';
import '../widgets/geometric_sliver_app_bar.dart';
import 'pdf_viewer_screen.dart';

class NationalExamsScreen extends StatelessWidget {
  const NationalExamsScreen({super.key});

  // لون حسب نوع المسابقة
  static Color _typeColor(String grade) {
    final g = grade.toLowerCase();
    if (g.contains('concours') || g.contains('ابتدائية')) {
      return const Color(0xFF14B8A6); // Teal
    }
    if (g.contains('brevet') || g.contains('إعدادية')) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (g.contains('bac') || g.contains('baccalauréat') || g.contains('ثانوية')) {
      return const Color(0xFF8B5CF6); // Purple
    }
    return AppTheme.primaryColor;
  }

  static LinearGradient _typeGradient(String grade) {
    final g = grade.toLowerCase();
    if (g.contains('concours') || g.contains('ابتدائية')) {
      return const LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    }
    if (g.contains('brevet') || g.contains('إعدادية')) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final exams = BooksData.allBooks
        .where((b) => b.section == BooksData.sCompetitions)
        .toList();

    final Map<String, Map<String, List<Book>>> ungrouped = {};
    for (final exam in exams) {
      ungrouped.putIfAbsent(exam.grade, () => {});
      ungrouped[exam.grade]!.putIfAbsent(exam.category, () => []).add(exam);
    }

    int getExamTypePriority(String g) {
      final lower = g.toLowerCase();
      if (lower.contains('concours')) return 1;
      if (lower.contains('brevet')) return 2;
      if (lower.contains('bac') || lower.contains('baccalauréat')) return 3;
      return 4;
    }

    int gradeYear(String g) {
      final match = RegExp(r'\d{4}').firstMatch(g);
      return match != null ? int.parse(match.group(0)!) : 0;
    }

    final sortedGrades = ungrouped.keys.toList()
      ..sort((a, b) {
        final typeA = getExamTypePriority(a);
        final typeB = getExamTypePriority(b);
        if (typeA != typeB) return typeA.compareTo(typeB);
        return gradeYear(a).compareTo(gradeYear(b));
      });

    final Map<String, Map<String, List<Book>>> grouped = {
      for (final grade in sortedGrades) grade: ungrouped[grade]!,
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          GeometricSliverAppBar(
            title: 'امتحانات المسابقات الوطنية',
            icon: Icons.emoji_events_rounded,
            gradient: AppTheme.goldGradient,
          ),

          if (exams.isEmpty)
            SliverFillRemaining(child: _buildLockedView(context))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── بانر رئيسي ──
                  _buildHeroBanner(context),
                  const SizedBox(height: 20),

                  // ── مجموعات المسابقات ──
                  ...grouped.entries.map((gradeEntry) {
                    final gradeName = _getGradeName(gradeEntry.key);
                    final categoriesMap = gradeEntry.value;
                    final color = _typeColor(gradeEntry.key);
                    final gradient = _typeGradient(gradeEntry.key);

                    return _GradeSection(
                      gradeName: gradeName,
                      categoriesMap: categoriesMap,
                      color: color,
                      gradient: gradient,
                      isDark: isDark,
                    );
                  }),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'امتحانات المسابقات الوطنية',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'كونكور  •  بريفية  •  باكالوريا',
                  style: GoogleFonts.tajawal(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGradeName(String grade) {
    switch (grade) {
      case 'الابتدائية':
        return '🏫 الابتدائية (Concours)';
      case 'الإعدادية':
        return '📚 الإعدادية (Brevet)';
      case 'الثانوية':
        return '🎓 الثانوية (Baccalauréat)';
      default:
        return grade;
    }
  }

  Widget _buildLockedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'امتحانات المسابقات غير متوفرة',
              style: GoogleFonts.tajawal(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'عذراً، لا توجد مسابقات حالياً.',
              style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
//  قسم مسابقة واحدة (Concours/Brevet/Bac)
// ══════════════════════════════════════
class _GradeSection extends StatelessWidget {
  final String gradeName;
  final Map<String, List<Book>> categoriesMap;
  final Color color;
  final LinearGradient gradient;
  final bool isDark;

  const _GradeSection({
    required this.gradeName,
    required this.categoriesMap,
    required this.color,
    required this.gradient,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── رأس النوع ──
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                gradeName,
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // ── قائمة السنوات داخل النوع ──
        ...categoriesMap.entries.map((categoryEntry) {
          final yearName = categoryEntry.key;
          final yearExams = categoryEntry.value;

          return _YearTile(
            yearName: yearName,
            yearExams: yearExams,
            color: color,
            isDark: isDark,
          );
        }),

        const SizedBox(height: 12),
      ],
    );
  }
}

// ══════════════════════════════════════
//  بلاطة السنة (ExpansionTile)
// ══════════════════════════════════════
class _YearTile extends StatefulWidget {
  final String yearName;
  final List<Book> yearExams;
  final Color color;
  final bool isDark;

  const _YearTile({
    required this.yearName,
    required this.yearExams,
    required this.color,
    required this.isDark,
  });

  @override
  State<_YearTile> createState() => _YearTileState();
}

class _YearTileState extends State<_YearTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? widget.color.withValues(alpha: 0.35)
              : (widget.isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFE2E8F0)),
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isExpanded
                ? widget.color.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: widget.isDark ? 0.15 : 0.04),
            blurRadius: _isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _isExpanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.color.withValues(
                  alpha: _isExpanded ? 0.18 : (widget.isDark ? 0.15 : 0.09)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              color: widget.color,
              size: 20,
            ),
          ),
          title: Text(
            widget.yearName,
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            '${widget.yearExams.length} امتحان',
            style: GoogleFonts.tajawal(
              fontSize: 10,
              color: widget.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: widget.color,
          collapsedIconColor:
              widget.isDark ? Colors.grey[400] : Colors.grey[500],
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          children: widget.yearExams.map((exam) {
            return _ExamTile(
                exam: exam, color: widget.color, isDark: widget.isDark);
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════
//  بطاقة الامتحان المفرد
// ══════════════════════════════════════
class _ExamTile extends StatelessWidget {
  final Book exam;
  final Color color;
  final bool isDark;

  const _ExamTile({
    required this.exam,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // أيقونة الامتحان
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.description_rounded, color: color, size: 17),
          ),
          const SizedBox(width: 10),

          // اسم الامتحان
          Expanded(
            child: Text(
              exam.title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // أزرار الإجراءات
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exam.url.isNotEmpty)
                _ExamButton(
                  label: 'عرض',
                  icon: Icons.visibility_rounded,
                  color: color,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        pdfUrl: exam.url,
                        title: exam.title,
                        stageName: 'امتحانات وطنية',
                        sectionName: exam.category,
                        book: exam,
                      ),
                    ),
                  ),
                ),
              if (exam.url.isNotEmpty && exam.solutionUrl.isNotEmpty)
                const SizedBox(width: 6),
              if (exam.solutionUrl.isNotEmpty)
                _ExamButton(
                  label: 'الحل',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF16A34A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        pdfUrl: exam.solutionUrl,
                        title: 'حل ${exam.title}',
                        stageName: 'حل',
                        sectionName: exam.category,
                        book: exam,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════
//  زر عرض/حل صغير
// ══════════════════════════════════════
class _ExamButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExamButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
