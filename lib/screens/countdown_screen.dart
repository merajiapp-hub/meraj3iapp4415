import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../services/countdown_service.dart';
import '../theme/app_theme.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  final _service = CountdownService();
  late final Stream<bool> _countdownEnabledStream;
  late final Stream<List<CountdownEvent>> _activeEventsStream;

  @override
  void initState() {
    super.initState();
    _countdownEnabledStream = _service.streamCountdownEnabled();
    _activeEventsStream = _service.streamActiveEvents();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'العدّ التنازلي',
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StreamBuilder<bool>(
          stream: _countdownEnabledStream,
          initialData: true,
          builder: (context, enabledSnap) {
            final isEnabled = enabledSnap.data ?? true;
            if (!isEnabled) {
              return _buildDisabledState(isDark);
            }

            return StreamBuilder<List<CountdownEvent>>(
              stream: _activeEventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data ?? [];
                if (events.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                final vacations =
                    events.where((e) => e.type == 'vacation').toList();
                final exams =
                    events.where((e) => e.type != 'vacation').toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: const Color(0xFF10B981),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // عنوان الصفحة الرئيسي
                      _buildPageHeading(
                        title: 'العدّ التنازلي للمواعيد',
                        subtitle: 'متابعة حية للمسابقات الوطنية والعطل المدرسية المعتمدة',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      if (exams.isNotEmpty) ...[
                        _buildSectionLabel(
                          title: 'المسابقات والامتحانات الوطنية',
                          icon: Icons.school_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        ...exams.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LiveCountdownCard(
                              key: ValueKey(e.id),
                              event: e,
                              isDark: isDark,
                              isVacation: false,
                            ),
                          ),
                        ),
                      ],

                      if (vacations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSectionLabel(
                          title: 'العطل المدرسية والإجازات الرسمية',
                          icon: Icons.beach_access_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        ...vacations.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LiveCountdownCard(
                              key: ValueKey(v.id),
                              event: v,
                              isDark: isDark,
                              isVacation: true,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPageHeading({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد مواعيد نشطة حالياً',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'سيتم إضافة مواعيد المسابقات الوطنية والعطل فور اعتمادها رسمياً من لوحة الإدارة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_off_rounded,
              size: 64,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            const SizedBox(height: 14),
            Text(
              'خدمة العد التنازلي غير مفعّلة حالياً',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── بطاقة العد التنازلي المدمجة الثابتة هندسياً بدون أي اهتزاز ───────────────
class _LiveCountdownCard extends StatefulWidget {
  final CountdownEvent event;
  final bool isDark;
  final bool isVacation;

  const _LiveCountdownCard({
    super.key,
    required this.event,
    required this.isDark,
    required this.isVacation,
  });

  @override
  State<_LiveCountdownCard> createState() => _LiveCountdownCardState();
}

class _LiveCountdownCardState extends State<_LiveCountdownCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // مؤقت محلي معزول بالكامل
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDark = widget.isDark;
    const accentGreen = Color(0xFF10B981);
    final cardBg = isDark ? const Color(0xFF131D2A) : Colors.white;

    final isDue = event.isDueToday;
    final isEnded = event.isEnded;
    final rem = event.remainingDuration;

    final days = rem.isNegative ? 0 : rem.inDays;
    final hours = rem.isNegative ? 0 : rem.inHours % 24;
    final minutes = rem.isNegative ? 0 : rem.inMinutes % 60;
    final seconds = rem.isNegative ? 0 : rem.inSeconds % 60;

    final dateFormatted = DateFormat('yyyy/MM/dd').format(event.targetDate);

    final headerBg = isDark
        ? const Color(0xFF162534)
        : (widget.isVacation
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFF0FDF4));

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2D40) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── 1. رأس البطاقة المدمج: العنوان + التاريخ + نقطة الحالة ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: headerBg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.tajawal(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateFormatted,
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDue
                        ? const Color(0xFFF59E0B)
                        : (isEnded ? Colors.grey : accentGreen),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDue
                                ? const Color(0xFFF59E0B)
                                : (isEnded ? Colors.grey : accentGreen))
                            .withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── 2. جسم البطاقة بحجم مصغر ثابت تماماً ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: isDue
                ? _buildDueMessage(event, accentGreen, isDark)
                : isEnded
                    ? _buildEndedMessage(event, accentGreen, isDark)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ── الجانب الأيسر: المؤشرات الدائرية (ساعات، دقائق، ثواني) ──
                          Expanded(
                            flex: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // عمود الساعات والدقائق الصغير
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSmallGauge(
                                      label: 'ساعات',
                                      valStr: hours.toString().padLeft(2, '0'),
                                      fraction: (hours % 24) / 24.0,
                                      fillColor: accentGreen,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSmallGauge(
                                      label: 'دقائق',
                                      valStr: minutes.toString().padLeft(2, '0'),
                                      fraction: (minutes % 60) / 60.0,
                                      fillColor: accentGreen,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),

                                // مؤشر الثواني الدائري
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildBigSecondsGauge(
                                      seconds: seconds,
                                      fillColor: accentGreen,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'ثواني',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // ── الجانب الأيمن: عدد الأيام المتبقية ──
                          Expanded(
                            flex: 4,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'متبقي',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  height: 32,
                                  child: Center(
                                    child: Text(
                                      '$days',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: accentGreen,
                                        height: 1.0,
                                        fontFeatures: const [
                                          ui.FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'أيام',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 58,
                                  height: 3.5,
                                  decoration: BoxDecoration(
                                    color: accentGreen.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (1.0 - (days / 365.0)).clamp(0.08, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: accentGreen,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // مؤشر دائري مصغر للثواني مع عزل إعادة الرسم RepaintBoundary
  Widget _buildBigSecondsGauge({
    required int seconds,
    required Color fillColor,
    required bool isDark,
  }) {
    final trackColor = isDark
        ? const Color(0xFF243242)
        : const Color(0xFFF1F5F9);

    return RepaintBoundary(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(
          painter: _PieGaugePainter(
            fraction: (seconds % 60) / 60.0,
            fillColor: fillColor,
            trackColor: trackColor,
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              child: Text(
                seconds.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // مؤشر دائري مصغر للساعات والدقائق
  Widget _buildSmallGauge({
    required String label,
    required String valStr,
    required double fraction,
    required Color fillColor,
    required bool isDark,
  }) {
    final trackColor = isDark
        ? const Color(0xFF243242)
        : const Color(0xFFF1F5F9);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: _PieGaugePainter(
                fraction: fraction,
                fillColor: fillColor,
                trackColor: trackColor,
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  child: Text(
                    valStr,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDueMessage(CountdownEvent event, Color themeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_on_rounded, color: Color(0xFFF59E0B), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.dueMessage.isNotEmpty ? event.dueMessage : 'حان الموعد اليوم! بالتوفيق للجميع.',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndedMessage(CountdownEvent event, Color themeColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: themeColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.endMessage.isNotEmpty ? event.endMessage : 'انتهى هذا الموعد رسمياً.',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── رسام المؤشر الدائري التفاعلي Pie Chart ─────────────────────────────────────
class _PieGaugePainter extends CustomPainter {
  final double fraction;
  final Color fillColor;
  final Color trackColor;

  const _PieGaugePainter({
    required this.fraction,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // دائرة الخلفية
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, trackPaint);

    // قطاع دائري للثواني أو الساعات أو الدقائق
    if (fraction > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      final sweepAngle = 2 * math.pi * fraction.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        true, // قطاع دائري كامل Pie
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PieGaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.trackColor != trackColor;
}
