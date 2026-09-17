import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ReviewStatisticsScreen extends StatelessWidget {
  const ReviewStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('إحصائيات التقييمات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ', style: GoogleFonts.tajawal()));
          }

          final reviews = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == null || data['status'] == 'published';
          }).toList();
          if (reviews.isEmpty) {
            return Center(child: Text('لا توجد تقييمات لحساب الإحصائيات', style: GoogleFonts.tajawal(fontSize: 16)));
          }

          int total = reviews.length;
          double sum = 0;
          List<int> starCounts = [0, 0, 0, 0, 0];

          for (var doc in reviews) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
            sum += rating;
            int rounded = rating.round().clamp(1, 5);
            starCounts[rounded - 1]++;
          }

          double average = sum / total;

          final percentage = (average / 5 * 100).clamp(0, 100).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              children: [
                _buildAverageCard(average, total, isDark),
                const SizedBox(height: 14),
                _buildPercentageCard(percentage, isDark),
                const SizedBox(height: 14),
                _buildColumnChart(starCounts, total, isDark),
                const SizedBox(height: 14),
                _buildBarsCard(starCounts, total, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAverageCard(double average, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            average.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < average.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppTheme.secondaryColor,
                  size: 25,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'من إجمالي $total تقييم',
            style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageCard(double percentage, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 7,
                  backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5F0EC),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                Text(
                  '${percentage.round()}%',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نسبة الرضا العامة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('متوسط التقييم مقارنة بأعلى تقييم ممكن', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarsCard(List<int> starCounts, int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Text('توزيع التقييمات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 14),
          ...List.generate(5, (index) {
          int star = 5 - index;
          int count = starCounts[star - 1];
          double pct = total > 0 ? count / total : 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  '$star',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, color: AppTheme.secondaryColor, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text(
                    '$count',
                    style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _buildColumnChart(List<int> starCounts, int total, bool isDark) {
    final maxCount = starCounts.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الرسم البياني للتقييمات',
            textAlign: TextAlign.right,
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 178,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(5, (index) {
                final count = starCounts[index];
                final ratio = maxCount == 0 ? 0.0 : count / maxCount;
                final percentage = total == 0 ? 0 : (count / total * 100).round();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$percentage%',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 450),
                              width: double.infinity,
                              height: 18 + ratio * 92,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: index == 4
                                      ? [AppTheme.secondaryColor, const Color(0xFFF3D77B)]
                                      : [AppTheme.primaryColor, AppTheme.lightGreen],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(9),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.star_rounded, size: 14, color: AppTheme.secondaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.07),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.1),
      ),
    );
  }
}
