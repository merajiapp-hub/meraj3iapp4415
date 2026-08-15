import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _selectedPeriodIndex = 0; // 0=أسبوعي، 1=شهري، 2=سنوي

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = Provider.of<StatisticsProvider>(context);

    // تحديث البيانات العامة إذا لزم الأمر
    final favCount = stats.userFavoriteBooks;
    final dlCount = stats.userDownloadedBooks;
    final readCount = stats.userReadBooks;
    final tasksCount = stats.userCompletedTasks;
    final totalBooks = stats.totalBooks > 0 ? stats.totalBooks : 400;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          CurvedHeader(
            title: 'الإحصائيات',
            subtitle: 'تتبع نشاطك ومراجعاتك',
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF8B5CF6)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    // ─── بطاقات الإحصائيات ──────────────────────────────────────
                    _buildStatsGrid(isDark, favCount, dlCount, readCount, tasksCount, totalBooks),
                    const SizedBox(height: 24),

                    // ─── مؤشرات النشاط ──────────────────────────────────────────
                    _buildActivityChart(isDark),
                    const SizedBox(height: 24),

                    // ─── الرسم البياني الدائري ───────────────────────────────────
                    _buildPieChart(isDark, favCount, dlCount, totalBooks),
                    const SizedBox(height: 24),

                    // ─── شريط الفترة الزمنية ─────────────────────────────────────
                    _buildPeriodSelector(isDark),
                    const SizedBox(height: 16),

                    // ─── الرسم البياني الخطي ─────────────────────────────────────
                    _buildLineChart(isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── شبكة الإحصائيات ───────────────────────────────────────────────────────
  Widget _buildStatsGrid(bool isDark, int favCount, int dlCount, int readCount, int tasksCount, int totalBooks) {
    final statsList = [
      _StatItem(
        label: 'الكتب المقروءة',
        value: '$readCount',
        icon: Icons.menu_book_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
      ),
      _StatItem(
        label: 'المهام المنجزة',
        value: '$tasksCount',
        icon: Icons.task_alt_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
      ),
      _StatItem(
        label: 'المفضلة',
        value: '$favCount',
        icon: Icons.favorite_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
        ),
      ),
      _StatItem(
        label: 'الكتب المتاحة',
        value: '$totalBooks',
        icon: Icons.library_books_rounded,
        gradient: AppTheme.primaryGradient,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: statsList.map((s) => _buildStatCard(s, isDark)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.value,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        item.label,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── الرسم البياني العمودي ──────────────────────────────────────────────────
  Widget _buildActivityChart(bool isDark) {
    final isWeekly = _selectedPeriodIndex == 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWeekly ? 'النشاط الأسبوعي' : 'النشاط الشهري',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isWeekly ? 'عدد المهام والنشاطات هذا الأسبوع' : 'عدد المهام والنشاطات هذا الشهر',
            style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        AppTheme.primaryColor.withValues(alpha: 0.9),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                      getTitlesWidget: (value, meta) {
                        final days = ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[value.toInt() % 7],
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: isWeekly ? [
                  _buildBarGroup(0, 3),
                  _buildBarGroup(1, 7),
                  _buildBarGroup(2, 5),
                  _buildBarGroup(3, 9),
                  _buildBarGroup(4, 4),
                  _buildBarGroup(5, 8),
                  _buildBarGroup(6, 6),
                ] : [
                  _buildBarGroup(0, 15),
                  _buildBarGroup(1, 20),
                  _buildBarGroup(2, 10),
                  _buildBarGroup(3, 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 14,
          borderRadius: BorderRadius.circular(6),
          gradient: AppTheme.primaryGradient,
        ),
      ],
    );
  }

  // ─── الرسم البياني الدائري ──────────────────────────────────────────────────
  Widget _buildPieChart(bool isDark, int favCount, int dlCount, int totalBooks) {
    final total = (favCount + dlCount + totalBooks).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع المحتوى',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: totalBooks / total * 100,
                        color: AppTheme.primaryColor,
                        title: '${(totalBooks / total * 100).toInt()}%',
                        radius: 50,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: dlCount == 0 ? 1 : dlCount / total * 100,
                        color: const Color(0xFF10B981),
                        title: dlCount == 0
                            ? ''
                            : '${(dlCount / total * 100).toInt()}%',
                        radius: 50,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        value: favCount == 0 ? 1 : favCount / total * 100,
                        color: const Color(0xFFEF4444),
                        title: favCount == 0
                            ? ''
                            : '${(favCount / total * 100).toInt()}%',
                        radius: 50,
                        titleStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      'الكتب المتاحة',
                      AppTheme.primaryColor,
                      '$totalBooks',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'التنزيلات',
                      const Color(0xFF10B981),
                      '$dlCount',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'المفضلة',
                      const Color(0xFFEF4444),
                      '$favCount',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ─── اختيار الفترة ──────────────────────────────────────────────────────────
  Widget _buildPeriodSelector(bool isDark) {
    final periods = ['أسبوعي', 'شهري', 'سنوي'];
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(
          periods.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriodIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _selectedPeriodIndex == i
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  periods[i],
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedPeriodIndex == i
                        ? Colors.white
                        : Colors.grey[500],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── الرسم البياني الخطي ───────────────────────────────────────────────────
  Widget _buildLineChart(bool isDark) {
    final List<FlSpot> spots = _selectedPeriodIndex == 0
        ? [
            const FlSpot(0, 2),
            const FlSpot(1, 5),
            const FlSpot(2, 3),
            const FlSpot(3, 7),
            const FlSpot(4, 4),
            const FlSpot(5, 9),
            const FlSpot(6, 6),
          ]
        : _selectedPeriodIndex == 1
        ? [
            const FlSpot(0, 4),
            const FlSpot(1, 8),
            const FlSpot(2, 6),
            const FlSpot(3, 10),
            const FlSpot(4, 7),
          ]
        : [
            const FlSpot(0, 20),
            const FlSpot(1, 35),
            const FlSpot(2, 28),
            const FlSpot(3, 45),
            const FlSpot(4, 38),
            const FlSpot(5, 50),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تطور النشاط',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: AppTheme.primaryGradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.2),
                          AppTheme.primaryColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}
