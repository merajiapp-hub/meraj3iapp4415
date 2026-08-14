import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<StatisticsProvider>(); // تحديث تلقائي عند تغيير الإحصائيات
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تطور المستوى',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyComparison(isDark),
            const SizedBox(height: 24),
            Text(
              'نتائج الاختبارات',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTestResultsChart(isDark),
            const SizedBox(height: 24),
            Text(
              'ساعات الدراسة (هذا الأسبوع)',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStudyHoursChart(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyComparison(bool isDark) {
    return Container(
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
      child: Column(
        children: [
          Text(
            'مقارنة بالأسبوع السابق',
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonItem('المهام', '12', '+3', true, isDark),
              _buildComparisonItem('الاختبارات', '5', '-1', false, isDark),
              _buildComparisonItem('المعدل', '15.5', '+0.5', true, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, String value, String diff, bool isPositive, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: isPositive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 2),
              Text(
                diff,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestResultsChart(bool isDark) {
    return Container(
      height: 250,
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
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(fontSize: 10, color: Colors.grey);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text('اختبار ${value.toInt()}', style: style),
                  );
                },
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 1,
          maxX: 5,
          minY: 0,
          maxY: 20,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(1, 12),
                FlSpot(2, 14.5),
                FlSpot(3, 13),
                FlSpot(4, 16),
                FlSpot(5, 15.5),
              ],
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyHoursChart(bool isDark) {
    return Container(
      height: 250,
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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      days[value.toInt()],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
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
          barGroups: [
            _makeBarData(0, 3, isDark),
            _makeBarData(1, 4.5, isDark),
            _makeBarData(2, 2, isDark),
            _makeBarData(3, 5, isDark),
            _makeBarData(4, 6, isDark),
            _makeBarData(5, 1, isDark),
            _makeBarData(6, 8, isDark),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarData(int x, double y, bool isDark) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.primaryColor,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }
}
