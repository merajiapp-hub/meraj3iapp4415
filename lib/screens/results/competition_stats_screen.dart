import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/results_service.dart';
import '../../theme/app_theme.dart';
import 'school_stats_screen.dart';
import 'student_detail_screen.dart';

class CompetitionStatsScreen extends StatefulWidget {
  final String title;
  final List<StudentResult> allResults;
  final ExamType examType;
  final Gradient gradient;

  const CompetitionStatsScreen({
    super.key,
    required this.title,
    required this.allResults,
    required this.examType,
    required this.gradient,
  });

  @override
  State<CompetitionStatsScreen> createState() => _CompetitionStatsScreenState();
}

class _CompetitionStatsScreenState extends State<CompetitionStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _schoolSearchCtrl = TextEditingController();
  final TextEditingController _compSearchCtrl = TextEditingController();
  String _schoolSearchQuery = '';
  String _compSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final tabCount = widget.examType == ExamType.bac ? 4 : 3;
    _tabController = TabController(length: tabCount, vsync: this);
    _schoolSearchCtrl.addListener(() {
      setState(() => _schoolSearchQuery = _schoolSearchCtrl.text.trim().toLowerCase());
    });
    _compSearchCtrl.addListener(() {
      setState(() => _compSearchQuery = _compSearchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _schoolSearchCtrl.dispose();
    _compSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = (widget.gradient as LinearGradient).colors.first;

    // ─── الحسابات العامة ───
    final total = widget.allResults.length;
    final passed = widget.allResults.where((r) => r.isPassed).length;
    final failed = widget.allResults.where((r) => r.isFailed).length;
    final absent = widget.allResults.where((r) => r.isAbsent).length;
    final expelled = widget.allResults.where((r) => r.isExpelled).length;
    final complementary = widget.allResults.where((r) => r.isComplementary).length;

    final passRate = total > 0 ? (passed / total * 100) : 0.0;
    final failRate = total > 0 ? (failed / total * 100) : 0.0;
    final absentRate = total > 0 ? (absent / total * 100) : 0.0;
    final expelledRate = total > 0 ? (expelled / total * 100) : 0.0;
    final complementaryRate = total > 0 ? (complementary / total * 100) : 0.0;

    // أعلى نقطة/معدل
    double topScore = 0.0;
    for (final r in widget.allResults) {
      if (r.score != null && r.score! > topScore) {
        topScore = r.score!;
      }
    }

    final scoreLabel = widget.examType == ExamType.concours ? 'مجموع' : 'معدل';
    final maxScore = widget.examType == ExamType.concours ? 200.0 : 20.0;

    // ─── إحصائيات المدارس ───
    final Map<String, _SchoolData> schoolMap = {};
    for (final r in widget.allResults) {
      if (r.school.isEmpty) continue;
      schoolMap.putIfAbsent(r.school, () => _SchoolData(name: r.school, wilaya: r.wilaya));
      final sc = schoolMap[r.school]!;
      sc.total++;
      if (r.isPassed) sc.passed++;
      if (r.isFailed) sc.failed++;
      if (r.isAbsent) sc.absent++;
      if (r.isExpelled) sc.expelled++;
      if (r.isComplementary) sc.complementary++;
      if (r.score != null && r.score! > sc.topScore) {
        sc.topScore = r.score!;
      }
    }

    final sortedSchools = schoolMap.values.toList()
      ..sort((a, b) {
        if (b.passRate != a.passRate) {
          return b.passRate.compareTo(a.passRate);
        }
        if (b.passed != a.passed) {
          return b.passed.compareTo(a.passed);
        }
        return b.topScore.compareTo(a.topScore);
      });

    // إسناد ترتيب المدارس
    for (int i = 0; i < sortedSchools.length; i++) {
      sortedSchools[i].rank = i + 1;
    }

    // ─── إحصائيات الولايات ───
    final Map<String, _WilayaData> wilayaMap = {};
    for (final r in widget.allResults) {
      if (r.wilaya.isEmpty) continue;
      wilayaMap.putIfAbsent(r.wilaya, () => _WilayaData(name: r.wilaya));
      final w = wilayaMap[r.wilaya]!;
      w.total++;
      if (r.isPassed) w.passed++;
      if (r.isFailed) w.failed++;
      if (r.isAbsent) w.absent++;
      if (r.isExpelled) w.expelled++;
      if (r.isComplementary) w.complementary++;
      if (r.score != null && r.score! > w.topScore) {
        w.topScore = r.score!;
      }
    }

    final sortedWilayas = wilayaMap.values.toList()
      ..sort((a, b) {
        if (b.passRate != a.passRate) {
          return b.passRate.compareTo(a.passRate);
        }
        return b.passed.compareTo(a.passed);
      });

    for (int i = 0; i < sortedWilayas.length; i++) {
      sortedWilayas[i].rank = i + 1;
    }

    // ─── الطلاب المؤهلون للدورة التكميلية (خاص بالبكالوريا العادية) ───
    final compStudents = widget.examType == ExamType.bac
        ? widget.allResults.where((r) => r.isComplementary).toList()
        : <StudentResult>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إحصائيات ${widget.title}',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: widget.gradient)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
          isScrollable: true,
          tabs: [
            const Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'نظرة عامة'),
            const Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'ترتيب المدارس'),
            const Tab(icon: Icon(Icons.map_rounded, size: 20), text: 'ترتيب الولايات'),
            if (widget.examType == ExamType.bac)
              const Tab(icon: Icon(Icons.refresh_rounded, size: 20), text: 'المؤهلون للتكميلية'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. نظرة عامة
          _buildOverviewTab(
            isDark: isDark,
            primaryColor: primaryColor,
            total: total,
            passed: passed,
            failed: failed,
            absent: absent,
            expelled: expelled,
            complementary: complementary,
            passRate: passRate,
            failRate: failRate,
            absentRate: absentRate,
            expelledRate: expelledRate,
            complementaryRate: complementaryRate,
            topScore: topScore,
            scoreLabel: scoreLabel,
            maxScore: maxScore,
          ),

          // 2. ترتيب وإحصائيات المدارس
          _buildSchoolsTab(
            isDark: isDark,
            primaryColor: primaryColor,
            schools: sortedSchools,
            scoreLabel: scoreLabel,
          ),

          // 3. ترتيب الولايات
          _buildWilayasTab(
            isDark: isDark,
            primaryColor: primaryColor,
            wilayas: sortedWilayas,
            scoreLabel: scoreLabel,
          ),

          // 4. الدورة التكميلية (للبكالوريا فقط)
          if (widget.examType == ExamType.bac)
            _buildComplementaryTab(
              isDark: isDark,
              primaryColor: primaryColor,
              compStudents: compStudents,
              totalBac: total,
              compRate: complementaryRate,
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 1: OVERVIEW
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab({
    required bool isDark,
    required Color primaryColor,
    required int total,
    required int passed,
    required int failed,
    required int absent,
    required int expelled,
    required int complementary,
    required double passRate,
    required double failRate,
    required double absentRate,
    required double expelledRate,
    required double complementaryRate,
    required double topScore,
    required String scoreLabel,
    required double maxScore,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // البطاقة الرئيسية لنسبة النجاح
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نسبة النجاح الإجمالية',
                          style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${passRate.toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total > 0 ? (passed / total) : 0,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$passed ناجح من أصل $total مترشح',
                      style: GoogleFonts.tajawal(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'أعلى $scoreLabel: ${topScore.toStringAsFixed(2)} / ${maxScore.toInt()}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // شبكة الإحصائيات التفصيلية
          Text(
            '📊 ملخص الحالات الدقيقة',
            style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: [
              _buildMetricCard(
                title: 'إجمالي المترشحين',
                value: '$total',
                percent: '100%',
                icon: Icons.people_alt_rounded,
                color: Colors.blue,
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'الناجحون',
                value: '$passed',
                percent: '${passRate.toStringAsFixed(1)}%',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF16A34A),
                isDark: isDark,
              ),
              _buildMetricCard(
                title: 'الراسبون',
                value: '$failed',
                percent: '${failRate.toStringAsFixed(1)}%',
                icon: Icons.cancel_rounded,
                color: Colors.red,
                isDark: isDark,
              ),
              if (absent > 0)
                _buildMetricCard(
                  title: 'الغائبون',
                  value: '$absent',
                  percent: '${absentRate.toStringAsFixed(1)}%',
                  icon: Icons.person_off_rounded,
                  color: Colors.grey,
                  isDark: isDark,
                ),
              if (widget.examType == ExamType.bac && complementary > 0)
                _buildMetricCard(
                  title: 'المؤهلون للتكميلية',
                  value: '$complementary',
                  percent: '${complementaryRate.toStringAsFixed(1)}%',
                  icon: Icons.refresh_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              if (expelled > 0)
                _buildMetricCard(
                  title: 'المطرودون',
                  value: '$expelled',
                  percent: '${expelledRate.toStringAsFixed(1)}%',
                  icon: Icons.block_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              _buildMetricCard(
                title: 'أعلى $scoreLabel',
                value: topScore.toStringAsFixed(2),
                percent: 'من ${maxScore.toInt()}',
                icon: Icons.star_rounded,
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // الرسم البياني الدائري
          Text(
            '🥧 التمثيل البياني للنتائج',
            style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 40,
                        sections: [
                          if (passed > 0)
                            PieChartSectionData(
                              color: const Color(0xFF16A34A),
                              value: passed.toDouble(),
                              title: '${passRate.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              radius: 35,
                            ),
                          if (failed > 0)
                            PieChartSectionData(
                              color: Colors.red,
                              value: failed.toDouble(),
                              title: '${failRate.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              radius: 35,
                            ),
                          if (widget.examType == ExamType.bac && complementary > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: complementary.toDouble(),
                              title: '${complementaryRate.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              radius: 35,
                            ),
                          if (absent > 0)
                            PieChartSectionData(
                              color: Colors.grey,
                              value: absent.toDouble(),
                              title: '${absentRate.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              radius: 30,
                            ),
                          if (expelled > 0)
                            PieChartSectionData(
                              color: Colors.purple,
                              value: expelled.toDouble(),
                              title: '${expelledRate.toStringAsFixed(0)}%',
                              titleStyle: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              radius: 30,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (passed > 0)
                        _buildLegendItem('ناجح ($passed)', const Color(0xFF16A34A), '${passRate.toStringAsFixed(1)}%'),
                      if (failed > 0)
                        _buildLegendItem('راسب ($failed)', Colors.red, '${failRate.toStringAsFixed(1)}%'),
                      if (widget.examType == ExamType.bac && complementary > 0)
                        _buildLegendItem('تكميلي ($complementary)', Colors.orange, '${complementaryRate.toStringAsFixed(1)}%'),
                      if (absent > 0)
                        _buildLegendItem('غائب ($absent)', Colors.grey, '${absentRate.toStringAsFixed(1)}%'),
                      if (expelled > 0)
                        _buildLegendItem('مطرود ($expelled)', Colors.purple, '${expelledRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String percent,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  percent,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.tajawal(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            percent,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 2: SCHOOLS RANKING & DETAILED STATS
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSchoolsTab({
    required bool isDark,
    required Color primaryColor,
    required List<_SchoolData> schools,
    required String scoreLabel,
  }) {
    final filtered = schools.where((s) {
      if (_schoolSearchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_schoolSearchQuery) ||
          s.wilaya.toLowerCase().contains(_schoolSearchQuery);
    }).toList();

    return Column(
      children: [
        // شريط البحث بين المدارس
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _schoolSearchCtrl,
              style: GoogleFonts.tajawal(),
              decoration: InputDecoration(
                hintText: 'ابحث عن مدرسة أو ولاية...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 20),
                suffixIcon: _schoolSearchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => _schoolSearchCtrl.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // عنوان وعدّاد المدارس
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            children: [
              Text(
                '🏫 إحصائيات وترتيب المدارس (${filtered.length})',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                'مرتبة حسب نسبة النجاح',
                style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),

        // قائمة المدارس
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد مدارس مطابقة للبحث.',
                    style: GoogleFonts.tajawal(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final school = filtered[index];
                    return _buildSchoolCard(
                      school: school,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      scoreLabel: scoreLabel,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSchoolCard({
    required _SchoolData school,
    required bool isDark,
    required Color primaryColor,
    required String scoreLabel,
  }) {
    final rankColor = school.rank == 1
        ? const Color(0xFFEAB308) // Gold
        : school.rank == 2
            ? const Color(0xFF94A3B8) // Silver
            : school.rank == 3
                ? const Color(0xFFB45309) // Bronze
                : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SchoolStatsScreen(
                  schoolName: school.name,
                  allResults: widget.allResults,
                  examType: widget.examType,
                  gradient: widget.gradient,
                  emoji: '🏫',
                  passScore: widget.examType == ExamType.concours ? 85.0 : 10.0,
                  maxScore: widget.examType == ExamType.concours ? 200.0 : 20.0,
                  scoreLabel: scoreLabel,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الرأس: الترتيب + اسم المدرسة + نسبة النجاح
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: rankColor.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '#${school.rank}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: rankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (school.wilaya.isNotEmpty)
                            Text(
                              school.wilaya,
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${school.passRate.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // تفاصيل المدرسة: مشاركين، ناجحين، راسبين، غائبين، أعلى معدل
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniBadge('المشاركين', '${school.total}', Colors.blue),
                    _buildMiniBadge('الناجحين', '${school.passed}', const Color(0xFF16A34A)),
                    _buildMiniBadge('الراسبين', '${school.failed}', Colors.red),
                    if (school.absent > 0)
                      _buildMiniBadge('الغائبين', '${school.absent}', Colors.grey),
                    if (widget.examType == ExamType.bac && school.complementary > 0)
                      _buildMiniBadge('تكميلي', '${school.complementary}', Colors.orange),
                    _buildMiniBadge('أعلى $scoreLabel', school.topScore.toStringAsFixed(2), const Color(0xFFD97706)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 3: WILAYAS RANKING
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildWilayasTab({
    required bool isDark,
    required Color primaryColor,
    required List<_WilayaData> wilayas,
    required String scoreLabel,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: wilayas.length,
      itemBuilder: (context, index) {
        final w = wilayas[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${w.rank}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
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
                      w.name,
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${w.passed} ناجح من أصل ${w.total} مترشح',
                      style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${w.passRate.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'أعلى $scoreLabel: ${w.topScore.toStringAsFixed(2)}',
                    style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 4: COMPLEMENTARY (BAC ONLY)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildComplementaryTab({
    required bool isDark,
    required Color primaryColor,
    required List<StudentResult> compStudents,
    required int totalBac,
    required double compRate,
  }) {
    final filtered = compStudents.where((s) {
      if (_compSearchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_compSearchQuery) ||
          s.id.toLowerCase().contains(_compSearchQuery) ||
          s.school.toLowerCase().contains(_compSearchQuery) ||
          s.wilaya.toLowerCase().contains(_compSearchQuery);
    }).toList();

    // توزيع حسب الولايات
    final Map<String, int> wilayaDist = {};
    for (final s in compStudents) {
      if (s.wilaya.isEmpty) continue;
      wilayaDist[s.wilaya] = (wilayaDist[s.wilaya] ?? 0) + 1;
    }

    return Column(
      children: [
        // بطاقة ملخصة للمؤهلين للدورة التكميلية
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.orange, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الطلاب المؤهلون للدورة التكميلية',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${compStudents.length} طالب مؤهل (يمثلون ${compRate.toStringAsFixed(1)}% من إجمالي مترشحي البكالوريا)',
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // شريط البحث بين المؤهلين
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _compSearchCtrl,
              style: GoogleFonts.tajawal(),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم، الرقم، المدرسة، أو الولاية...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.orange, size: 20),
                suffixIcon: _compSearchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () => _compSearchCtrl.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // قائمة الطلاب المؤهلين
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    compStudents.isEmpty
                        ? 'لا يوجد طلاب مؤهلون للدورة التكميلية.'
                        : 'لا توجد نتائج مطابقة للبحث.',
                    style: GoogleFonts.tajawal(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(
                                student: student,
                                gradient: widget.gradient,
                                emoji: '🎓',
                                passScore: 10.0,
                                maxScore: 20.0,
                                scoreLabel: 'المعدل',
                                allResults: widget.allResults,
                                examType: widget.examType,
                                title: widget.title,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('🔄', style: TextStyle(fontSize: 16)),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    '${student.school.isNotEmpty ? student.school : ""} ${student.wilaya.isNotEmpty ? "• ${student.wilaya}" : ""}',
                                    style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (student.score != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    student.score!.toStringAsFixed(2),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  Text(
                                    'مؤهل للتكميلية',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 9,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SchoolData {
  final String name;
  final String wilaya;
  int rank = 0;
  int total = 0;
  int passed = 0;
  int failed = 0;
  int absent = 0;
  int expelled = 0;
  int complementary = 0;
  double topScore = 0.0;

  double get passRate => total > 0 ? (passed / total * 100) : 0.0;
  double get failRate => total > 0 ? (failed / total * 100) : 0.0;

  _SchoolData({required this.name, required this.wilaya});
}

class _WilayaData {
  final String name;
  int rank = 0;
  int total = 0;
  int passed = 0;
  int failed = 0;
  int absent = 0;
  int expelled = 0;
  int complementary = 0;
  double topScore = 0.0;

  double get passRate => total > 0 ? (passed / total * 100) : 0.0;

  _WilayaData({required this.name});
}
