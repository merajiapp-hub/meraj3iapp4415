import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/results_service.dart';
import '../../services/school_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/top_students_section.dart';
import 'student_detail_screen.dart';

class SchoolStatsScreen extends StatefulWidget {
  final String schoolName;
  final List<StudentResult> allResults;
  final ExamType examType;
  final Gradient gradient;
  final String emoji;
  final double passScore;
  final double maxScore;
  final String scoreLabel;

  const SchoolStatsScreen({
    super.key,
    required this.schoolName,
    required this.allResults,
    required this.examType,
    required this.gradient,
    required this.emoji,
    required this.passScore,
    required this.maxScore,
    required this.scoreLabel,
  });

  @override
  State<SchoolStatsScreen> createState() => _SchoolStatsScreenState();
}

class _SchoolStatsScreenState extends State<SchoolStatsScreen> {
  late List<StudentResult> _schoolStudents;
  late List<StudentResult> _filteredStudents;
  final TextEditingController _searchCtrl = TextEditingController();

  late int _total;
  late int _passed;
  late int _failed;
  late int _absent;
  late int _expelled;
  late int _complementary;
  late double _passRate;
  late double _topScore;
  late int _schoolRank;
  late int _totalSchools;
  String _schoolWilaya = '';

  @override
  void initState() {
    super.initState();
    _calculateStats();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredStudents = _schoolStudents;
      } else {
        _filteredStudents = _schoolStudents.where((s) {
          return s.name.toLowerCase().contains(q) ||
              s.id.toLowerCase().contains(q) ||
              s.branch.toLowerCase().contains(q) ||
              s.status.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _calculateStats() {
    // 1. فلترة طلاب المدرسة
    _schoolStudents = widget.allResults
        .where((r) => r.school == widget.schoolName)
        .toList();
    _filteredStudents = _schoolStudents;

    if (_schoolStudents.isNotEmpty) {
      _schoolWilaya = _schoolStudents.first.wilaya;
    }

    // 2. الحسابات الدقيقة
    _total = _schoolStudents.length;
    _passed = _schoolStudents.where((r) => r.isPassed).length;
    _failed = _schoolStudents.where((r) => r.isFailed).length;
    _absent = _schoolStudents.where((r) => r.isAbsent).length;
    _expelled = _schoolStudents.where((r) => r.isExpelled).length;
    _complementary = _schoolStudents.where((r) => r.isComplementary).length;

    _passRate = _total > 0 ? (_passed / _total * 100) : 0.0;

    _topScore = 0.0;
    for (final r in _schoolStudents) {
      if (r.score != null && r.score! > _topScore) {
        _topScore = r.score!;
      }
    }

    // 3. حساب ترتيب المدرسة الوطني بناءً على نسبة النجاح
    final Map<String, _SchoolSummary> map = {};
    for (final r in widget.allResults) {
      if (r.school.isEmpty) continue;
      map.putIfAbsent(r.school, () => _SchoolSummary(name: r.school));
      final s = map[r.school]!;
      s.total++;
      if (r.isPassed) s.passed++;
    }

    final sorted = map.values.toList()
      ..sort((a, b) {
        if (b.passRate != a.passRate) return b.passRate.compareTo(a.passRate);
        return b.passed.compareTo(a.passed);
      });

    _totalSchools = sorted.length;
    final idx = sorted.indexWhere((s) => s.name == widget.schoolName);
    _schoolRank = idx >= 0 ? idx + 1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar جذاب مع تدرج وهندسة ناعمة
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: widget.gradient),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.schoolName,
                                        style: GoogleFonts.tajawal(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_schoolWilaya.isNotEmpty)
                                        Text(
                                          'ولاية $_schoolWilaya',
                                          style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // المحتوى الإحصائي
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة الترتيب ونسبة النجاح
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
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
                                    'الترتيب الوطني',
                                    style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '#$_schoolRank',
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'من أصل $_totalSchools مدرسة',
                                    style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
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
                                    'نسبة النجاح',
                                    style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  const Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 20),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_passRate.toStringAsFixed(1)}%',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // بطاقات تفصيلية للأعداد
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      _buildMetricTile('المشاركون', '$_total', Colors.blue, isDark),
                      _buildMetricTile('الناجحون', '$_passed', const Color(0xFF16A34A), isDark),
                      _buildMetricTile('الراسبون', '$_failed', Colors.red, isDark),
                      if (_absent > 0)
                        _buildMetricTile('الغائبون', '$_absent', Colors.grey, isDark),
                      if (widget.examType == ExamType.bac && _complementary > 0)
                        _buildMetricTile('تكميلي', '$_complementary', Colors.orange, isDark),
                      if (_expelled > 0)
                        _buildMetricTile('المطرودون', '$_expelled', Colors.purple, isDark),
                      _buildMetricTile(
                        'أعلى ${widget.scoreLabel}',
                        _topScore.toStringAsFixed(2),
                        const Color(0xFFD97706),
                        isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── أزرار تصدير PDF ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final passed = _schoolStudents.where((s) => s.isPassed).toList();
                            SchoolPdfService.generateAndShareList(
                              context: context,
                              students: passed,
                              listTitle: 'قائمة الناجحين',
                              schoolName: widget.schoolName,
                              competitionTitle: widget.examType.name.toUpperCase(),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFF16A34A)),
                          label: Text('قائمة الناجحين', style: GoogleFonts.tajawal(color: const Color(0xFF16A34A), fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final failed = _schoolStudents.where((s) => !s.isPassed && !s.isAbsent).toList();
                            SchoolPdfService.generateAndShareList(
                              context: context,
                              students: failed,
                              listTitle: 'قائمة الراسبين',
                              schoolName: widget.schoolName,
                              competitionTitle: widget.examType.name.toUpperCase(),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Colors.red),
                          label: Text('قائمة الراسبين', style: GoogleFonts.tajawal(color: Colors.red, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // أوائل المدرسة
                  if (_schoolStudents.isNotEmpty) ...[
                    TopStudentsSection(
                      students: _schoolStudents,
                      gradient: widget.gradient,
                      emoji: widget.emoji,
                      passScore: widget.passScore,
                      maxScore: widget.maxScore,
                      scoreLabel: widget.scoreLabel,
                      examType: widget.examType,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // شريط البحث بين طلاب المدرسة
                  Text(
                    'قائمة مترشحي المدرسة (${_filteredStudents.length})',
                    style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: GoogleFonts.tajawal(),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو الرقم أو الشعبة...',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => _searchCtrl.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // قائمة طلاب المدرسة
          if (_filteredStudents.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStudentTile(_filteredStudents[index], isDark),
                  childCount: _filteredStudents.length,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'لا توجد نتائج مطابقة للبحث.',
                    style: GoogleFonts.tajawal(color: Colors.grey),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTile(StudentResult student, bool isDark) {
    final statusColor = student.isPassed
        ? const Color(0xFF16A34A)
        : student.isAbsent
            ? Colors.grey
            : student.isExpelled
                ? Colors.purple
                : student.isComplementary
                    ? Colors.orange
                    : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentDetailScreen(
                  student: student,
                  gradient: widget.gradient,
                  emoji: widget.emoji,
                  passScore: widget.passScore,
                  maxScore: widget.maxScore,
                  scoreLabel: widget.scoreLabel,
                  allResults: widget.allResults,
                  examType: widget.examType,
                  title: widget.schoolName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student.isPassed ? '✓' : (student.isComplementary ? '🔄' : (student.isAbsent ? '?' : '✗')),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name.isNotEmpty ? student.name : 'مترشح رقم ${student.id}',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.branch.isNotEmpty)
                        Text(
                          student.branch,
                          style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (student.score != null)
                      Text(
                        student.score!.toStringAsFixed(2),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: statusColor,
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        student.status,
                        style: GoogleFonts.tajawal(
                          fontSize: 9,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SchoolSummary {
  final String name;
  int total = 0;
  int passed = 0;
  double get passRate => total > 0 ? (passed / total * 100) : 0.0;

  _SchoolSummary({required this.name});
}
