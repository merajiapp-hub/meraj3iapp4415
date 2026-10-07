import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import '../data/exam_selection_utils.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

class MyExamsScreen extends StatelessWidget {
  const MyExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          const CurvedHeader(
            title: 'اختباراتي',
            gradient: AppTheme.brandGradient,
            leadingIcon: Icons.history_rounded,
          ),
          Expanded(
            child: uid == null
                ? _buildLoginRequired(isDark)
                : _buildAttemptsList(uid, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 72,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'يجب تسجيل الدخول أولاً',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsList(String uid, bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('exam_attempts')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 64,
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تعذر تحميل نتائج اختباراتك حالياً.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MyExamsScreen()),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aTime = _timestampMillis(a.data()['submittedAt']);
          final bTime = _timestampMillis(b.data()['submittedAt']);
          return bTime.compareTo(aTime);
        });
        if (docs.isEmpty) {
          return _buildEmpty(isDark);
        }

        // Summary stats
        final attempts = docs.map((d) => d.data()).toList();
        final completedAttempts =
            attempts.where((a) => a['status'] != 'in_progress').toList();
        final avgScore = completedAttempts.isEmpty
            ? 0
            : (completedAttempts.fold<int>(
                        0,
                        (acc, a) => acc + ((a['score'] as num?)?.toInt() ?? 0),
                      ) /
                      completedAttempts.length)
                  .round();
        final bestScore = completedAttempts.isEmpty
            ? 0
            : completedAttempts.fold<int>(
                0,
                (best, a) =>
                    ((a['score'] as num?)?.toInt() ?? 0) > best
                        ? (a['score'] as num).toInt()
                        : best,
              );
        final totalStars = attempts.fold<int>(
            0, (acc, a) => acc + ((a['stars'] as num?)?.toInt() ?? 0));

        final chartData = completedAttempts.reversed.toList();

        return Column(
          children: [
            // Summary Cards - بطاقات إحصائية عمودية
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: AppTheme.primaryColor,
                    value: '${attempts.length}',
                    label: 'إجمالي المحاولات',
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFF10B981),
                    value: '$avgScore%',
                    label: 'متوسط النتائج',
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    value: '$bestScore%',
                    label: 'أفضل نتيجة',
                    isDark: isDark,
                  ),
                  _StatCard(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    value: '$totalStars ⭐',
                    label: 'مجموع النجوم',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            
            // Chart Section
            if (chartData.length > 1)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                height: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التقدم الزمني',
                        style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 20,
                              getDrawingHorizontalLine: (value) => FlLine(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200,
                                    strokeWidth: 1,
                                  )),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (val, meta) => Text(
                                        '${val.toInt()}',
                                        style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.black54)))),
                            bottomTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: max(1, chartData.length - 1).toDouble(),
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartData.asMap().entries.map((e) {
                                final sc = (e.value['score'] as num?)?.toDouble() ?? 0;
                                return FlSpot(e.key.toDouble(), sc);
                              }).toList(),
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  return _buildAttemptCard(data, isDark);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  int _timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  Widget _buildAttemptCard(Map<String, dynamic> data, bool isDark) {
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toInt() ?? 0;
    final wrong = (data['wrongAnswers'] as num?)?.toInt() ?? 0;
    final total = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final timeSecs = (data['timeTakenSeconds'] as num?)?.toInt() ?? 0;
    final title = data['quizTitle']?.toString() ?? 'اختبار';
    final status = data['status']?.toString() ?? 'completed';
    final savedStars = (data['stars'] as num?)?.toInt() ?? 0;
    final stars = savedStars > 0 ? savedStars : _calcStars(score);
    final isInProgress = status == 'in_progress';

    final m = (timeSecs ~/ 60).toString().padLeft(2, '0');
    final s = (timeSecs % 60).toString().padLeft(2, '0');
    final timeStr = '$m:$s';

    final submittedAt = data['submittedAt'];
    String dateStr = '';
    if (submittedAt is Timestamp) {
      final dt = submittedAt.toDate();
      dateStr =
          '${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    Color scoreColor;
    if (score >= 80) {
      scoreColor = const Color(0xFF10B981);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B);
    } else {
      scoreColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isInProgress
                ? Colors.orange.withValues(alpha: 0.4)
                : scoreColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // دائرة النتيجة أو حالة التقدم
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isInProgress ? Colors.orange : scoreColor)
                  .withValues(alpha: 0.1),
              border: Border.all(
                  color: isInProgress ? Colors.orange : scoreColor, width: 2),
            ),
            child: Center(
              child: isInProgress
                  ? const Icon(Icons.pause_circle_outline_rounded,
                      color: Colors.orange, size: 26)
                  : Text(
                      '$score%',
                      style: GoogleFonts.outfit(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    if (isInProgress)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('قيد التقدم',
                            style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!isInProgress) ...[
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < stars ? Colors.amber : Colors.grey.shade400,
                        size: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    children: [
                      _MiniChip(label: '✓ $correct', color: const Color(0xFF10B981)),
                      _MiniChip(label: '✗ $wrong', color: const Color(0xFFEF4444)),
                      _MiniChip(label: 'من $total', color: const Color(0xFF6366F1)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 12,
                        color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 4),
                    Text(timeStr,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark ? Colors.white38 : Colors.black38)),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined, size: 11,
                          color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 3),
                      Text(dateStr,
                          style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calcStars(int score) =>
      ExamSelectionUtils.starsForScore(score);

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80,
              color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text('لم تخض أي اختبار بعد',
              style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 8),
          Text('ابدأ اختبارك الأول من صفحة الاختبارات',
              style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}



class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

