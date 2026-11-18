import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/schedule_item.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

/// الشاشة الذكية المتكاملة لـ «جدولي الدراسي»
class StudyScheduleScreen extends StatefulWidget {
  final bool embedded;
  const StudyScheduleScreen({super.key, this.embedded = false});

  @override
  State<StudyScheduleScreen> createState() => _StudyScheduleScreenState();
}

class _StudyScheduleScreenState extends State<StudyScheduleScreen>
    with SingleTickerProviderStateMixin {
  // ترتيب أيام الأسبوع المعتمد في المنظومة التعليمية:
  // السبت (6)، الأحد (7)، الاثنين (1)، الثلاثاء (2)، الأربعاء (3)، الخميس (4)، الجمعة (5)
  final List<int> _weekdaysOrder = [6, 7, 1, 2, 3, 4, 5];
  final List<String> _weekdayNames = [
    'السبت',
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة'
  ];

  late int _selectedDay;
  late final TabController _viewTabController;
  Timer? _countdownTimer;

  // المواد الشائعة للاختيار السريع
  static const List<(String, Color, String)> _commonSubjects = [
    ('الرياضيات', Color(0xFF2563EB), 'calculate'),
    ('الفيزياء والكيمياء', Color(0xFF7C3AED), 'science'),
    ('العلوم الطبيعية', Color(0xFF059669), 'eco'),
    ('الفلسفة', Color(0xFFD97706), 'psychology'),
    ('اللغة العربية', Color(0xFF0F766E), 'menu_book'),
    ('التربية الإسلامية', Color(0xFF047857), 'mosque'),
    ('اللغة الفرنسية', Color(0xFF4338CA), 'translate'),
    ('اللغة الإنجليزية', Color(0xFFB45309), 'language'),
    ('التاريخ والجغرافيا', Color(0xFFC026D3), 'public'),
    ('المعلوماتية', Color(0xFF0284C7), 'laptop'),
  ];

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 3, vsync: this);

    final today = DateTime.now().weekday;
    _selectedDay = _weekdaysOrder.contains(today) ? today : _weekdaysOrder[0];

    // مؤقت تحديث العداد التنازلي للحصة القادمة
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _viewTabController.dispose();
    super.dispose();
  }

  String _getDayName(int dayNum) {
    final idx = _weekdaysOrder.indexOf(dayNum);
    return idx != -1 ? _weekdayNames[idx] : 'اليوم';
  }

  void _goToToday() {
    final today = DateTime.now().weekday;
    setState(() {
      _selectedDay = _weekdaysOrder.contains(today) ? today : _weekdaysOrder[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFC);
    final schedule = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditSessionSheet(context, day: _selectedDay),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'إضافة حصة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ─── 1. الرأس المنحني وأزرار الإجراءات السريعة ───────────────
            _buildHeader(isDark, schedule),

            // ─── 2. شريط الإحصائيات الأربع ──────────────────────────────
            _buildStatsBar(isDark, schedule),

            // ─── 3. كرت الحصة القادمة والعد التنازلي ─────────────────────
            _buildNextSessionBanner(isDark, schedule),

            // ─── 4. شريط اختيار طريقة العرض ─────────────────────────────
            _buildViewTabBar(isDark),

            // ─── 5. المحتوى حسب طريقة العرض ─────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _viewTabController,
                children: [
                  // العرض اليومي (الصباح والمساء)
                  _buildDailyView(isDark, schedule),
                  // العرض الأسبوعي (شريط الأيام + الحصص)
                  _buildWeeklyView(isDark, schedule),
                  // عرض القائمة الشاملة
                  _buildListView(isDark, schedule),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. الرأس المنحني ──────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, ScheduleProvider schedule) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE، d MMMM yyyy', 'ar').format(today);

    return Stack(
      children: [
        CurvedHeader(
          title: 'جدولي الدراسي',
          subtitle: dateStr,
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 20),
                ),
                Row(
                  children: [
                    // زر وضع العطلة
                    IconButton(
                      tooltip: schedule.isVacationMode
                          ? 'إلغاء وضع العطلة'
                          : 'تفعيل وضع العطلة (إيقاف التنبيهات)',
                      onPressed: () async {
                        await schedule.toggleVacationMode();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                schedule.isVacationMode
                                    ? 'تم تفعيل وضع العطلة (تم إيقاف التنبيهات) 🌴'
                                    : 'تم استئناف التنبيهات الدراسية بنجاح 🔔',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        schedule.isVacationMode
                            ? Icons.beach_access_rounded
                            : Icons.notifications_active_rounded,
                        color: schedule.isVacationMode
                            ? const Color(0xFFFDE68A)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    // زر إدارة الواجبات
                    IconButton(
                      tooltip: 'الواجبات والمهام',
                      onPressed: () => _openTasksModal(context, schedule),
                      icon: const Icon(Icons.assignment_rounded,
                          color: Colors.white, size: 20),
                    ),
                    // زر تصدير الجدول
                    IconButton(
                      tooltip: 'نسخ أو تصدير الجدول',
                      onPressed: () => _showExportOptionsDialog(context, schedule),
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2. شريط الإحصائيات الأربع ─────────────────────────────────────────────
  Widget _buildStatsBar(bool isDark, ScheduleProvider schedule) {
    final todayCount = schedule.getTodaySessionsCount(_selectedDay);
    final todayHours = schedule.getTodayHours(_selectedDay);
    final totalCount = schedule.getTotalSessions();
    final reminders = schedule.getActiveRemindersCount();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          _buildStatCard(
            'حصص اليوم',
            '$todayCount',
            Icons.school_rounded,
            const Color(0xFF0F766E),
            isDark,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'ساعات الدراسة',
            todayHours.toStringAsFixed(1),
            Icons.schedule_rounded,
            const Color(0xFF2563EB),
            isDark,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'حصص الأسبوع',
            '$totalCount',
            Icons.date_range_rounded,
            const Color(0xFF7C3AED),
            isDark,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            'التذكيرات',
            schedule.isVacationMode ? 'عطلة' : '$reminders',
            Icons.notifications_active_rounded,
            schedule.isVacationMode
                ? const Color(0xFFD97706)
                : const Color(0xFF059669),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16202E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. كرت الحصة القادمة والعد التنازلي الذكي ──────────────────────────────
  Widget _buildNextSessionBanner(bool isDark, ScheduleProvider schedule) {
    final nextInfo = schedule.getNextUpcomingSession();

    if (nextInfo == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  size: 16, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'لا توجد حصص قادمة الآن لهذا اليوم، استمتع بوقتك! 🎉',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final item = nextInfo.$1!;
    final diffMinutes = nextInfo.$2;
    final isRunningNow = diffMinutes <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRunningNow
                ? [const Color(0xFF065F46), const Color(0xFF059669)]
                : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isRunningNow ? const Color(0xFF059669) : const Color(0xFF2563EB))
                  .withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRunningNow ? Icons.play_circle_fill_rounded : Icons.timer_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRunningNow
                        ? 'حصة جارية الآن: ${item.title}'
                        : 'الحصة القادمة: ${item.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.tajawal(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${item.startTime.format(context)} - ${item.endTime.format(context)} • ${item.isMorning ? "الفترة الصباحية" : "الفترة المسائية"}',
                    style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isRunningNow
                    ? 'جارية الآن 🟢'
                    : 'بعد $diffMinutes دقيقة ⏳',
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isRunningNow ? const Color(0xFF065F46) : const Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. شريط اختيار طريقة العرض ────────────────────────────────────────────
  Widget _buildViewTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _viewTabController,
        indicator: BoxDecoration(
          color: const Color(0xFF0F766E),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        labelStyle: GoogleFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'العرض اليومي (صباح/مساء)'),
          Tab(text: 'العرض الأسبوعي'),
          Tab(text: 'عرض القائمة'),
        ],
      ),
    );
  }

  // ─── 5. أ. العرض اليومي (مقسم إلى الصباح والمساء) ───────────────────────────
  Widget _buildDailyView(bool isDark, ScheduleProvider schedule) {
    final morningItems = schedule.getMorningItems(_selectedDay);
    final eveningItems = schedule.getEveningItems(_selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
      children: [
        // شريط اختيار اليوم السريع مع زر "اليوم"
        _buildDaySelectorHeader(isDark),

        const SizedBox(height: 10),

        // ☀️ الفترة الصباحية
        _buildPeriodSection(
          periodTitle: 'الفترة الصباحية',
          periodIcon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFF59E0B),
          items: morningItems,
          isDark: isDark,
          schedule: schedule,
          defaultPeriod: 'morning',
        ),

        const SizedBox(height: 14),

        // 🌙 الفترة المسائية
        _buildPeriodSection(
          periodTitle: 'الفترة المسائية',
          periodIcon: Icons.nights_stay_rounded,
          iconColor: const Color(0xFF6366F1),
          items: eveningItems,
          isDark: isDark,
          schedule: schedule,
          defaultPeriod: 'evening',
        ),
      ],
    );
  }

  Widget _buildPeriodSection({
    required String periodTitle,
    required IconData periodIcon,
    required Color iconColor,
    required List<ScheduleItem> items,
    required bool isDark,
    required ScheduleProvider schedule,
    required String defaultPeriod,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(periodIcon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                periodTitle,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${items.length} حصص',
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _openAddEditSessionSheet(
                  context,
                  day: _selectedDay,
                  defaultPeriod: defaultPeriod,
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 14, color: iconColor),
                      const SizedBox(width: 2),
                      Text(
                        'إضافة',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'لا توجد حصص مسجلة في هذا التوقيت',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ),
            )
          else
            ...items.map(
              (item) => _buildSessionCard(item, isDark, schedule),
            ),
        ],
      ),
    );
  }

  // ─── 5. ب. العرض الأسبوعي ──────────────────────────────────────────────────
  Widget _buildWeeklyView(bool isDark, ScheduleProvider schedule) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
      children: [
        _buildDaySelectorHeader(isDark),
        const SizedBox(height: 10),
        ..._weekdaysOrder.map((dayNum) {
          final items = schedule.getItemsForDay(dayNum);
          final isCurrent = dayNum == _selectedDay;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16202E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF0F766E)
                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getDayName(dayNum),
                          style: GoogleFonts.tajawal(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: isCurrent
                                ? const Color(0xFF0F766E)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        if (dayNum == DateTime.now().weekday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F766E),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'اليوم',
                              style: GoogleFonts.tajawal(
                                  fontSize: 9, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '${items.length} حصص',
                      style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Text(
                    'يوم راحة — لا توجد حصص',
                    style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                  )
                else
                  ...items.map(
                    (it) => _buildSessionCard(it, isDark, schedule, compact: true),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── 5. ج. عرض القائمة الشاملة ─────────────────────────────────────────────
  Widget _buildListView(bool isDark, ScheduleProvider schedule) {
    final allItems = <ScheduleItem>[];
    for (final day in _weekdaysOrder) {
      allItems.addAll(schedule.getItemsForDay(day));
    }

    if (allItems.isEmpty) {
      return Center(
        child: Text(
          'لم تتم إضافة أي حصص بعد في جدولك',
          style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        return _buildSessionCard(item, isDark, schedule, showDayBadge: true);
      },
    );
  }

  // ─── شريط الأيام السريع ─────────────────────────────────────────────────────
  Widget _buildDaySelectorHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _goToToday,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'اليوم',
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F766E),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _weekdaysOrder.map((dayNum) {
                  final isSelected = _selectedDay == dayNum;
                  final isRealToday = dayNum == DateTime.now().weekday;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getDayName(dayNum)),
                          if (isRealToday) ...[
                            const SizedBox(width: 3),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F766E),
                      backgroundColor: isDark
                          ? const Color(0xFF0F1722)
                          : const Color(0xFFF8FAFC),
                      labelStyle: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      onSelected: (_) => setState(() => _selectedDay = dayNum),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── بطاقة الحصة الدراسية الاحترافية ────────────────────────────────────────
  Widget _buildSessionCard(
    ScheduleItem item,
    bool isDark,
    ScheduleProvider schedule, {
    bool compact = false,
    bool showDayBadge = false,
  }) {
    final now = DateTime.now();
    final isToday = item.weekday == now.weekday;
    final currentMin = now.hour * 60 + now.minute;
    final startMin = item.startTime.hour * 60 + item.startTime.minute;
    final endMin = item.endTime.hour * 60 + item.endTime.minute;

    final isRunning = isToday && (currentMin >= startMin && currentMin < endMin);
    final isPassed = isToday && (currentMin >= endMin);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning
              ? const Color(0xFF10B981)
              : (item.isExam
                  ? const Color(0xFFDC2626)
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
          width: isRunning || item.isExam ? 1.5 : 1.0,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // شريط لوني جانبي
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // أيقونة المادة
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _resolveIcon(item.iconName),
                size: 20,
                color: item.color,
              ),
            ),
            const SizedBox(width: 10),
            // تفاصيل الحصة
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              decoration: item.isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isCancelled
                                  ? Colors.grey
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                        if (item.isExam) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'اختبار',
                              style: GoogleFonts.tajawal(
                                  fontSize: 8.5, color: Colors.white),
                            ),
                          ),
                        ],
                        if (showDayBadge) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• ${_getDayName(item.weekday)}',
                            style: GoogleFonts.tajawal(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                        const SizedBox(width: 3),
                        Text(
                          '${item.startTime.format(context)} - ${item.endTime.format(context)} (${item.formattedDuration})',
                          style: GoogleFonts.tajawal(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    if (item.teacher != null && item.teacher!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'الأستاذ: ${item.teacher}${item.room != null && item.room!.isNotEmpty ? " • ${item.room}" : ""}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                            fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // حالة الحصة والخيارات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  if (item.isCancelled)
                    _buildBadge('ملغاة', const Color(0xFFDC2626))
                  else if (isRunning)
                    _buildBadge('جارية الآن', const Color(0xFF10B981))
                  else if (isPassed)
                    _buildBadge('انتهت', Colors.grey)
                  else if (isToday)
                    _buildBadge('قادمة', const Color(0xFF2563EB)),

                  PopupMenuButton<String>(
                    tooltip: 'خيارات',
                    icon: Icon(Icons.more_vert_rounded,
                        size: 18, color: isDark ? Colors.white60 : Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    onSelected: (val) =>
                        _handleMenuAction(val, item, schedule, context),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('تعديل الحصة'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.content_copy_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('نسخ إلى يوم آخر'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'cancel_toggle',
                        child: Row(
                          children: [
                            Icon(item.isCancelled
                                ? Icons.restore_rounded
                                : Icons.block_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(item.isCancelled
                                ? 'إلغاء وضع الإلغاء'
                                : 'إلغاء الحصة مؤقتاً'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'exam_toggle',
                        child: Row(
                          children: [
                            const Icon(Icons.assignment_late_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(item.isExam
                                ? 'إلغاء وسم الاختبار'
                                : 'تحديد كموعد اختبار'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف الحصة', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  IconData _resolveIcon(String name) {
    switch (name) {
      case 'calculate':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'mosque':
        return Icons.auto_stories_rounded;
      case 'translate':
        return Icons.translate_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'laptop':
        return Icons.laptop_chromebook_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  // ─── إدارة إجراءات القائمة ─────────────────────────────────────────────────
  void _handleMenuAction(
    String action,
    ScheduleItem item,
    ScheduleProvider schedule,
    BuildContext context,
  ) async {
    switch (action) {
      case 'edit':
        _openAddEditSessionSheet(context, item: item, day: item.weekday);
        break;
      case 'copy':
        _showCopyDialog(context, item, schedule);
        break;
      case 'cancel_toggle':
        await schedule.toggleCancel(item);
        break;
      case 'exam_toggle':
        await schedule.toggleExam(item);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: Text('هل أنت متأكد من حذف حصة "${item.title}" من جدولك؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await schedule.removeItem(item);
        }
        break;
    }
  }

  // ─── نافذة نسخ الحصة إلى يوم آخر ───────────────────────────────────────────
  void _showCopyDialog(
    BuildContext context,
    ScheduleItem item,
    ScheduleProvider schedule,
  ) {
    int targetDay = item.weekday == 6 ? 7 : 6;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('نسخ حصة ${item.title}',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختر اليوم الذي تريد نسخ الحصة إليه بنفس التوقيت:',
                    style: GoogleFonts.tajawal(fontSize: 12.5)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: _weekdaysOrder.map((d) {
                    final isSelected = targetDay == d;
                    return ChoiceChip(
                      label: Text(_getDayName(d)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0F766E),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setDialogState(() => targetDay = d),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await schedule.copyToDay(item, targetDay);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'تم نسخ حصة "${item.title}" إلى ${_getDayName(targetDay)} بنجاح ✅'),
                      ),
                    );
                  }
                },
                child: const Text('تأكيد النسخ',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── نافذة إضافة وتعديل الحصة الدراسية ──────────────────────────────────────
  void _openAddEditSessionSheet(
    BuildContext context, {
    ScheduleItem? item,
    required int day,
    String? defaultPeriod,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditSessionModal(
        item: item,
        initialDay: day,
        defaultPeriod: defaultPeriod,
        weekdaysOrder: _weekdaysOrder,
        weekdayNames: _weekdayNames,
        commonSubjects: _commonSubjects,
      ),
    );
  }

  // ─── نافذة إدارة الواجبات والمهام ──────────────────────────────────────────
  void _openTasksModal(BuildContext context, ScheduleProvider schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TasksModalSheet(schedule: schedule),
    );
  }

  // ─── تصدير الجدول بصيغة نصية أو مشاركته ────────────────────────────────────
  void _showExportOptionsDialog(
    BuildContext context,
    ScheduleProvider schedule,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.share_rounded, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text('تصدير ومشاركة جدولي',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'يمكنك تصدير جدولك الأسبوعي كاملاً ومشاركته مع زملائك أو معلمينك بكل سهولة.',
            style: GoogleFonts.tajawal(fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E)),
              onPressed: () {
                Navigator.pop(ctx);
                _shareTextSchedule(schedule);
              },
              child: const Text('مشاركة كنص منسق',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _shareTextSchedule(ScheduleProvider schedule) {
    final buffer = StringBuffer();
    buffer.writeln('📚 جدولي الدراسي — تطبيق مراجعي');
    buffer.writeln('══════════════════════════════');

    for (final day in _weekdaysOrder) {
      final items = schedule.getItemsForDay(day);
      if (items.isEmpty) continue;

      buffer.writeln('\n🗓️ ${_getDayName(day)}:');
      for (final it in items) {
        final period = it.isMorning ? 'صباحاً' : 'مساءً';
        buffer.writeln(
            '  • ${it.title}: ${it.startTime.format(context)} - ${it.endTime.format(context)} ($period)');
        if (it.teacher != null && it.teacher!.isNotEmpty) {
          buffer.writeln('    الأستاذ: ${it.teacher}');
        }
      }
    }

    buffer.writeln('\n══════════════════════════════');
    buffer.writeln('تم إنشاؤه عبر تطبيق مراجعي MERAJ3I');

    Share.share(buffer.toString(), subject: 'جدولي الدراسي — مراجعي');
  }
}

// ─── نافذة إدخال وتعديل الحصة الدراسية ────────────────────────────────────────
class _AddEditSessionModal extends StatefulWidget {
  final ScheduleItem? item;
  final int initialDay;
  final String? defaultPeriod;
  final List<int> weekdaysOrder;
  final List<String> weekdayNames;
  final List<(String, Color, String)> commonSubjects;

  const _AddEditSessionModal({
    this.item,
    required this.initialDay,
    this.defaultPeriod,
    required this.weekdaysOrder,
    required this.weekdayNames,
    required this.commonSubjects,
  });

  @override
  State<_AddEditSessionModal> createState() => _AddEditSessionModalState();
}

class _AddEditSessionModalState extends State<_AddEditSessionModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _teacherCtrl;
  late final TextEditingController _roomCtrl;
  late final TextEditingController _notesCtrl;

  late int _selectedDay;
  late String _selectedPeriod;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late Color _selectedColor;
  late String _selectedIcon;
  late bool _notify;
  late int _notifyMinutes;
  int? _secondaryNotifyMinutes;
  late bool _isExam;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _titleCtrl = TextEditingController(text: it?.title ?? '');
    _teacherCtrl = TextEditingController(text: it?.teacher ?? '');
    _roomCtrl = TextEditingController(text: it?.room ?? '');
    _notesCtrl = TextEditingController(text: it?.description ?? '');

    _selectedDay = it?.weekday ?? widget.initialDay;
    _selectedPeriod = it?.period ?? widget.defaultPeriod ?? 'morning';

    _startTime = it?.startTime ??
        (_selectedPeriod == 'morning'
            ? const TimeOfDay(hour: 8, minute: 0)
            : const TimeOfDay(hour: 16, minute: 0));
    _endTime = it?.endTime ??
        (_selectedPeriod == 'morning'
            ? const TimeOfDay(hour: 10, minute: 0)
            : const TimeOfDay(hour: 18, minute: 0));

    _selectedColor = it?.color ?? const Color(0xFF0F766E);
    _selectedIcon = it?.iconName ?? 'menu_book';
    _notify = it?.notify ?? true;
    _notifyMinutes = it?.notifyMinutesBefore ?? 15;
    _secondaryNotifyMinutes = it?.secondaryNotifyMinutes;
    _isExam = it?.isExam ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // تعديل وقت النهاية تلقائياً ليكون بعد ساعتين إذا كان قبل أو يساوي وقت البداية
        final sMin = picked.hour * 60 + picked.minute;
        final eMin = _endTime.hour * 60 + _endTime.minute;
        if (eMin <= sMin) {
          final newEndMin = (sMin + 120) % (24 * 60);
          _endTime = TimeOfDay(hour: newEndMin ~/ 60, minute: newEndMin % 60);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      initialEntryMode: TimePickerEntryMode.dial,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveSession() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة أو اختيار اسم المادة')),
      );
      return;
    }

    final sMin = _startTime.hour * 60 + _startTime.minute;
    final eMin = _endTime.hour * 60 + _endTime.minute;
    if (eMin <= sMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب أن يكون وقت نهاية الحصة بعد وقت بدايتها!')),
      );
      return;
    }

    final schedule = context.read<ScheduleProvider>();
    final newItem = ScheduleItem(
      id: widget.item?.id ??
          'session_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: _notesCtrl.text.trim(),
      weekday: _selectedDay,
      startTime: _startTime,
      endTime: _endTime,
      color: _selectedColor,
      teacher: _teacherCtrl.text.trim().isEmpty ? null : _teacherCtrl.text.trim(),
      room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
      period: _selectedPeriod,
      iconName: _selectedIcon,
      isExam: _isExam,
      isCancelled: widget.item?.isCancelled ?? false,
      notify: _notify,
      notifyMinutesBefore: _notifyMinutes,
      secondaryNotifyMinutes: _secondaryNotifyMinutes,
    );

    // فحص تعارض التوقيت مع حصص أخرى في نفس اليوم
    final hasConflict =
        schedule.hasConflict(newItem, excludeId: widget.item?.id);
    if (hasConflict) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text('تنبيه: تعارض في التوقيت!'),
              ],
            ),
            content: const Text(
              'توجد حصة أخرى مسجلة مسبقاً في نفس هذا التوقيت أو يتداخل وقتها معه.\nهل تود حفظ هذه الحصة على أي حال؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('تعديل التوقيت'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم، حفظ مع التداخل',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

      if (proceed != true) return;
    }

    if (widget.item == null) {
      await schedule.addItem(newItem);
    } else {
      await schedule.updateItem(widget.item!, newItem);
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.item == null
            ? 'تمت إضافة الحصة بنجاح 📚'
            : 'تم تحديث بيانات الحصة بنجاح ✅'),
        backgroundColor: const Color(0xFF0F766E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض السحب العلوي
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.item == null ? 'إضافة حصة دراسية جديدة' : 'تعديل الحصة الدراسية',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // اختيار سريع من المواد الشائعة
              Text('اختيار سريع للمادة:',
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.grey)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.commonSubjects.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        avatar: Icon(Icons.circle, size: 10, color: s.$2),
                        label: Text(s.$1, style: GoogleFonts.tajawal(fontSize: 11)),
                        backgroundColor: isDark
                            ? const Color(0xFF0F1722)
                            : const Color(0xFFF1F5F9),
                        onPressed: () {
                          setState(() {
                            _titleCtrl.text = s.$1;
                            _selectedColor = s.$2;
                            _selectedIcon = s.$3;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // اسم المادة
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.tajawal(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'اسم المادة الدراسية *',
                  hintText: 'مثال: الرياضيات أو الفلسفة',
                  prefixIcon: Icon(Icons.menu_book_rounded,
                      color: _selectedColor, size: 20),
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // اليوم والفترة (صباح / مساء)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDay,
                      decoration: InputDecoration(
                        labelText: 'اليوم',
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      items: widget.weekdaysOrder.map((d) {
                        final idx = widget.weekdaysOrder.indexOf(d);
                        return DropdownMenuItem(
                          value: d,
                          child: Text(widget.weekdayNames[idx],
                              style: GoogleFonts.tajawal(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDay = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: InputDecoration(
                        labelText: 'الفترة',
                        prefixIcon: Icon(
                          _selectedPeriod == 'morning'
                              ? Icons.wb_sunny_rounded
                              : Icons.nights_stay_rounded,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'morning',
                          child: Text('الصباح ☀️'),
                        ),
                        DropdownMenuItem(
                          value: 'evening',
                          child: Text('المساء 🌙'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPeriod = val;
                            if (val == 'morning' && _startTime.hour >= 13) {
                              _startTime = const TimeOfDay(hour: 8, minute: 0);
                              _endTime = const TimeOfDay(hour: 10, minute: 0);
                            } else if (val == 'evening' && _startTime.hour < 13) {
                              _startTime = const TimeOfDay(hour: 16, minute: 0);
                              _endTime = const TimeOfDay(hour: 18, minute: 0);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // وقت البداية ووقت النهاية
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartTime,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('البداية:',
                                style: GoogleFonts.tajawal(fontSize: 11)),
                            Text(_startTime.format(context),
                                style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('النهاية:',
                                style: GoogleFonts.tajawal(fontSize: 11)),
                            Text(_endTime.format(context),
                                style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // الأستاذ والقاعة (اختياري)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _teacherCtrl,
                      style: GoogleFonts.tajawal(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'الأستاذ (اختياري)',
                        prefixIcon: const Icon(Icons.person_rounded, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _roomCtrl,
                      style: GoogleFonts.tajawal(fontSize: 12),
                      decoration: InputDecoration(
                        labelText: 'القاعة (اختياري)',
                        prefixIcon:
                            const Icon(Icons.meeting_room_rounded, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // إعدادات التنبيه والوقت
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded,
                                size: 18, color: Color(0xFF0F766E)),
                            const SizedBox(width: 6),
                            Text('تفعيل التذكير قبل الحصة',
                                style: GoogleFonts.tajawal(
                                    fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: _notify,
                          activeColor: const Color(0xFF0F766E),
                          onChanged: (val) => setState(() => _notify = val),
                        ),
                      ],
                    ),
                    if (_notify) ...[
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('التنبيه الأول قبل الحصة بـ:',
                              style: GoogleFonts.tajawal(fontSize: 11)),
                          DropdownButton<int>(
                            value: _notifyMinutes,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 5, child: Text('5 دقائق')),
                              DropdownMenuItem(value: 10, child: Text('10 دقائق')),
                              DropdownMenuItem(value: 15, child: Text('15 دقيقة')),
                              DropdownMenuItem(value: 30, child: Text('30 دقيقة')),
                              DropdownMenuItem(value: 60, child: Text('ساعة كاملة')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _notifyMinutes = val);
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('تنبيه ثانٍ إضافي (اختياري):',
                              style: GoogleFonts.tajawal(fontSize: 11)),
                          DropdownButton<int?>(
                            value: _secondaryNotifyMinutes,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: null, child: Text('بدون')),
                              DropdownMenuItem(value: 5, child: Text('قبل 5 دقائق')),
                              DropdownMenuItem(value: 10, child: Text('قبل 10 دقائق')),
                            ],
                            onChanged: (val) =>
                                setState(() => _secondaryNotifyMinutes = val),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // خيار وضع الاختبار
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('هذه الحصة موعد اختبار / امتحان',
                    style: GoogleFonts.tajawal(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text('تمييز الحصة بلون أحمر وإرسال تنبيه خاص',
                    style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey)),
                value: _isExam,
                activeColor: const Color(0xFFDC2626),
                onChanged: (val) => setState(() => _isExam = val ?? false),
              ),
              const SizedBox(height: 14),

              // زر الحفظ النهائي
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.item == null ? 'إضافة إلى الجدول' : 'تحديث الحصة',
                    style: GoogleFonts.tajawal(
                        fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── نافذة إدارة الواجبات والمهام الدراسية ────────────────────────────────────
class _TasksModalSheet extends StatefulWidget {
  final ScheduleProvider schedule;
  const _TasksModalSheet({required this.schedule});

  @override
  State<_TasksModalSheet> createState() => _TasksModalSheetState();
}

class _TasksModalSheetState extends State<_TasksModalSheet> {
  final _taskTitleCtrl = TextEditingController();
  final _taskSubjectCtrl = TextEditingController();

  @override
  void dispose() {
    _taskTitleCtrl.dispose();
    _taskSubjectCtrl.dispose();
    super.dispose();
  }

  void _addNewTask() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إضافة واجب / مهمة جديدة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الواجب أو التمرين',
                  hintText: 'مثال: حل تمارين الدالة الأسية ص 45',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _taskSubjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'المادة (اختياري)',
                  hintText: 'مثال: الرياضيات',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E)),
              onPressed: () async {
                final title = _taskTitleCtrl.text.trim();
                if (title.isEmpty) return;

                final task = ScheduleTask(
                  id: 'task_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  subjectName: _taskSubjectCtrl.text.trim().isEmpty
                      ? 'واجب عام'
                      : _taskSubjectCtrl.text.trim(),
                  dueDate: DateTime.now().add(const Duration(days: 1)),
                );
                await widget.schedule.addTask(task);
                _taskTitleCtrl.clear();
                _taskSubjectCtrl.clear();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = widget.schedule.tasks;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_rounded,
                        color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Text('الواجبات والمهام الدراسية',
                        style: GoogleFonts.tajawal(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _addNewTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('واجب جديد', style: GoogleFonts.tajawal(fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded,
                              size: 44, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text('لا توجد واجبات متراكمة! ممتاز جداً 👏',
                              style: GoogleFonts.tajawal(
                                  fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, idx) {
                        final t = tasks[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: t.isCompleted,
                            activeColor: const Color(0xFF10B981),
                            title: Text(
                              t.title,
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: t.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${t.subjectName} • حتى ${DateFormat('dd/MM').format(t.dueDate)}',
                              style: GoogleFonts.tajawal(fontSize: 10.5),
                            ),
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              onPressed: () => widget.schedule.deleteTask(t.id),
                            ),
                            onChanged: (_) => widget.schedule.toggleTask(t.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
