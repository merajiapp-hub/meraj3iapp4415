import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/results_service.dart';
import 'student_detail_screen.dart';

class WilayaStatsScreen extends StatefulWidget {
  final String wilayaName;
  final List<StudentResult> allResults;
  final ExamType examType;
  final Gradient gradient;
  final String emoji;
  final double passScore;
  final double maxScore;
  final String scoreLabel;

  const WilayaStatsScreen({
    super.key,
    required this.wilayaName,
    required this.allResults,
    required this.examType,
    required this.gradient,
    required this.emoji,
    required this.passScore,
    required this.maxScore,
    required this.scoreLabel,
  });

  @override
  State<WilayaStatsScreen> createState() => _WilayaStatsScreenState();
}

class _WilayaStatsScreenState extends State<WilayaStatsScreen> {
  late List<StudentResult> _wilayaStudents;
  late List<StudentResult> _filteredStudents;
  final TextEditingController _searchCtrl = TextEditingController();

  late int _total;
  late int _passed;
  late double _passRate;
  late double _topScore;
  late int _wilayaRank;
  late int _totalWilayas;

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
        _filteredStudents = _wilayaStudents;
      } else {
        _filteredStudents = _wilayaStudents.where((s) {
          return s.name.toLowerCase().contains(q) ||
              s.id.toLowerCase().contains(q) ||
              s.branch.toLowerCase().contains(q) ||
              s.school.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _calculateStats() {
    _wilayaStudents = widget.allResults
        .where((r) => r.wilaya == widget.wilayaName)
        .toList();
    _filteredStudents = _wilayaStudents;

    _total = _wilayaStudents.length;
    _passed = _wilayaStudents.where((s) => s.isPassed).length;

    _passRate = _total > 0 ? (_passed / _total * 100) : 0.0;

    _topScore = 0.0;
    for (final r in _wilayaStudents) {
      if (r.score != null && r.score! > _topScore) {
        _topScore = r.score!;
      }
    }

    final Map<String, _WilayaSummary> map = {};
    for (final r in widget.allResults) {
      if (r.wilaya.isEmpty) continue;
      map.putIfAbsent(r.wilaya, () => _WilayaSummary(name: r.wilaya));
      final s = map[r.wilaya]!;
      s.total++;
      if (r.isPassed) s.passed++;
    }

    final sorted = map.values.toList()
      ..sort((a, b) {
        if (b.passRate != a.passRate) return b.passRate.compareTo(a.passRate);
        return b.passed.compareTo(a.passed);
      });

    _totalWilayas = sorted.length;
    final idx = sorted.indexWhere((s) => s.name == widget.wilayaName);
    _wilayaRank = idx >= 0 ? idx + 1 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: widget.gradient),
                child: SafeArea(
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
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.wilayaName,
                                    style: GoogleFonts.tajawal(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'إحصائيات الولاية - ${widget.examType == ExamType.bac ? 'البكالوريا' : widget.examType == ExamType.brevet ? 'البيام' : 'السانكيام'}',
                                    style: GoogleFonts.tajawal(color: Colors.white70, fontSize: 13),
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
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(isDark),
                  const SizedBox(height: 24),
                  _buildSearchBox(isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final student = _filteredStudents[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _buildStudentCard(student, isDark),
                );
              },
              childCount: _filteredStudents.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('المرتبة وطنياً', '$_wilayaRank', 'من $_totalWilayas ولاية', Colors.amber, Icons.emoji_events_rounded, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('نسبة النجاح', '${_passRate.toStringAsFixed(2)}%', '$_passed ناجح', const Color(0xFF16A34A), Icons.percent_rounded, isDark)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('أعلى ${widget.scoreLabel}', _topScore.toStringAsFixed(2), 'من ${widget.maxScore.toInt()}', const Color(0xFF3B82F6), Icons.star_rounded, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('إجمالي المترشحين', '$_total', '', Colors.purple, Icons.people_alt_rounded, isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Colors.white : Colors.black87)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.tajawal(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'ابحث عن طالب في الولاية...',
          hintStyle: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentResult student, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        title: Text(student.name, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        subtitle: Text(student.school, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: student.isPassed ? const Color(0xFF16A34A).withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            student.score?.toStringAsFixed(2) ?? '-',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: student.isPassed ? const Color(0xFF16A34A) : Colors.red,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(
                student: student,
                examType: widget.examType,
                gradient: widget.gradient,
                emoji: widget.emoji,
                passScore: widget.passScore,
                maxScore: widget.maxScore,
                scoreLabel: widget.scoreLabel,
                allResults: widget.allResults,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WilayaSummary {
  final String name;
  int total = 0;
  int passed = 0;
  double get passRate => total > 0 ? (passed / total * 100) : 0.0;
  _WilayaSummary({required this.name});
}
