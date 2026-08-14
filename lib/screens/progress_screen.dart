import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/statistics_provider.dart';
import '../providers/task_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = Provider.of<StatisticsProvider>(context);
    final tasks = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate task completion rate
    final totalTasks = tasks.tasks.length;
    final completedTasks = tasks.tasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('تطور المستوى', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatCardsRow(stats, completionRate, isDark),
            const SizedBox(height: 32),
            Text(
              'نتائج الاختبارات السابقة',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChart(isDark),
            const SizedBox(height: 32),
            _buildComparisonCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCardsRow(StatisticsProvider stats, double completionRate, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'متوسط الدرجات',
            value: '${stats.userAvgScore.toStringAsFixed(1)}%',
            icon: Icons.score,
            color: Colors.blue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'إنجاز المهام',
            value: '${completionRate.toStringAsFixed(0)}%',
            icon: Icons.task_alt,
            color: Colors.green,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 50),
                FlSpot(1, 65),
                FlSpot(2, 60),
                FlSpot(3, 80),
                FlSpot(4, 75),
                FlSpot(5, 90),
              ],
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
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

  Widget _buildComparisonCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up, color: Colors.orange, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أداء ممتاز هذا الأسبوع!',
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'زاد معدل إنجازك للمهام بنسبة 15% مقارنة بالأسبوع الماضي.',
                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
