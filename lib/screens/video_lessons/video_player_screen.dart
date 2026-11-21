import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video_lesson_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/video_lesson_service.dart';
import '../../../services/video_download_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/pro_feature_gate.dart';
import '../pro_subscription_screen.dart';
import '../pdf_viewer_screen.dart';
import 'widgets/video_player_widget.dart';
import 'teacher_profile_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoLesson lesson;
  final VideoSubject subject;
  final VideoLevel level;
  final VideoUnit? unit;
  final List<VideoLesson> playlist;
  final String? localFilePath;

  const VideoPlayerScreen({
    super.key,
    required this.lesson,
    required this.subject,
    required this.level,
    this.unit,
    required this.playlist,
    this.localFilePath,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  final VideoLessonService _service = VideoLessonService();
  final VideoDownloadService _downloadService = VideoDownloadService();

  late VideoLesson _currentLesson;
  VideoTeacher? _teacher;
  bool _isCompleted = false;
  bool _isFavorite = false;
  int _lastPositionSeconds = 0;
  String? _effectiveLocalPath;

  // حالة التنزيل
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadPercent = 0;

  // الملاحظات الشخصية
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isSavingNote = false;

  // التقييم
  int _userRating = 5;

  // الاختبار القصير
  int? _selectedQuizOption;
  int _quizStep = 0;
  int _quizScore = 0;
  bool _showQuizExplanation = false;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
    _effectiveLocalPath = widget.localFilePath;
    _initLessonState();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLessonState() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';

    _service.incrementLessonViews(_currentLesson);

    // فحص المعلم المرتبط
    if (_currentLesson.teacherId != null && _currentLesson.teacherId!.isNotEmpty) {
      final t = await _service.getTeacher(_currentLesson.teacherId!);
      if (mounted) setState(() => _teacher = t);
    } else {
      if (mounted) setState(() => _teacher = null);
    }

    // فحص التنزيل المحلي
    final downloaded = await _downloadService.isLessonDownloaded(_currentLesson.id);
    if (mounted) {
      setState(() => _isDownloaded = downloaded);
    }

    // استرجاع موضع الاستئناف والملاحظة
    if (userId.isNotEmpty) {
      final prog = await _service.getLessonProgress(userId, _currentLesson.id);
      if (prog != null && mounted) {
        setState(() {
          _isCompleted = prog.isCompleted;
          _lastPositionSeconds = prog.lastPositionSeconds;
        });
      }

      // جلب الملاحظة
      _service.streamLessonNote(userId, _currentLesson.id).first.then((noteText) {
        if (mounted && noteText.isNotEmpty) {
          _noteCtrl.text = noteText;
        }
      });
    }
  }

  void _switchLesson(VideoLesson newLesson) {
    final auth = context.read<AuthProvider>();
    if (newLesson.isPro && !auth.isPro) {
      ProFeatureGate.showProLockedDialog(
        context: context,
        featureName: 'الدرس: ${newLesson.title}',
      );
      return;
    }

    setState(() {
      _currentLesson = newLesson;
      _isCompleted = false;
      _isFavorite = false;
      _effectiveLocalPath = null;
      _lastPositionSeconds = 0;
      _selectedQuizOption = null;
      _quizStep = 0;
      _quizScore = 0;
      _showQuizExplanation = false;
      _noteCtrl.clear();
    });
    _initLessonState();
  }

  Future<void> _toggleComplete() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول لحفظ تقدمك')),
      );
      return;
    }

    final newStatus = !_isCompleted;
    setState(() => _isCompleted = newStatus);
    await _service.recordProgress(
      userId: userId,
      lesson: _currentLesson,
      isCompleted: newStatus,
      lastPositionSeconds: _lastPositionSeconds,
    );

    if (mounted && newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'أحسنت! تم تسجيل إكمال هذا الدرس بنجاح',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) return;

    final isFav = await _service.toggleFavorite(
      userId: userId,
      lessonId: _currentLesson.id,
    );
    setState(() => _isFavorite = isFav);
  }

  void _shareLesson() {
    Share.share(
      'شاهد هذا الدرس: ${_currentLesson.title} في منصة مراجعي التعليمية\n${_currentLesson.previewUrl}',
      subject: _currentLesson.title,
    );
  }

  Future<void> _handleDownload() async {
    final auth = context.read<AuthProvider>();

    // تنزيل الفيديوهات للمشاهدة دون إنترنت ميزة مقيدة تتطلب اشتراك Pro
    if (!auth.isPro) {
      ProFeatureGate.showProLockedDialog(
        context: context,
        featureName: 'تنزيل الفيديوهات للمشاهدة دون إنترنت',
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadPercent = 0;
    });

    _downloadService.progressStream(_currentLesson.id).listen((p) {
      if (mounted) {
        setState(() => _downloadPercent = p.progress ?? 0);
      }
    });

    try {
      final savedPath = await _downloadService.downloadLesson(
        lesson: _currentLesson,
        subjectName: widget.subject.title,
        levelCode: widget.level.code,
      );
      if (mounted && savedPath != null) {
        setState(() {
          _isDownloaded = true;
          _effectiveLocalPath = savedPath;
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('تم تنزيل الفيديو بنجاح ويمكنك الآن مشاهدته دون إنترنت'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('فشل أثناء التنزيل: $e'),
          ),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) return;

    setState(() => _isSavingNote = true);
    await _service.saveLessonNote(userId, _currentLesson.id, _noteCtrl.text);
    if (mounted) {
      setState(() => _isSavingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الملاحظة بنجاح')),
      );
    }
  }

  void _openPdfViewer(VideoAttachment file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          pdfUrl: file.url,
          title: file.title,
          stageName: widget.level.title,
          sectionName: widget.subject.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectColor = Color(widget.subject.colorHex);
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid ?? '';

    final currentIndex = widget.playlist.indexWhere((l) => l.id == _currentLesson.id);
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex >= 0 && currentIndex < widget.playlist.length - 1;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.subject.title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            tooltip: 'حفظ في المفضلة',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة الدرس',
            onPressed: _shareLesson,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. مشغل الفيديو المتطور
              VideoPlayerWidget(
                key: ValueKey(_currentLesson.id),
                lesson: _currentLesson,
                localFilePath: _effectiveLocalPath,
                initialPositionSeconds: _lastPositionSeconds,
                isProUser: auth.isPro,
                onUpgradeToPro: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProSubscriptionScreen()),
                ),
                onPositionChanged: (sec) {
                  _lastPositionSeconds = sec;
                  if (userId.isNotEmpty) {
                    _service.recordProgress(
                      userId: userId,
                      lesson: _currentLesson,
                      isCompleted: _isCompleted,
                      lastPositionSeconds: sec,
                    );
                  }
                },
                onCompleted: () {
                  if (!_isCompleted) _toggleComplete();
                },
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. تصنيف الدرس وحالة Pro
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: subjectColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.level.code,
                            style: GoogleFonts.tajawal(
                              color: subjectColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.unit != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.unit!.title,
                              style: GoogleFonts.tajawal(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (_currentLesson.isPro)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'PRO',
                                  style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // عنوان الدرس
                    Text(
                      _currentLesson.title,
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // المشاهدات والمدة والتقييم
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 14, color: isDark ? Colors.white54 : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${_currentLesson.viewsCount} مشاهدة', style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
                        if (_currentLesson.duration.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          Icon(Icons.access_time_rounded, size: 14, color: isDark ? Colors.white54 : Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(_currentLesson.duration, style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600])),
                        ],
                        const SizedBox(width: 14),
                        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          _currentLesson.ratingAverage.toStringAsFixed(1),
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // أزرار التفاعل الرئيسية: إكمال الدرس + تنزيل أوفلاين + تنقل
                    Row(
                      children: [
                        // زر تحديد كمكتمل
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white : Colors.black87),
                              side: BorderSide(
                                color: _isCompleted
                                    ? const Color(0xFF10B981)
                                    : (isDark ? Colors.white24 : Colors.black26),
                                width: _isCompleted ? 1.5 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(
                              _isCompleted ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                              color: _isCompleted ? const Color(0xFF10B981) : null,
                            ),
                            label: Text(
                              _isCompleted ? 'مكتمل' : 'تحديد كمكتمل',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            onPressed: _toggleComplete,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // زر التنزيل دون إنترنت
                        if (_currentLesson.allowDownload)
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _isDownloaded
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: _isDownloading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(
                                      _isDownloaded
                                          ? Icons.download_done_rounded
                                          : Icons.download_rounded,
                                      size: 18,
                                    ),
                              label: Text(
                                _isDownloading
                                    ? '${(_downloadPercent * 100).toInt()}%'
                                    : _isDownloaded
                                        ? 'منزل بالجهاز'
                                        : 'تنزيل الفيديو',
                                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              onPressed: _isDownloading || _isDownloaded ? null : _handleDownload,
                            ),
                          ),
                        const SizedBox(width: 8),

                        // أزرار السابق والتالي
                        IconButton.filledTonal(
                          icon: const Icon(Icons.skip_previous_rounded),
                          tooltip: 'الدرس السابق',
                          onPressed: hasPrevious ? () => _switchLesson(widget.playlist[currentIndex - 1]) : null,
                        ),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.skip_next_rounded),
                          tooltip: 'الدرس التالي',
                          onPressed: hasNext ? () => _switchLesson(widget.playlist[currentIndex + 1]) : null,
                        ),
                      ],
                    ),
                    if (!context.watch<AuthProvider>().isPro) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProSubscriptionScreen()),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF78350F), Color(0xFFB45309)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFB45309).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.amberAccent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'اشترك في Pro لتنزيل جميع الفيديوهات دون إنترنت وبدون إعلانات',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // 3. بطاقة معلومات الأستاذ (البند 6 من البرومبت)
                    if (_teacher != null || (_currentLesson.teacherName != null && _currentLesson.teacherName!.isNotEmpty))
                      _buildTeacherCard(isDark),

                    // 4. قسم ملفات ومذكرات الدرس PDF (البند 6)
                    if (_currentLesson.pdfFiles.isNotEmpty)
                      _buildAttachmentsSection(isDark),

                    // 5. وصف الدرس وملاحظات إضافية
                    if (_currentLesson.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'وصف الدرس',
                        style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentLesson.description,
                        style: GoogleFonts.tajawal(fontSize: 13.5, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
                      ),
                    ],

                    // 6. ملاحظات الطالب الشخصية (البند 14)
                    _buildPersonalNotesSection(isDark),

                    // 7. اختبار سريع بعد الدرس (البند 14)
                    if (_currentLesson.quizQuestions.isNotEmpty)
                      _buildQuizSection(isDark),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 8. قائمة الدروس الأخرى في نفس الوحدة / المادة
                    Row(
                      children: [
                        const Icon(Icons.playlist_play_rounded, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'دروس هذه المادة (${widget.playlist.length})',
                          style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ...widget.playlist.map((item) {
                      final isSelected = item.id == _currentLesson.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? subjectColor.withValues(alpha: isDark ? 0.2 : 0.1)
                              : (isDark ? AppTheme.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? subjectColor
                                : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? subjectColor : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isSelected ? Icons.play_arrow_rounded : Icons.play_circle_outline_rounded,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: GoogleFonts.tajawal(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13.5,
                              color: isSelected ? subjectColor : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.duration.isNotEmpty ? item.duration : 'فيديو تعليمي',
                            style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                          trailing: item.isPro
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(6)),
                                  child: Text('PRO', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                )
                              : null,
                          onTap: () => _switchLesson(item),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بطاقة الأستاذ
  Widget _buildTeacherCard(bool isDark) {
    final tName = _teacher?.name ?? _currentLesson.teacherName ?? 'أستاذ المادة';
    final tPhoto = _teacher?.effectivePhotoUrl ?? _currentLesson.teacherPhotoUrl ?? '';
    final tSpecialty = _teacher?.specialty ?? widget.subject.title;
    final tBio = _teacher?.bio ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة الأستاذ
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor, width: 1.5),
            ),
            child: ClipOval(
              child: tPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: tPhoto,
                      fit: BoxFit.cover,
                      errorWidget: (ctx, url, err) => _fallbackAvatar(),
                    )
                  : _fallbackAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tName,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                Text(
                  tSpecialty,
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
                if (tBio.isNotEmpty)
                  Text(
                    tBio,
                    style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (_teacher != null)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TeacherProfileScreen(teacher: _teacher!)),
                );
              },
              child: Text(
                'دروس الأستاذ',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFF14B8A6),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  /// قسم ملفات PDF والمذكرات
  Widget _buildAttachmentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 8),
            Text(
              'ملفات ومذكرات الدرس (${_currentLesson.pdfFiles.length})',
              style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._currentLesson.pdfFiles.map((file) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.title,
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (file.fileSize.isNotEmpty)
                        Text(
                          file.fileSize,
                          style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                        ),
                    ],
                  ),
                ),
                // زر عرض الملف المدمج في قارئ PDF
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => _openPdfViewer(file),
                  child: const Text('عرض في التطبيق'),
                ),
                const SizedBox(width: 6),
                // زر التنزيل الخارجي
                IconButton(
                  icon: const Icon(Icons.download_rounded, size: 20),
                  tooltip: 'تنزيل PDF',
                  onPressed: () {
                    final uri = Uri.tryParse(file.url);
                    if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// قسم الملاحظات الشخصية
  Widget _buildPersonalNotesSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFF14B8A6), size: 22),
              const SizedBox(width: 8),
              Text(
                'ملاحظاتي الخاصة على هذا الدرس',
                style: GoogleFonts.tajawal(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_isSavingNote)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                TextButton(
                  onPressed: _saveNote,
                  child: const Text('حفظ الملاحظة'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'سجّل ملاحظاتك، القوانين المهمة، أو النقاط التي تريد مراجعتها لاحقاً...',
              hintStyle: GoogleFonts.tajawal(fontSize: 12, color: isDark ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  /// قسم الاختبار القصير
  Widget _buildQuizSection(bool isDark) {
    final quiz = _currentLesson.quizQuestions;
    if (_quizStep >= quiz.length) {
      return Container(
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFF10B981), size: 40),
            const SizedBox(height: 8),
            Text(
              'أحسنت! أكملت اختبار فهم الدرس',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'نتيجتك: $_quizScore من ${quiz.length}',
              style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _quizStep = 0;
                  _quizScore = 0;
                  _selectedQuizOption = null;
                  _showQuizExplanation = false;
                });
              },
              child: const Text('إعادة الاختبار'),
            ),
          ],
        ),
      );
    }

    final q = quiz[_quizStep];

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz_rounded, color: Color(0xFF8B5CF6), size: 22),
              const SizedBox(width: 8),
              Text(
                'اختبار سريع بعد الدرس (${_quizStep + 1} من ${quiz.length})',
                style: GoogleFonts.tajawal(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.question,
            style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...q.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isChosen = _selectedQuizOption == idx;
            final isCorrect = idx == q.correctIndex;

            Color? tileColor;
            if (_showQuizExplanation) {
              if (isCorrect) tileColor = Colors.green.withValues(alpha: 0.2);
              if (isChosen && !isCorrect) tileColor = Colors.red.withValues(alpha: 0.2);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: tileColor ?? (isChosen ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isChosen ? const Color(0xFF8B5CF6) : Colors.transparent),
              ),
              child: RadioListTile<int>(
                value: idx,
                groupValue: _selectedQuizOption,
                title: Text(opt, style: GoogleFonts.tajawal(fontSize: 13)),
                onChanged: _showQuizExplanation ? null : (val) => setState(() => _selectedQuizOption = val),
              ),
            );
          }),
          if (_showQuizExplanation && q.explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'التوضيح: ${q.explanation}',
              style: GoogleFonts.tajawal(fontSize: 12, color: Colors.green),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_showQuizExplanation)
                FilledButton(
                  onPressed: _selectedQuizOption == null
                      ? null
                      : () {
                          setState(() {
                            _showQuizExplanation = true;
                            if (_selectedQuizOption == q.correctIndex) {
                              _quizScore++;
                            }
                          });
                        },
                  child: const Text('تأكيد الإجابة'),
                )
              else
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _quizStep++;
                      _selectedQuizOption = null;
                      _showQuizExplanation = false;
                    });
                  },
                  child: const Text('السؤال التالي'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
