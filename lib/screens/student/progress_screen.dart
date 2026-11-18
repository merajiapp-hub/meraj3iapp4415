import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/reading_provider.dart';
import '../../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StatisticsProvider>().fetchUserStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatisticsProvider>();
    final reading = context.watch<ReadingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Map<int, double> hoursPerDay = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // الأحد = 0، الاثنين = 1 ...
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    for (final session in reading.sessions) {
      final sessionDay = DateTime(
        session.lastReadAt.year,
        session.lastReadAt.month,
        session.lastReadAt.day,
      );
      final diff = sessionDay.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        hoursPerDay[diff] = (hoursPerDay[diff] ?? 0) +
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
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<StatisticsProvider>().fetchUserStats();
        },
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              _statItem('الاختبارات', '${stats.userTestsTaken}', isDark),
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
    final double safeMaxY = (maxHours <= 0)
        ? 3.0
        : (maxHours * 1.3).ceilToDouble().clamp(3.0, 24.0);

    final double totalWeekHours =
        hoursPerDay.values.fold(0.0, (sum, val) => sum + val);
    final double dailyAvg = totalWeekHours / 7.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: _cardDecor(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── رأس البطاقة: الإجمالي والمتوسط اليومي ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي هذا الأسبوع',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        totalWeekHours.toStringAsFixed(1),
                        style: GoogleFonts.tajawal(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ساعة',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'المعدل: ${dailyAvg.toStringAsFixed(1)} س/يوم',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── رسم بياني محسّن بتدرجات جميلة وتسميات واضحة ───
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY: safeMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      const days = [
                        'الأحد',
                        'الإثنين',
                        'الثلاثاء',
                        'الأربعاء',
                        'الخميس',
                        'الجمعة',
                        'السبت'
                      ];
                      final dayName =
                          group.x.toInt() < days.length ? days[group.x.toInt()] : '';
                      final h = rod.toY;
                      final hoursInt = h.toInt();
                      final mins = ((h - hoursInt) * 60).round();
                      String timeStr = '${h.toStringAsFixed(1)} ساعة';
                      if (hoursInt > 0 && mins > 0) {
                        timeStr = '$hoursInt س و $mins د';
                      }
                      return BarTooltipItem(
                        '$dayName\n$timeStr',
                        GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        const days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            days[idx],
                            style: GoogleFonts.tajawal(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: safeMaxY > 6 ? 2.0 : 1.0,
                      getTitlesWidget: (val, meta) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          '${val.toInt()}س',
                          style: GoogleFonts.tajawal(
                            fontSize: 9.5,
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMaxY > 6 ? 2.0 : 1.0,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  7,
                  (i) => _makeBar(
                    i,
                    (hoursPerDay[i] ?? 0.0).clamp(0.0, safeMaxY),
                    safeMaxY,
                    isDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBar(int x, double y, double safeMaxY, bool isDark) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
        toY: y,
        gradient: y > 0
            ? const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF2DD4BF)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              )
            : null,
        color: y <= 0
            ? (isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0))
            : null,
        width: 18,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        backDrawRodData: BackgroundBarChartRodData(
          show: true,
          toY: safeMaxY,
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
        ),
      ),
    ]);
  }
}
