import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/schedule_item.dart';
import '../providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../utils/schedule_icon_helper.dart';

/// الشاشة الذكية المتطورة لـ «جدولي الدراسي» - تصميم Muraji'i Design System الاحترافي
class StudyScheduleScreen extends StatefulWidget {
  final bool embedded;
  const StudyScheduleScreen({super.key, this.embedded = false});

  @override
  State<StudyScheduleScreen> createState() => _StudyScheduleScreenState();
}

class _StudyScheduleScreenState extends State<StudyScheduleScreen>
    with SingleTickerProviderStateMixin {
  // ترتيب أيام الأسبوع المعتمد في المنظومة التعليمية
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

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 2, vsync: this);

    final today = DateTime.now().weekday;
    _selectedDay = _weekdaysOrder.contains(today) ? today : _weekdaysOrder[0];

    // مؤقت دوري حي (كل ثانية) لتحديث العد التنازلي الرقمي بدقة فائقة
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

  String _safeArabicDate(DateTime date) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName، ${date.day} $monthName';
  }

  int _getRemainingSessionsCount(int weekday, ScheduleProvider schedule) {
    final now = DateTime.now();
    final currentMin = now.hour * 60 + now.minute;
    final items = schedule.getItemsForDay(weekday);
    if (weekday != now.weekday) {
      return items.where((i) => !i.isCancelled).length;
    }
    return items.where((i) {
      if (i.isCancelled) return false;
      final endMin = i.endTime.hour * 60 + i.endTime.minute;
      return endMin > currentMin;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF7F9FB);
    final schedule = context.watch<ScheduleProvider>();

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditSessionSheet(context, day: _selectedDay),
        backgroundColor: const Color(0xFF1A146B),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'إضافة حصة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. شريط التطبيق العلوي الاحترافي المتناسق مع هوية مراجعي
              _buildTopAppBar(context, isDark, schedule),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // 2. ترويسة الصفحة (التاريخ، النص المحفز)
                    _buildHeaderBanner(isDark, schedule),

                    // 3. رادار الحصة القادمة أو الجارية الفخم والمختصر
                    _buildHeroNextSessionRadar(isDark, schedule),

                    // 4. بطاقات الإحصائيات الأربع الذكية (شبكة 2x2 متناسقة)
                    _buildStatsGrid(isDark, schedule),
                  ],
                ),
              ),
              // 5. شريط اختيار طريقة العرض الثابت والمثبت أثناء التمرير
              SliverPersistentHeader(
                pinned: true,
                delegate: _ScheduleTabBarDelegate(
                  child: Container(
                    color: bg,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildViewTabBar(isDark),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _viewTabController,
            physics: const NeverScrollableScrollPhysics(), // التنقل بالضغط فقط
            children: [
              // أ. الجدول الأسبوعي المدرسي الكامل
              _buildWeeklyTimetableView(isDark, schedule),
              // ب. عرض القائمة الشاملة
              _buildListView(isDark, schedule),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. شريط التطبيق العلوي الرسمي النظيف ──────────────────────────────────
  Widget _buildTopAppBar(BuildContext context, bool isDark, ScheduleProvider schedule) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF7F9FB),
      leading: IconButton(
        tooltip: 'رجوع',
        icon: Icon(
          Icons.arrow_forward_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A146B),
          size: 22,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      centerTitle: true,
      title: Text(
        'جدولي الدراسي',
        style: GoogleFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A146B),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'مشاركة الجدول',
          icon: Icon(
            Icons.share_rounded,
            size: 20,
            color: isDark ? Colors.white70 : const Color(0xFF1A146B),
          ),
          onPressed: () => _shareSchedule(schedule),
        ),
      ],
    );
  }

  // ─── 2. ترويسة الصفحة الأنيقة (بدون زر متكرر) ──────────────────────────────
  Widget _buildHeaderBanner(bool isDark, ScheduleProvider schedule) {
    final today = DateTime.now();
    final dateStr = _safeArabicDate(today);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'نظّم وقتك وتابع دراستك وكن مستعداً لحصتك القادمة 🌟',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF474651),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. رادار الحصة الجارية أو القادمة الخلاب والمختصر ─────────────────────
  Widget _buildHeroNextSessionRadar(bool isDark, ScheduleProvider schedule) {
    final nextInfo = schedule.getNextUpcomingSession();

    if (nextInfo == null) {
      final totalSessions = schedule.getTotalSessions();
      if (totalSessions == 0) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A146B), Color(0xFF312E81)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A146B).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ابدأ ببناء جدولك الدراسي',
                        style: GoogleFonts.tajawal(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'أضف أول حصة أو استورد قالباً جاهزاً بضغطة زر.',
                        style: GoogleFonts.tajawal(
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _promptSeedSchedule(schedule),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A146B),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'قالب جاهز ✨',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF006C4A).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF006C4A).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF006C4A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أكملت جميع حصص اليوم بنجاح! راحة موفقة ومراجعة هادئة 👏🌟',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF006C4A),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A146B), Color(0xFF312E81)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A146B).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF82F5C1).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF82F5C1).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF82F5C1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isRunningNow ? 'جارية الآن' : 'قادمة قريباً',
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF82F5C1),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.room != null && item.room!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item.room!,
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                _buildHeroCircleButton(
                  icon: item.notify
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_outlined,
                  onTap: () async {
                    final updated = item.copyWith(notify: !item.notify);
                    await schedule.updateItem(item, updated);
                  },
                ),
                const SizedBox(width: 6),
                _buildHeroCircleButton(
                  icon: Icons.edit_rounded,
                  onTap: () => _openAddEditSessionSheet(context, item: item, day: item.weekday),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${item.teacher != null && item.teacher!.isNotEmpty ? "${item.teacher!} • " : ""}${item.startTime.format(context)} - ${item.endTime.format(context)}',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildDigitalCountdown(
                      targetTime: item.startTime,
                      isRunning: isRunningNow,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showQuickPrepDialog(context, item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'تحضير المادة',
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

            // المعلم والوقت
            Text(
              '${item.teacher != null && item.teacher!.isNotEmpty ? "${item.teacher!} • " : ""}${item.startTime.format(context)} - ${item.endTime.format(context)}',
              style: GoogleFonts.tajawal(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),

            // السطر السفلي: العد التنازلي الرقمي وزر تحضير المادة
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRunningNow ? 'الحالة الحالية' : 'البدء خلال',
                      style: GoogleFonts.tajawal(
                        fontSize: 10.5,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildDigitalCountdown(
                      targetTime: item.startTime,
                      isRunning: isRunningNow,
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showQuickPrepDialog(context, item),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: Text(
                    'تحضير المادة',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C4A),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCircleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  // عداد رقمي حي (ساعة : دقيقة : ثانية)
  Widget _buildDigitalCountdown({required TimeOfDay targetTime, required bool isRunning}) {
    if (isRunning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF006C4A).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF82F5C1).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill_rounded, size: 14, color: Color(0xFF82F5C1)),
            const SizedBox(width: 6),
            Text(
              'الحصة جارية الآن في القاعة',
              style: GoogleFonts.tajawal(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF82F5C1),
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final target = DateTime(
      now.year,
      now.month,
      now.day,
      targetTime.hour,
      targetTime.minute,
    );
    var diff = target.difference(now);
    if (diff.isNegative) diff = Duration.zero;

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCountdownBox(hours),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _buildCountdownBox(minutes),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _buildCountdownBox(seconds),
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String val) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        val,
        style: GoogleFonts.tajawal(
          fontSize: 13.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  // ─── 4. بطاقات الإحصائيات الأربع (شبكة 2x2 متناسقة) ───────────────────────
  Widget _buildStatsGrid(bool isDark, ScheduleProvider schedule) {
    final todayCount = schedule.getTodaySessionsCount(_selectedDay);
    final todayHours = schedule.getTodayHours(_selectedDay);
    final remainingCount = _getRemainingSessionsCount(_selectedDay, schedule);
    final dueTasks = schedule.tasks.where((t) => !t.isCompleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  value: '$todayCount',
                  label: 'حصص اليوم',
                  icon: Icons.schedule_rounded,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF4F46E5),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModernStatCard(
                  value: '$remainingCount',
                  label: 'المتبقية',
                  icon: Icons.hourglass_top_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  value: '${todayHours.toStringAsFixed(1)} س',
                  label: 'ساعات الدراسة',
                  icon: Icons.timer_rounded,
                  iconBg: const Color(0xFFFFFBEB),
                  iconColor: const Color(0xFFD97706),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModernStatCard(
                  value: '$dueTasks',
                  label: 'واجبات مستحقة',
                  icon: Icons.assignment_outlined,
                  iconBg: const Color(0xFFFFF1F2),
                  iconColor: const Color(0xFFE11D48),
                  isDark: isDark,
                  onTap: () => _openTasksModal(context, schedule),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF191C1E),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 5. شريط اختيار طريقة العرض (الحبوب الأنيقة) ──────────────────────────
  Widget _buildViewTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _viewTabController,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: isDark ? Colors.white : const Color(0xFF1A146B),
        unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
        labelStyle: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'الجدول الأسبوعي'),
          Tab(text: 'عرض القائمة'),
        ],
      ),
    );
  }

  // ─── 6. أ. العرض اليومي (الصباح، المساء، المسار الزمني، المهام الدراسية) ────
  Widget _buildDailyView(bool isDark, ScheduleProvider schedule) {
    final morningItems = schedule.getMorningItems(_selectedDay);
    final eveningItems = schedule.getEveningItems(_selectedDay);
    final totalDayItems = morningItems.length + eveningItems.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
      children: [
        // أزرار اختيار أيام الأسبوع
        _buildDaySelectorHeader(isDark, schedule),

        const SizedBox(height: 12),

        if (totalDayItems == 0)
          _buildEmptyDayCard(isDark, schedule)
        else ...[
          // ☀️ الفترة الصباحية
          _buildPeriodTimelineSection(
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
          _buildPeriodTimelineSection(
            periodTitle: 'الفترة المسائية',
            periodIcon: Icons.nights_stay_rounded,
            iconColor: const Color(0xFF6366F1),
            items: eveningItems,
            isDark: isDark,
            schedule: schedule,
            defaultPeriod: 'evening',
          ),
        ],

        // مهامي الدراسية التفاعلية
        _buildStudyTasksSection(isDark, schedule),
      ],
    );
  }

  // بطاقة ترويسة الفترة مع المخطط الزمني المترابط
  Widget _buildPeriodTimelineSection({
    required String periodTitle,
    required IconData periodIcon,
    required Color iconColor,
    required List<ScheduleItem> items,
    required bool isDark,
    required ScheduleProvider schedule,
    required String defaultPeriod,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ترويسة الفترة
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Icon(periodIcon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                periodTitle,
                style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length} حصص',
                  style: GoogleFonts.tajawal(
                    fontSize: 10.5,
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
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: iconColor),
                      const SizedBox(width: 2),
                      Text(
                        'إضافة',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
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
        ),
        const SizedBox(height: 6),

        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
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
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Column(
              children: [
                _buildTimelineItem(
                  item: item,
                  isFirst: index == 0,
                  isLast: index == items.length - 1,
                  isDark: isDark,
                  schedule: schedule,
                ),
                if (index < items.length - 1)
                  _buildBreakIndicator(item, items[index + 1], isDark),
              ],
            );
          }),
      ],
    );
  }

  // عقدة المسار الزمني المتصل (Timeline Node) مع خط ونقطة حالة
  Widget _buildTimelineItem({
    required ScheduleItem item,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
    required ScheduleProvider schedule,
  }) {
    final now = DateTime.now();
    final isToday = item.weekday == now.weekday;
    final currentMin = now.hour * 60 + now.minute;
    final startMin = item.startTime.hour * 60 + item.startTime.minute;
    final endMin = item.endTime.hour * 60 + item.endTime.minute;

    final isRunning = isToday && (currentMin >= startMin && currentMin < endMin);
    final isPassed = item.isCompleted || (isToday && (currentMin >= endMin));
    final isUpcoming = isToday && (currentMin < startMin);

    final Color dotColor;
    final Color dotRingColor;
    final String statusText;
    final Color statusTextColor;
    final Color statusBgColor;

    if (item.isCancelled) {
      dotColor = const Color(0xFFDC2626);
      dotRingColor = Colors.transparent;
      statusText = 'ملغاة';
      statusTextColor = const Color(0xFFDC2626);
      statusBgColor = const Color(0xFFFEE2E2);
    } else if (isPassed) {
      dotColor = const Color(0xFF006C4A);
      dotRingColor = const Color(0xFF82F5C1);
      statusText = 'مكتملة';
      statusTextColor = const Color(0xFF006C4A);
      statusBgColor = const Color(0xFFECFDF5);
    } else if (isRunning) {
      dotColor = const Color(0xFF1A146B);
      dotRingColor = const Color(0xFF9C9AF4);
      statusText = 'جارية الآن';
      statusTextColor = const Color(0xFF1A146B);
      statusBgColor = const Color(0xFFEEF2FF);
    } else if (isUpcoming) {
      dotColor = const Color(0xFF3525CD);
      dotRingColor = const Color(0xFFC3C0FF);
      statusText = 'قادمة';
      statusTextColor = const Color(0xFF3525CD);
      statusBgColor = const Color(0xFFEEF2FF);
    } else {
      dotColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
      dotRingColor = Colors.transparent;
      statusText = 'مجدولة';
      statusTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
      statusBgColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عمود المسار الرأسي
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  flex: isFirst ? 0 : 1,
                  child: isFirst
                      ? const SizedBox(height: 18)
                      : Container(
                          width: 2,
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                ),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotRingColor, width: 2),
                    boxShadow: isRunning
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1A146B).withValues(alpha: 0.45),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : Container(
                          width: 2,
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // بطاقة الحصة
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildSessionCard(
                item: item,
                isDark: isDark,
                schedule: schedule,
                statusText: statusText,
                statusTextColor: statusTextColor,
                statusBgColor: statusBgColor,
                isRunning: isRunning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الحصة الدراسية بالتصميم المطور الفخم
  Widget _buildSessionCard({
    required ScheduleItem item,
    required bool isDark,
    required ScheduleProvider schedule,
    required String statusText,
    required Color statusTextColor,
    required Color statusBgColor,
    bool isRunning = false,
    bool compact = false,
    bool showDayBadge = false,
  }) {
    final safeColor = ScheduleIconHelper.getSafeColor(item.color, isDark: isDark);
    final iconData = ScheduleIconHelper.resolveIcon(item.iconName, item.title);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRunning
              ? const Color(0xFF1A146B)
              : (item.isExam
                  ? const Color(0xFFDC2626)
                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
          width: isRunning || item.isExam ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRunning
                ? const Color(0xFF1A146B).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: isRunning ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // أيقونة المادة بحاوية دائرية ناعمة (Squircle)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: safeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: safeColor.withValues(alpha: isDark ? 0.4 : 0.25),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Icon(iconData, size: 22, color: safeColor),
              ),
            ),
            const SizedBox(width: 12),

            // معلومات وتفاصيل الحصة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            decoration: item.isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isCancelled
                                ? Colors.grey
                                : (isDark ? Colors.white : const Color(0xFF191C1E)),
                          ),
                        ),
                      ),
                      if (item.isExam) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'امتحان 🔥',
                            style: GoogleFonts.tajawal(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      if (showDayBadge) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• ${_getDayName(item.weekday)}',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // الوقت والمدة
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 13, color: isDark ? Colors.white54 : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${item.startTime.format(context)} - ${item.endTime.format(context)}',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF474651),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${item.formattedDuration})',
                        style: GoogleFonts.tajawal(
                          fontSize: 10.5,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  if ((item.teacher != null && item.teacher!.isNotEmpty) ||
                      (item.room != null && item.room!.isNotEmpty)) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (item.teacher != null && item.teacher!.isNotEmpty) ...[
                          Text(
                            item.teacher!,
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                        if (item.teacher != null &&
                            item.teacher!.isNotEmpty &&
                            item.room != null &&
                            item.room!.isNotEmpty)
                          Text(' • ', style: TextStyle(color: Colors.grey[400])),
                        if (item.room != null && item.room!.isNotEmpty) ...[
                          Text(
                            item.room!,
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // شارة الحالة وزر الخيارات
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                PopupMenuButton<String>(
                  tooltip: 'خيارات الحصة',
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: isDark ? Colors.white60 : Colors.grey[600]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) => _handleMenuAction(val, item, schedule, context),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: Color(0xFF3525CD)),
                          SizedBox(width: 8),
                          Text('تعديل الحصة'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'complete_toggle',
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted ? Icons.undo_rounded : Icons.check_circle_rounded,
                            size: 16,
                            color: const Color(0xFF006C4A),
                          ),
                          const SizedBox(width: 8),
                          Text(item.isCompleted ? 'إلغاء وضع الاكتمال' : 'تمييز كمكتملة'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 8),
                          Text('نسخ إلى يوم آخر'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'exam_toggle',
                      child: Row(
                        children: [
                          const Icon(Icons.quiz_rounded, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Text(item.isExam ? 'إلغاء صفة الاختبار' : 'تعيين كاختبار'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'cancel_toggle',
                      child: Row(
                        children: [
                          const Icon(Icons.event_busy_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(item.isCancelled ? 'إلغاء تعليق الحصة' : 'تعليق / إلغاء مؤقت'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف الحصة', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // مؤشر الاستراحة الأنيق بين الحصص
  Widget _buildBreakIndicator(ScheduleItem current, ScheduleItem next, bool isDark) {
    final currentEndMin = current.endTime.hour * 60 + current.endTime.minute;
    final nextStartMin = next.startTime.hour * 60 + next.startTime.minute;
    final breakMinutes = nextStartMin - currentEndMin;

    if (breakMinutes <= 0 || breakMinutes > 180) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 1,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 8),
          Text(
            '☕ استراحة $breakMinutes دقيقة',
            style: GoogleFonts.tajawal(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 1,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }

  // ─── قسم مهامي الدراسية (Homework & Tasks) ─────────────────────────────────
  Widget _buildStudyTasksSection(bool isDark, ScheduleProvider schedule) {
    final tasks = schedule.tasks;

    return Container(
      margin: const EdgeInsets.only(top: 18, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مهامي الدراسية',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
              TextButton(
                onPressed: () => _openTasksModal(context, schedule),
                child: Text(
                  'عرض الكل (${tasks.length})',
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A146B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.task_alt_rounded, color: Color(0xFF006C4A), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'لا توجد مهام دراسية متأخرة، كل شيء منجز! 🎉',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF191C1E),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openTasksModal(context, schedule),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text(
                      'إضافة واجب',
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: const Color(0xFF006C4A),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...tasks.take(4).map((task) {
              final isUrgent = task.dueDate.difference(DateTime.now()).inHours < 24;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // شارة الأولوية
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUrgent ? 'عاجل' : 'قريب',
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUrgent
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // تفاصيل الواجب
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                  ? Colors.grey
                                  : (isDark ? Colors.white : const Color(0xFF191C1E)),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${task.subjectName} • ${_formatTaskDate(task.dueDate)}',
                            style: GoogleFonts.tajawal(
                              fontSize: 10.5,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // مربع الاختيار التفاعلي
                    InkWell(
                      onTap: () => schedule.toggleTask(task.id),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? const Color(0xFF006C4A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: task.isCompleted
                                ? const Color(0xFF006C4A)
                                : const Color(0xFFCBD5E1),
                            width: 1.8,
                          ),
                        ),
                        child: task.isCompleted
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                            : null,
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

  String _formatTaskDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    final diffDays = taskDay.difference(today).inDays;

    if (diffDays == 0) {
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'م' : 'ص';
      return 'مستحق اليوم، $hour:${date.minute.toString().padLeft(2, '0')} $period';
    } else if (diffDays == 1) {
      return 'مستحق غداً';
    } else {
      return 'مستحق: ${date.day}/${date.month}';
    }
  }

  // نافذة تحضير المادة السريع
  void _showQuickPrepDialog(BuildContext context, ScheduleItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF131B2A)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006C4A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Color(0xFF006C4A), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تحضير مادة: ${item.title}',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${item.startTime.format(context)} - ${item.endTime.format(context)} ${item.room != null ? "• ${item.room!}" : ""}',
                          style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'نصائح للتحضير السريع قبل الحصة:',
                style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPrepTip(Icons.check_circle_outline_rounded,
                  'مراجعة النقاط الرئيسية والملخصات للدرس السابق'),
              _buildPrepTip(Icons.edit_note_rounded,
                  'تجهيز الدفتر والقلم وأوراق العمل المطلوبة'),
              _buildPrepTip(Icons.help_outline_rounded,
                  'تدوين أي أسئلة أو نقاط غير واضحة لطرحها على الأستاذ'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(
                    'أنا جاهز ومستعد للحصة! 🌟',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006C4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrepTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF006C4A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.tajawal(fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة اليوم الفارغ
  Widget _buildEmptyDayCard(bool isDark, ScheduleProvider schedule) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A146B).withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded,
                size: 38, color: Color(0xFF1A146B)),
          ),
          const SizedBox(height: 14),
          Text(
            'لا توجد حصص مسجلة يوم ${_getDayName(_selectedDay)}',
            style: GoogleFonts.tajawal(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF191C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'يمكنك إضافة حصة دراسية جديدة لهذا اليوم أو توليد جدول مدرسي كامل بنقرة واحدة.',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _openAddEditSessionSheet(context, day: _selectedDay),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('إضافة حصة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A146B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _promptSeedSchedule(schedule),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text('جدول نموذجي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A146B),
                  side: const BorderSide(color: Color(0xFF1A146B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 6. ب. الجدول الأسبوعي المدرسي الشبكي ──────────────────────────────────
  Widget _buildWeeklyTimetableView(bool isDark, ScheduleProvider schedule) {
    final totalSessions = schedule.getTotalSessions();

    if (totalSessions == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmptyDayCard(isDark, schedule),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _promptSeedSchedule(schedule),
                icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 18),
                label: Text(
                  'استيراد جدول مدرسي افتراضي (موريتانيا)',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A146B),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final periods = [
      ('08:00 - 10:00', 'الحصة الأولى', 8, 10),
      ('10:00 - 12:00', 'الحصة الثانية', 10, 12),
      ('12:00 - 14:00', 'فترة الظهيرة', 12, 14),
      ('15:00 - 17:00', 'الحصة المسائية', 15, 17),
    ];

    final schoolDays = _weekdaysOrder;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A146B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grid_view_rounded, size: 20, color: Color(0xFF1A146B)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جدول الحصص الأسبوعي المدرسي',
                          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'إجمالي $totalSessions حصة موزعة على الأسبوع',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _openAddEditSessionSheet(context, day: _selectedDay),
                  icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF1A146B)),
                  label: Text(
                    'إضافة',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A146B),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF1A146B).withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // الجدول الشبكي
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 700),
                child: Column(
                  children: [
                    // صف رؤوس الأعمدة: الأيام
                    Container(
                      color: const Color(0xFF1A146B).withValues(alpha: isDark ? 0.25 : 0.1),
                      child: Row(
                        children: [
                          Container(
                            width: 110,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            alignment: Alignment.center,
                            child: Text(
                              'الفترة / اليوم',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1A146B),
                              ),
                            ),
                          ),
                          ...schoolDays.map((dayNum) {
                            final isRealToday = dayNum == DateTime.now().weekday;
                            return Container(
                              width: 120,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getDayName(dayNum),
                                    style: GoogleFonts.tajawal(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isRealToday
                                          ? const Color(0xFF1A146B)
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ),
                                  if (isRealToday)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A146B),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'اليوم',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // صفوف الفترات الزمنية
                    ...periods.map((period) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 110,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    period.$2,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    period.$1,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 9.5,
                                      color: isDark ? Colors.white38 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...schoolDays.map((dayNum) {
                              final daySessions = schedule.getItemsForDay(dayNum);
                              final sessionInSlot = daySessions.where((s) {
                                if (s.isCancelled) return false;
                                final startH = s.startTime.hour;
                                return startH >= period.$3 && startH < period.$4;
                              }).toList();

                              return Container(
                                width: 120,
                                constraints: const BoxConstraints(minHeight: 65),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: sessionInSlot.isEmpty
                                    ? InkWell(
                                        onTap: () => _openAddEditSessionSheet(context, day: dayNum),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Center(
                                          child: Icon(Icons.add_rounded,
                                              size: 16,
                                              color: isDark ? Colors.white12 : Colors.grey[300]),
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: sessionInSlot.map((s) {
                                          final safeCol = ScheduleIconHelper.getSafeColor(
                                              s.color,
                                              isDark: isDark);
                                          return InkWell(
                                            onTap: () => _openAddEditSessionSheet(
                                                context,
                                                item: s,
                                                day: dayNum),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(vertical: 2),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: safeCol.withValues(
                                                    alpha: isDark ? 0.25 : 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: safeCol.withValues(
                                                      alpha: isDark ? 0.45 : 0.3),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Text(
                                                    s.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.tajawal(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  if (s.room != null && s.room!.isNotEmpty)
                                                    Text(
                                                      s.room!,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.tajawal(
                                                        fontSize: 9,
                                                        color: isDark ? Colors.white60 : Colors.grey[700],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 6. ج. عرض القائمة الشاملة ─────────────────────────────────────────────
  Widget _buildListView(bool isDark, ScheduleProvider schedule) {
    final allItems = <ScheduleItem>[];
    for (final day in _weekdaysOrder) {
      allItems.addAll(schedule.getItemsForDay(day));
    }

    if (allItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildEmptyDayCard(isDark, schedule),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        return _buildSessionCard(
          item: item,
          isDark: isDark,
          schedule: schedule,
          statusText: _getDayName(item.weekday),
          statusTextColor: const Color(0xFF1A146B),
          statusBgColor: const Color(0xFFEEF2FF),
          showDayBadge: true,
        );
      },
    );
  }

  // ─── شريط الأيام السريع ────────────────────────────────────────────────────
  Widget _buildDaySelectorHeader(bool isDark, ScheduleProvider schedule) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _goToToday,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1A146B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'اليوم 🎯',
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A146B),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _weekdaysOrder.map((dayNum) {
                  final isSelected = _selectedDay == dayNum;
                  final isRealToday = dayNum == DateTime.now().weekday;
                  final daySessionsCount = schedule.getTodaySessionsCount(dayNum);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getDayName(dayNum)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (isDark ? Colors.white12 : Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$daySessionsCount',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
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
                      selectedColor: const Color(0xFF1A146B),
                      backgroundColor: isDark
                          ? const Color(0xFF0B111D)
                          : const Color(0xFFF1F5F9),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تم حذف حصة "${item.title}" بنجاح 🗑️')),
            );
          }
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
    int targetDay = item.weekday == 5 ? 6 : item.weekday + 1;
    if (targetDay > 7) targetDay = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  // ─── قائمة خيارات الجدول والقوالب ──────────────────────────────────────────
  void _showScheduleOptionsMenu(BuildContext context, ScheduleProvider schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF131B2A)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'خيارات وإعدادات الجدول',
                style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF0F766E)),
                ),
                title: Text('تعبئة جدول مدرسي نموذجي تلقائي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                subtitle: Text('إنشاء جدول أسبوعي كامل وموزع بذكاء على الحصص الصباحية والمسائية', style: GoogleFonts.tajawal(fontSize: 11)),
                onTap: () {
                  Navigator.pop(ctx);
                  _promptSeedSchedule(schedule);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                ),
                title: Text('مسح جميع حصص الجدول', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.red)),
                subtitle: Text('حذف كافة الحصص المسجلة والبدء من جديد', style: GoogleFonts.tajawal(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('تأكيد مسح الجدول'),
                      content: const Text('هل أنت متأكد من رغبتك في حذف كافة الحصص المسجلة في جدولك؟ لا يمكن التراجع عن هذا الإجراء.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('إلغاء')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('نعم، مسح الكل', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await schedule.clearAllSessions();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم مسح جميع الحصص بنجاح 🧹')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _promptSeedSchedule(ScheduleProvider schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF0F766E)),
            const SizedBox(width: 8),
            Text('جدول نموذجي متكامل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'سيقوم هذا الخيار بتهيئة جدول مدرسي أسبوعي متكامل يشمل أهم المواد (الرياضيات، العلوم، الفيزياء، العربية، الفرنسية، الإنجليزية، الفلسفة، الإسلامية، المعلوماتية) بتوقيت صباحي ومسائي منظم. يمكنك تعديله لاحقاً كما تشاء.\n\nهل تود المتابعة؟',
          style: GoogleFonts.tajawal(fontSize: 12.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تطبيق الجدول النموذجي', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await schedule.seedDefaultSchoolSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت تهيئة الجدول الدراسي النموذجي بنجاح! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.share_rounded, color: Color(0xFF0F766E)),
              const SizedBox(width: 8),
              Text('تصدير ومشاركة جدولي',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'يمكنك تصدير جدولك الأسبوعي كاملاً ومشاركته مع زملائك أو معلمينك بكل سهولة عبر واتساب أو نسخ النص.',
            style: GoogleFonts.tajawal(fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              onPressed: () {
                Navigator.pop(ctx);
                _shareTextSchedule(schedule);
              },
              child: const Text('مشاركة كنص منسق', style: TextStyle(color: Colors.white)),
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
        final period = it.isMorning ? 'صباحاً ☀️' : 'مساءً 🌙';
        buffer.writeln(
            '  • ${it.title}: ${it.startTime.format(context)} - ${it.endTime.format(context)} ($period)');
        if (it.teacher != null && it.teacher!.isNotEmpty) {
          buffer.writeln('    الأستاذ: ${it.teacher}');
        }
        if (it.room != null && it.room!.isNotEmpty) {
          buffer.writeln('    القاعة: ${it.room}');
        }
      }
    }

    buffer.writeln('\n══════════════════════════════');
    buffer.writeln('تم إنشاؤه عبر تطبيق مراجعي MERAJ3I');

    Share.share(buffer.toString(), subject: 'جدولي الدراسي — مراجعي');
  }
}

// ─── نافذة إدخال وتعديل الحصة الدراسية الاحترافية ────────────────────────────
class _AddEditSessionModal extends StatefulWidget {
  final ScheduleItem? item;
  final int initialDay;
  final String? defaultPeriod;
  final List<int> weekdaysOrder;
  final List<String> weekdayNames;

  const _AddEditSessionModal({
    this.item,
    required this.initialDay,
    this.defaultPeriod,
    required this.weekdaysOrder,
    required this.weekdayNames,
  });

  @override
  State<_AddEditSessionModal> createState() => _AddEditSessionModalState();
}

class _AddEditSessionModalState extends State<_AddEditSessionModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _teacherCtrl;
  late final TextEditingController _roomCtrl;

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

    _selectedDay = it?.weekday ?? widget.initialDay;
    _selectedPeriod = it?.period ?? widget.defaultPeriod ?? 'morning';

    if (it != null) {
      _startTime = it.startTime;
      _endTime = it.endTime;
      _selectedColor = ScheduleIconHelper.getSafeColor(it.color);
      _selectedIcon = it.iconName;
      _notify = it.notify;
      _notifyMinutes = it.notifyMinutesBefore;
      _secondaryNotifyMinutes = it.secondaryNotifyMinutes;
      _isExam = it.isExam;
    } else {
      if (_selectedPeriod == 'morning') {
        _startTime = const TimeOfDay(hour: 8, minute: 0);
        _endTime = const TimeOfDay(hour: 10, minute: 0);
      } else {
        _startTime = const TimeOfDay(hour: 16, minute: 0);
        _endTime = const TimeOfDay(hour: 18, minute: 0);
      }
      _selectedColor = const Color(0xFF0F766E);
      _selectedIcon = 'menu_book';
      _notify = true;
      _notifyMinutes = 15;
      _secondaryNotifyMinutes = null;
      _isExam = false;
    }

    // استماع لتغييرات العنوان للاقتراح التلقائي للون والأيقونة
    _titleCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    if (widget.item == null && _titleCtrl.text.isNotEmpty) {
      final suggestion = ScheduleIconHelper.suggestForTitle(_titleCtrl.text);
      if (suggestion.$2 != _selectedIcon && _selectedIcon == 'menu_book') {
        setState(() {
          _selectedColor = suggestion.$1;
          _selectedIcon = suggestion.$2;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // تعديل وقت النهاية تلقائياً ليكون بعد ساعتين إذا كان قبل البداية
        final startMin = picked.hour * 60 + picked.minute;
        final endMin = _endTime.hour * 60 + _endTime.minute;
        if (endMin <= startMin) {
          final newEndH = (picked.hour + 2) % 24;
          _endTime = TimeOfDay(hour: newEndH, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (ctx, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _openIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF131B2A)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر أيقونة المادة',
                style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: ScheduleIconHelper.availableIcons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, idx) {
                    final itemDef = ScheduleIconHelper.availableIcons[idx];
                    final isSelected = _selectedIcon == itemDef.key;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedIcon = itemDef.key);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _selectedColor : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(itemDef.icon,
                                size: 24,
                                color: isSelected ? _selectedColor : Colors.grey[700]),
                            const SizedBox(height: 4),
                            Text(
                              itemDef.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.tajawal(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF131B2A)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر لون المادة',
                style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ScheduleIconHelper.academicColors.map((col) {
                  final isSelected = _selectedColor == col;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedColor = col);
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: col.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 22)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveSession() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المادة الدراسية!')),
      );
      return;
    }

    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وقت نهاية الحصة يجب أن يكون بعد وقت البداية!')),
      );
      return;
    }

    final schedule = context.read<ScheduleProvider>();

    final newItem = ScheduleItem(
      id: widget.item?.id ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
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

    // فحص تعارض التوقيت
    if (schedule.hasConflict(newItem, excludeId: widget.item?.id)) {
      final override = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('تنبيه: تعارض في التوقيت!'),
            ],
          ),
          content: const Text(
            'توجد حصة أخرى مسجلة تتداخل مع هذا التوقيت في نفس اليوم. هل تريد إضافة الحصة على أي حال؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('تعديل التوقيت'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('متابعة الإضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (override != true) return;
    }

    if (widget.item == null) {
      await schedule.addItem(newItem);
    } else {
      await schedule.updateItem(widget.item!, newItem);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.item == null
              ? 'تمت إضافة حصة "$title" إلى جدولك بنجاح ✅'
              : 'تم تحديث بيانات الحصة بنجاح ✅'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 14,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض السحب
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.item == null ? 'إضافة حصة دراسية جديدة' : 'تعديل الحصة الدراسية',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  // استعراض حي للأيقونة واللون
                  Row(
                    children: [
                      InkWell(
                        onTap: _openColorPicker,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _openIconPicker,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _selectedColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _selectedColor),
                          ),
                          child: Icon(
                            ScheduleIconHelper.resolveIcon(_selectedIcon),
                            size: 18,
                            color: _selectedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // اختيار سريع من المواد الشائعة مع الأيقونات الحقيقية
              Text('اختيار سريع لمادة شائعة:',
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ScheduleIconHelper.commonTemplates.map((template) {
                    final isCurrent = _titleCtrl.text == template.title;

                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        avatar: Icon(template.icon, size: 14, color: template.color),
                        label: Text(
                          template.title,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? template.color : null,
                          ),
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF0B111D)
                            : const Color(0xFFF1F5F9),
                        onPressed: () {
                          setState(() {
                            _titleCtrl.text = template.title;
                            _selectedColor = template.color;
                            _selectedIcon = template.iconKey;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // اسم المادة
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'اسم المادة الدراسية *',
                  hintText: 'مثال: الرياضيات، الفيزياء، اللغة العربية...',
                  prefixIcon: Icon(
                    ScheduleIconHelper.resolveIcon(_selectedIcon, _titleCtrl.text),
                    color: _selectedColor,
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'تغيير الأيقونة واللون',
                    icon: const Icon(Icons.palette_outlined, size: 20),
                    onPressed: _openColorPicker,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // اليوم والفترة (صباح / مساء) - قوائم منسدلة احترافية وأنيقة
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDay,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: 'اليوم *',
                        labelStyle: GoogleFonts.tajawal(fontSize: 12),
                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF0F766E)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                        ),
                      ),
                      items: widget.weekdaysOrder.map((d) {
                        final idx = widget.weekdaysOrder.indexOf(d);
                        return DropdownMenuItem(
                          value: d,
                          child: Text(
                            widget.weekdayNames[idx],
                            style: GoogleFonts.tajawal(fontSize: 12.5),
                          ),
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
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        labelText: 'الفترة *',
                        labelStyle: GoogleFonts.tajawal(fontSize: 12),
                        prefixIcon: Icon(
                          _selectedPeriod == 'morning'
                              ? Icons.wb_sunny_rounded
                              : Icons.nights_stay_rounded,
                          size: 18,
                          color: _selectedPeriod == 'morning'
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF6366F1),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                        ),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('البداية:', style: GoogleFonts.tajawal(fontSize: 11.5)),
                            Text(_startTime.format(context),
                                style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('النهاية:', style: GoogleFonts.tajawal(fontSize: 11.5)),
                            Text(_endTime.format(context),
                                style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                      style: GoogleFonts.tajawal(fontSize: 12.5),
                      decoration: InputDecoration(
                        labelText: 'الأستاذ (اختياري)',
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _roomCtrl,
                      style: GoogleFonts.tajawal(fontSize: 12.5),
                      decoration: InputDecoration(
                        labelText: 'القاعة (اختياري)',
                        prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // إعدادات التنبيه والوقت
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B111D) : const Color(0xFFF8FAFC),
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
                              style: GoogleFonts.tajawal(fontSize: 11.5)),
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
                              style: GoogleFonts.tajawal(fontSize: 11.5)),
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
                        fontSize: 12.5, fontWeight: FontWeight.bold)),
                subtitle: Text('تمييز الحصة بلون أحمر بارز وإشعار خاص',
                    style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.item == null ? 'إضافة إلى الجدول' : 'تحديث الحصة',
                    style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w800),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('إضافة واجب أو مهمة دراسية',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskTitleCtrl,
                decoration: InputDecoration(
                  labelText: 'عنوان المهمة أو الواجب *',
                  hintText: 'مثال: حل تمارين المتتاليات ص 45',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _taskSubjectCtrl,
                decoration: InputDecoration(
                  labelText: 'المادة الدراسية',
                  hintText: 'مثال: الرياضيات',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                      ? 'مهمة عامة'
                      : _taskSubjectCtrl.text.trim(),
                  dueDate: DateTime.now().add(const Duration(days: 1)),
                );

                await widget.schedule.addTask(task);
                _taskTitleCtrl.clear();
                _taskSubjectCtrl.clear();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('إضافة المهمة',
                  style: TextStyle(color: Colors.white)),
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
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131B2A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_rounded, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Text(
                      'الواجبات والمهام الدراسية',
                      style: GoogleFonts.tajawal(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _addNewTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('واجب جديد', style: GoogleFonts.tajawal(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, size: 44, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد واجبات متراكمة! ممتاز جداً 👏',
                            style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (ctx, idx) {
                        final t = tasks[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
                            ),
                          ),
                          child: CheckboxListTile(
                            value: t.isCompleted,
                            activeColor: const Color(0xFF0F766E),
                            title: Text(
                              t.title,
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: t.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              t.subjectName,
                              style: GoogleFonts.tajawal(
                                  fontSize: 10.5, color: const Color(0xFF0F766E)),
                            ),
                            onChanged: (_) => widget.schedule.toggleTask(t.id),
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () => widget.schedule.deleteTask(t.id),
                            ),
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

// تفويض تثبيت شريط التبويب أعلى الصفحة بسلاسة
class _ScheduleTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _ScheduleTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 52.0;

  @override
  double get minExtent => 52.0;

  @override
  bool shouldRebuild(covariant _ScheduleTabBarDelegate oldDelegate) => true;
}
