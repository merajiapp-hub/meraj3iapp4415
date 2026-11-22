import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/countdown_event.dart';
import '../services/countdown_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  CountdownScreen — المواعيد والعد التنازلي للمسابقات والعطل
// ══════════════════════════════════════════════════════════════════════════════
class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  final _service = CountdownService();
  late final Stream<bool> _countdownEnabledStream;
  late final Stream<List<CountdownEvent>> _activeEventsStream;
  Timer? _liveTimer;

  static const List<Color> _palette = [
    Color(0xFF16A34A), // Emerald Green
    Color(0xFF3525CD), // Deep Indigo (Brand)
    Color(0xFFD97706), // Warm Amber
    Color(0xFF7C3AED), // Royal Purple
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF0D9488), // Teal
    Color(0xFFE11D48), // Rose
  ];

  @override
  void initState() {
    super.initState();
    _countdownEnabledStream = _service.streamCountdownEnabled();
    _activeEventsStream = _service.streamActiveEvents();

    // تحديث حي فوري كل ثانية لحركة العدادات والمؤشرات
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF070F18) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: StreamBuilder<bool>(
          stream: _countdownEnabledStream,
          initialData: true,
          builder: (context, enabledSnap) {
            final isEnabled = enabledSnap.data ?? true;
            if (!isEnabled) return _buildDisabledState(isDark);

            return StreamBuilder<List<CountdownEvent>>(
              stream: _activeEventsStream,
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;
                final allEvents = snapshot.data ?? const <CountdownEvent>[];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── شريط الرأس الاحترافي ─────────────────────────────────
                    _buildAppBar(context, isDark),

                    // ── العنوان الرئيسي والفرعي والفلاتر ─────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مواعيد المسابقات',
                              style: GoogleFonts.tajawal(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'العد التنازلي للمسابقات والامتحانات الرسمية',
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── قائمة البطاقات المطابقة للتصميم ─────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                      sliver: isLoading
                          ? const SliverFillRemaining(
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                                ),
                              ),
                            )
                          : _buildEventsList(allEvents, isDark),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ── شريط الرأس النظيف ───────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF070F18) : const Color(0xFFF8FAFC),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_forward_rounded,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          size: 22,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      centerTitle: true,
      title: Text(
        'العدّ التنازلي',
        style: GoogleFonts.tajawal(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  // ── قائمة بطاقات المواعيد ───────────────────────────────────────────────
  Widget _buildEventsList(List<CountdownEvent> allEvents, bool isDark) {
    if (allEvents.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد مواعيد حالياً',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final event = allEvents[index];
          final color = _palette[index % _palette.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CountdownCardWidget(
              event: event,
              isDark: isDark,
              accentColor: color,
            ),
          );
        },
        childCount: allEvents.length,
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

// ══════════════════════════════════════════════════════════════════════════════
//  _CountdownCardWidget — بطاقة العد التنازلي المطابقة 100% للتصميم المطلوب
// ══════════════════════════════════════════════════════════════════════════════
class _CountdownCardWidget extends StatelessWidget {
  final CountdownEvent event;
  final bool isDark;
  final Color accentColor;

  const _CountdownCardWidget({
    required this.event,
    required this.isDark,
    this.accentColor = const Color(0xFF16A34A),
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white60 : const Color(0xFF64748B);

    final isDue = event.isDueToday;
    final isEnded = event.isEnded;
    final rem = event.remainingDuration;

    final days = rem.isNegative ? 0 : rem.inDays;
    final hours = rem.isNegative ? 0 : rem.inHours % 24;
    final minutes = rem.isNegative ? 0 : rem.inMinutes % 60;
    final seconds = rem.isNegative ? 0 : rem.inSeconds % 60;

    final dateFormatted = DateFormat('dd/MM/yyyy').format(event.targetDate);

    // الألوان المستوحاة من التصميم
    final greenPrimary = accentColor;
    final trackColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF131D2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1E2D40) : accentColor.withValues(alpha: 0.22);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF16A34A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. رأس البطاقة: عنوان الامتحان، التاريخ، والنقطة الخضراء ───────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateFormatted,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // النقطة الخضراء المتوهجة
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: greenPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: greenPrimary.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── 2. محتوى العداد التنازلي التفاعلي أو رسالة الانتهاء ─────────
          if (isEnded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2D40) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                event.endMessage.isNotEmpty
                    ? event.endMessage
                    : 'انتهى الموعد، نتمنى التوفيق والنجاح للجميع',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isDue)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
              ),
              child: Text(
                event.dueMessage.isNotEmpty
                    ? event.dueMessage
                    : 'حان الموعد اليوم! بالتوفيق لجميع المشاركين 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFD97706),
                ),
              ),
            )
          else
            // ── التصميم المطابق للصورة: 3 أقسام تفاعلية ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // القسم الأيمن: متبقي + رقم الأيام الكبير + أيام + الشريط السفلي
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'متبقي',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$days',
                          style: GoogleFonts.outfit(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: greenPrimary,
                            height: 1.05,
                          ),
                        ),
                      ),
                      Text(
                        'أيام',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // الشريط الأخضر الفاتح السفلي
                      Container(
                        width: 58,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? greenPrimary.withValues(alpha: 0.35)
                              : greenPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),

                // فاصل عمودي رفيع وأنيق
                Container(
                  height: 80,
                  width: 1,
                  color: isDark ? const Color(0xFF1E2D40) : const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // القسم الأوسط: مؤشر دائري كبير للثواني مع الرقم بالداخل
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(72, 72),
                              painter: _PieGaugePainter(
                                progress: seconds / 60.0,
                                trackColor: trackColor,
                                progressColor: greenPrimary,
                              ),
                            ),
                            Text(
                              seconds.toString().padLeft(2, '0'),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ثواني',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // القسم الأيسر: مؤشران دائريان متطابقان للساعات والدقائق
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // مؤشر الساعات
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(44, 44),
                                  painter: _PieGaugePainter(
                                    progress: hours / 24.0,
                                    trackColor: trackColor,
                                    progressColor: greenPrimary,
                                  ),
                                ),
                                Text(
                                  hours.toString().padLeft(2, '0'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ساعات',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // مؤشر الدقائق
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(44, 44),
                                  painter: _PieGaugePainter(
                                    progress: minutes / 60.0,
                                    trackColor: trackColor,
                                    progressColor: greenPrimary,
                                  ),
                                ),
                                Text(
                                  minutes.toString().padLeft(2, '0'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'دقائق',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: textMuted,
                            ),
                          ),
                        ],
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
}

// ══════════════════════════════════════════════════════════════════════════════
//  _PieGaugePainter — رسام قطاعات الدائرة التفاعلي المتحرك
// ══════════════════════════════════════════════════════════════════════════════
class _PieGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color progressColor;

  _PieGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // رسم خلفية الدائرة بالكامل
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // رسم قطاع التقدم الحي المتحرك باتجاه عقارب الساعة
    if (progress > 0) {
      final sweepPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;
      final sweepAngle = (progress.clamp(0.0, 1.0)) * 2 * math.pi;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, true, sweepPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PieGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

