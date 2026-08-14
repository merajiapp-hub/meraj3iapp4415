// screens/results/student_detail_screen.dart
// تصميم احترافي يشبه الصورة المرجعية
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../../services/results_service.dart';
import '../../services/result_pdf_service.dart';
import '../../providers/favorite_results_provider.dart';
import '../../theme/app_theme.dart';
import 'school_stats_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final StudentResult student;
  final Gradient gradient;
  final String emoji;
  final double passScore;
  final double maxScore;
  final String scoreLabel;
  final List<StudentResult> allResults;
  final ExamType examType;
  final String title;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.gradient,
    required this.emoji,
    required this.passScore,
    required this.maxScore,
    required this.scoreLabel,
    required this.allResults,
    required this.examType,
    this.title = '',
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;
  late ConfettiController _confettiController;

  // ترتيبات مُحسبة
  int? _rankNational;
  int? _rankWilaya;
  int? _rankCenter;
  int? _rankSchool;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FavoriteResultsProvider>().addRecent(
              widget.student,
              widget.examType,
              widget.title.isNotEmpty ? widget.title : 'نتيجة مسابقة',
            );
      }
    });

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _checkAndPlayConfetti();
    _computeRanks();
    _ctrl.forward();
  }

  void _computeRanks() {
    final s = widget.student;
    if (s.score == null) return;
    final all = widget.allResults;

    // ترتيب وطني (الناجحون فقط)
    if (s.isPassed) {
      final passedSorted = all
          .where((r) => r.isPassed && r.score != null)
          .toList()
        ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
      final idx = passedSorted.indexWhere((r) => r.id == s.id);
      if (idx >= 0) _rankNational = idx + 1;
    }

    // ترتيب الولاية
    if (s.wilaya.isNotEmpty) {
      final wilayaList = all
          .where((r) =>
              r.wilaya == s.wilaya && r.isPassed && r.score != null)
          .toList()
        ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
      final idx = wilayaList.indexWhere((r) => r.id == s.id);
      if (idx >= 0) _rankWilaya = idx + 1;
    }

    // ترتيب المركز
    if (s.center.isNotEmpty) {
      final centerList = all
          .where((r) =>
              r.center == s.center && r.isPassed && r.score != null)
          .toList()
        ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
      final idx = centerList.indexWhere((r) => r.id == s.id);
      if (idx >= 0) _rankCenter = idx + 1;
    }

    // ترتيب المدرسة
    if (s.school.isNotEmpty) {
      final schoolList = all
          .where((r) =>
              r.school == s.school && r.isPassed && r.score != null)
          .toList()
        ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
      final idx = schoolList.indexWhere((r) => r.id == s.id);
      if (idx >= 0) _rankSchool = idx + 1;
    }
  }

  void _checkAndPlayConfetti() {
    if (!widget.student.isPassed) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ─── مشاركة كبطاقة صورة ────────────────────────────────────────────────

  Future<void> _shareImageCard() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      if (imageBytes == null) throw Exception('فشل التقاط الصورة');

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/meraj3i_result_${widget.student.id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.png';
      final file = File(path);
      await file.writeAsBytes(imageBytes, flush: true);

      final text = _buildShareText(widget.student);
      await SharePlus.instance
          .share(ShareParams(text: text, files: [XFile(path)]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تصدير البطاقة: $e',
                style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تصدير النتيجة',
                style: GoogleFonts.tajawal(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('تحميل كملف PDF', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                ResultPdfService.generateAndShare(
                  context: context,
                  student: widget.student,
                  examType: widget.examType,
                  competitionTitle: widget.title,
                  scoreLabel: widget.scoreLabel,
                  maxScore: widget.maxScore,
                  rankNational: _rankNational,
                  rankWilaya: _rankWilaya,
                  rankCenter: _rankCenter,
                  rankSchool: _rankSchool,
                  saveToDownloads: true,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: Text('مشاركة كصورة', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                _shareImageCard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: Text('مشاركة كنص', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(context);
                _shareTextResult(widget.student);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildShareText(StudentResult s) {
    final score = s.score != null
        ? '${widget.scoreLabel}: ${s.score!.toStringAsFixed(2)}'
        : '';
    return '''
🎓 نتيجة MERAJ3I — ${widget.title}

👤 الاسم: ${s.name.isNotEmpty ? s.name : 'غير متوفر'}
🆔 الرقم: ${s.id.isNotEmpty ? s.id : 'غير متوفر'}
🏫 المؤسسة: ${s.school.isNotEmpty ? s.school : 'غير متوفر'}
📍 الولاية: ${s.wilaya.isNotEmpty ? s.wilaya : 'غير متوفر'}
${score.isNotEmpty ? '📊 $score' : ''}
✅ الحالة: ${s.status}
${_rankNational != null ? '🏆 الترتيب الوطني: $_rankNational' : ''}

📱 تطبيق مراجعي — منصتك التعليمية
''';
  }

  void _copyResult() {
    Clipboard.setData(ClipboardData(text: _buildShareText(widget.student)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ النتيجة ✓',
              style: GoogleFonts.tajawal()),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(student);
    final gradColor =
        (widget.gradient as LinearGradient).colors.first;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ── المحتوى الرئيسي ─────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // App Bar بسيط
              SliverAppBar(
                pinned: true,
                backgroundColor:
                    isDark ? const Color(0xFF0F172A) : Colors.white,
                elevation: 0,
                foregroundColor:
                    isDark ? Colors.white : const Color(0xFF0F172A),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // تصدير
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    onPressed: _showExportOptions,
                    tooltip: 'تصدير النتيجة',
                  ),
                  // نسخ
                  IconButton(
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: _copyResult,
                    tooltip: 'نسخ',
                  ),
                  // مفضلة
                  Consumer<FavoriteResultsProvider>(
                    builder: (context, prov, child) {
                      final isFav = prov.isFavorite(
                          student.id, widget.examType);
                      return IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.red[300] : null,
                        ),
                        onPressed: () => prov.toggleFavorite(
                          student,
                          widget.examType,
                          widget.title.isNotEmpty
                              ? widget.title
                              : 'نتيجة مسابقة',
                          context,
                        ),
                      );
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Column(
                            children: [
                              // ── بطاقة الحالة والشعار ────────────────
                              _buildStatusBadgeCard(
                                  student, statusColor, isDark),
                              const SizedBox(height: 16),

                              // ── اسم الطالب ──────────────────────────
                              Text(
                                student.name.isNotEmpty
                                    ? student.name
                                    : 'مترشح رقم ${student.id}',
                                style: GoogleFonts.tajawal(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),

                              // ── دائرة المجموع/المعدل ─────────────────
                              if (student.score != null)
                                _buildCircularScore(
                                    student, statusColor, isDark),
                              if (student.score != null)
                                const SizedBox(height: 16),

                              // ── بطاقة الولاية والمدرسة ───────────────
                              _buildLocationCard(student, isDark),
                              const SizedBox(height: 12),

                              // ── الترتيبات ────────────────────────────
                              if (student.isPassed &&
                                  (_rankSchool != null ||
                                      _rankCenter != null ||
                                      _rankWilaya != null ||
                                      _rankNational != null))
                                _buildRanksRow(isDark),
                              const SizedBox(height: 12),

                              // ── تفاصيل إضافية ────────────────────────
                              _buildDetailsCard(student, statusColor, isDark),
                              const SizedBox(height: 16),

                              // ── رسالة تشجيعية ─────────────────────────
                              _buildMessageCard(student),
                              const SizedBox(height: 24),

                              // ── شعار MERAJ3I ─────────────────────────
                              _buildFooter(isDark),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── زر مشاركة الصورة ────────────────────────────────────────
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SafeArea(
                child: const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Confetti ─────────────────────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                Color(0xFF16A34A),
                Color(0xFF0D9488),
                Color(0xFFF59E0B),
                Color(0xFF6366F1),
                Color(0xFFEC4899),
              ],
            ),
          ),
        ],
      ),
      // ── زر مشاركة الصورة ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isExporting ? null : _shareImageCard,
        backgroundColor: gradColor,
        elevation: 4,
        icon: _isExporting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.share_rounded, color: Colors.white),
        label: Text(
          _isExporting ? 'جاري التحضير...' : 'مشاركة النتيجة',
          style: GoogleFonts.tajawal(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── بطاقة الحالة + الشعار ────────────────────────────────────────────

  Widget _buildStatusBadgeCard(
      StudentResult s, Color statusColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // شارة الحالة
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  s.isPassed
                      ? Icons.check_circle_rounded
                      : s.isAbsent
                          ? Icons.help_outline_rounded
                          : s.isComplementary
                              ? Icons.refresh_rounded
                              : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  s.status,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // شعار MERAJ3I
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 36,
              width: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school_rounded,
                color: AppTheme.primaryColor,
                size: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── دائرة المجموع/المعدل ─────────────────────────────────────────────

  Widget _buildCircularScore(
      StudentResult s, Color statusColor, bool isDark) {
    final score = s.score ?? 0.0;
    final ratio = (score / widget.maxScore).clamp(0.0, 1.0);
    final isConcours = widget.examType == ExamType.concours;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // الدائرة
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(110, 110),
                  painter: _CircleScorePainter(
                    progress: ratio,
                    color: statusColor,
                    isDark: isDark,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      isConcours ? 'نقطة' : 'معدل',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // التفاصيل على اليمين
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _scoreDetailRow(
                    widget.scoreLabel,
                    '${score.toStringAsFixed(2)} / ${widget.maxScore.toStringAsFixed(0)}',
                    statusColor),
                if (s.center.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _scoreDetailRow('المركز', s.center, Colors.blue),
                ],
                if (s.wilaya.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _scoreDetailRow(
                      'الولاية', s.wilaya, AppTheme.primaryColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreDetailRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── بطاقة الولاية والمدرسة ──────────────────────────────────────────

  Widget _buildLocationCard(StudentResult s, bool isDark) {
    if (s.wilaya.isEmpty && s.school.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (s.school.isNotEmpty)
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchoolStatsScreen(
                      schoolName: s.school,
                      allResults: widget.allResults,
                      examType: widget.examType,
                      gradient: widget.gradient,
                      emoji: widget.emoji,
                      passScore: widget.passScore,
                      maxScore: widget.maxScore,
                      scoreLabel: widget.scoreLabel,
                    ),
                  ),
                ),
                child: _locationCell(
                  label: 'المدرسة',
                  value: s.school,
                  icon: Icons.school_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                  isFirst: true,
                  hasRight: s.wilaya.isNotEmpty,
                ),
              ),
            ),
          if (s.wilaya.isNotEmpty)
            Expanded(
              child: _locationCell(
                label: 'الولاية',
                value: s.wilaya,
                icon: Icons.location_on_rounded,
                color: AppTheme.primaryColor,
                isDark: isDark,
                isFirst: s.school.isEmpty,
                hasRight: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationCell({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isFirst,
    required bool hasRight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: hasRight
            ? Border(
                left: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9)))
            : null,
        borderRadius: BorderRadius.horizontal(
          right: isFirst ? const Radius.circular(16) : Radius.zero,
          left: !hasRight ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── صف الترتيبات ─────────────────────────────────────────────────────

  Widget _buildRanksRow(bool isDark) {
    final items = <_RankItem>[];
    if (_rankSchool != null) {
      items.add(_RankItem(
          label: 'ترتيب المدرسة', rank: _rankSchool!, color: Colors.purple));
    }
    if (_rankCenter != null) {
      items.add(_RankItem(
          label: 'ترتيب المقاطعة',
          rank: _rankCenter!,
          color: Colors.blue));
    }
    if (_rankWilaya != null) {
      items.add(_RankItem(
          label: 'ترتيب الولاية',
          rank: _rankWilaya!,
          color: AppTheme.primaryColor));
    }
    if (_rankNational != null) {
      items.add(_RankItem(
          label: 'الترتيب الوطني',
          rank: _rankNational!,
          color: const Color(0xFFF59E0B)));
    }
    if (items.isEmpty) return const SizedBox.shrink();

    // نعرض أول 3 أو 4 حسب التوفر
    final displayItems = items.take(4).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: displayItems.map((item) {
          return Expanded(
            child: Column(
              children: [
                Text(
                  '${item.rank}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),
                Text(
                  item.label,
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── تفاصيل إضافية ────────────────────────────────────────────────────

  Widget _buildDetailsCard(
      StudentResult s, Color statusColor, bool isDark) {
    final items = <MapEntry<String, String>>[];
    if (s.id.isNotEmpty) items.add(MapEntry('رقم التسجيل', s.id));
    if (s.branch.isNotEmpty) items.add(MapEntry('الشعبة', s.branch));
    if (s.rank.isNotEmpty && s.isPassed) {
      items.add(MapEntry(
        s.branch.isNotEmpty ? 'الترتيب في الشعبة' : 'الترتيب',
        s.rank,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات المترشح',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((e) => _detailRow(e.key, e.value, isDark)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── رسالة تشجيعية ─────────────────────────────────────────────────────

  Widget _buildMessageCard(StudentResult s) {
    String emoji;
    String title;
    String body;
    List<Color> colors;

    if (s.isPassed) {
      emoji = '🎉';
      title = 'مبروك النجاح!';
      body = 'تتمنى لكم منصة مراجعي مستقبلاً مشرقاً مليئاً بالنجاحات.';
      colors = const [Color(0xFF16A34A), Color(0xFF059669)];
    } else if (s.isComplementary) {
      emoji = '⏳';
      title = 'فرصة جديدة!';
      body = 'استغل الدورة التكميلية. منصة مراجعي تتمنى لك التوفيق.';
      colors = const [Color(0xFFF59E0B), Color(0xFFD97706)]; // Orange
    } else if (s.isExpelled) {
      emoji = '⚠️';
      title = 'عثرة لا تعني النهاية';
      body = 'استفد من التجربة. منصة مراجعي تشجعك على بداية جديدة.';
      colors = const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]; // Purple
    } else if (s.isAbsent) {
      emoji = '📝';
      title = 'نتمنى أن يكون المانع خيراً!';
      body = 'منصة مراجعي بانتظارك في المحطات القادمة.';
      colors = const [Color(0xFF6B7280), Color(0xFF4B5563)]; // Grey
    } else {
      emoji = '💪';
      title = 'لا تيأس!';
      body = 'الفشل أول خطوة نحو النجاح. استعد جيداً، النجاح حليفك.';
      colors = const [Color(0xFFEF4444), Color(0xFFDC2626)]; // Red
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.tajawal(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── شعار MERAJ3I ──────────────────────────────────────────────────────

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 22,
          errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.school_rounded,
              size: 22,
              color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 8),
        Text(
          'تطبيق مراجعي — منصتك التعليمية',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── مساعدات ────────────────────────────────────────────────────────────

  Color _statusColor(StudentResult s) {
    if (s.isPassed) return const Color(0xFF16A34A);
    if (s.isAbsent) return Colors.grey;
    if (s.isComplementary) return Colors.orange;
    if (s.isExpelled) return Colors.purple;
    return Colors.red;
  }

  void _shareTextResult(StudentResult s) {
    SharePlus.instance.share(ShareParams(text: _buildShareText(s)));
  }
}

// ── ترتيب مُعرَّف ────────────────────────────────────────────────────────

class _RankItem {
  final String label;
  final int rank;
  final Color color;

  _RankItem({required this.label, required this.rank, required this.color});
}

// ── رسّام الدائرة ──────────────────────────────────────────────────────────

class _CircleScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _CircleScorePainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // خلفية
    final bgPaint = Paint()
      ..color =
          isDark ? Colors.white.withValues(alpha: 0.08) : color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // التقدم
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_CircleScorePainter old) =>
      old.progress != progress || old.color != color;
}
