import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/reading_provider.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();
    final reading = context.watch<ReadingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Map<int, double> hoursPerDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    for (final session in reading.sessions) {
      final diff = session.lastReadAt.difference(startOfWeek);
      if (diff.inDays >= 0 && diff.inDays < 7) {
        hoursPerDay[diff.inDays] = (hoursPerDay[diff.inDays] ?? 0) +
            session.readingTimeSeconds / 3600.0;
      }
    }
    final double maxHours =
        hoursPerDay.values.fold(0.0, (a, b) => a > b ? a : b);

    final int totalCorrect = stats.userCorrectAnswers;
    final int totalWrong = stats.userWrongAnswers;
    final int totalAnswers = totalCorrect + totalWrong;
    final double avgScore =
        totalAnswers > 0 ? (totalCorrect / totalAnswers * 20) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('تطور المستوى',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(stats, isDark),
            const SizedBox(height: 24),
            Text('نتائج الاختبارات',
                style: GoogleFonts.tajawal(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTestResultsCard(totalCorrect, totalWrong, avgScore, isDark),
            const SizedBox(height: 24),
            Text('ساعات القراءة (هذا الأسبوع)',
                style: GoogleFonts.tajawal(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStudyHoursChart(hoursPerDay, maxHours, isDark),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor(bool isDark) => BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _buildSummaryCard(StatisticsProvider stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(isDark),
      child: Column(
        children: [
          Text('إحصائياتي الكاملة',
              style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('المهام المنجزة', '${stats.userCompletedTasks}', isDark),
              _statItem('الكتب المقروءة', '${stats.userCompletedBooks}', isDark),
              _statItem('التقييم', '${stats.userAvgScore.toStringAsFixed(1)}%', isDark),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('صواب', '${stats.userCorrectAnswers}', isDark),
              _statItem('خطأ', '${stats.userWrongAnswers}', isDark),
              _statItem('وقت القراءة', stats.formattedReadingTime, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, bool isDark) {
    return Column(children: [
      Text(value,
          style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor)),
      Text(label,
          style: GoogleFonts.tajawal(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _buildTestResultsCard(
      int correct, int wrong, double avgScore, bool isDark) {
    final total = correct + wrong;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(isDark),
      child: total == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('لا توجد اختبارات بعد',
                      style: GoogleFonts.tajawal(
                          color: Colors.grey, fontSize: 16)),
                ]),
              ),
            )
          : Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _scoreTile('صحيح ✅', correct, Colors.green, isDark),
                  _scoreTile('خطأ ❌', wrong, Colors.red, isDark),
                  _scoreTile('المعدل 📊',
                      '${avgScore.toStringAsFixed(1)}/20',
                      AppTheme.primaryColor,
                      isDark),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: total > 0 ? correct / total : 0,
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'نسبة الإجابات الصحيحة: ${total > 0 ? (correct / total * 100).toStringAsFixed(1) : 0}%',
                style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13),
              ),
            ]),
    );
  }

  Widget _scoreTile(String label, dynamic value, Color color, bool isDark) {
    return Column(children: [
      Text('$value',
          style: GoogleFonts.outfit(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      Text(label,
          style: GoogleFonts.tajawal(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black54)),
    ]);
  }

  Widget _buildStudyHoursChart(
      Map<int, double> hoursPerDay, double maxHours, bool isDark) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(isDark),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxHours < 0.1 ? 2 : (maxHours * 1.3),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['أحد', 'اثن', 'ثلا', 'أرب', 'خمس', 'جمع', 'سبت'];
                  final idx = value.toInt();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(idx < days.length ? days[idx] : '',
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
              7, (i) => _makeBar(i, hoursPerDay[i] ?? 0.0, isDark)),
        ),
      ),
    );
  }

  BarChartGroupData _makeBar(int x, double y, bool isDark) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        color: y > 0
            ? AppTheme.primaryColor
            : AppTheme.primaryColor.withValues(alpha: 0.15),
        width: 16,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: 2,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
        ),
      ),
    ]);
  }
}
