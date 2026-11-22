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
import '../../../widgets/pro_feature_gate.dart';
import '../pro_subscription_screen.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final VideoLessonService _service = VideoLessonService();
  final VideoDownloadService _downloadService = VideoDownloadService();

  late VideoLesson _currentLesson;
  VideoTeacher? _teacher;
  bool _isCompleted = false;
  bool _isFavorite = false;
  int _lastPositionSeconds = 0;
  String? _effectiveLocalPath;

  // حالة التنزيل وجودة التنزيل
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadPercent = 0;
  String _downloadQuality = 'HD'; // 'HD' or 'SD'

  // الملاحظات الشخصية المرتبطة بالوقت
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isSavingNote = false;

  // طرح سؤال على الأستاذ
  final TextEditingController _teacherQuestionCtrl = TextEditingController();
  bool _isSendingTeacherQuestion = false;
  bool _showTeacherQuestionSuccess = false;

  // التعليقات العامة
  final TextEditingController _commentCtrl = TextEditingController();
  bool _isPostingComment = false;

  // الاختبار القصير التفاعلي
  Map<int, int> _selectedAnswers = {};
  bool _quizEvaluated = false;
  int _quizScore = 0;

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
    _teacherQuestionCtrl.dispose();
    _commentCtrl.dispose();
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

    // استرجاع موضع الاستئناف والمفضلة
    if (userId.isNotEmpty) {
      final prog = await _service.getLessonProgress(userId, _currentLesson.id);
      if (prog != null && mounted) {
        setState(() {
          _isCompleted = prog.isCompleted;
          _lastPositionSeconds = prog.lastPositionSeconds;
        });
      }

      // المفضلة
      _service.isFavoriteStream(userId: userId, lessonId: _currentLesson.id).first.then((fav) {
        if (mounted) setState(() => _isFavorite = fav);
      });

      // استرجاع نتيجة الاختبار إن وجدت
      final quizRes = await _service.getQuizResult(userId, _currentLesson.id);
      if (quizRes != null && mounted) {
        setState(() {
          _quizEvaluated = true;
          _quizScore = (quizRes['score'] as num?)?.toInt() ?? 0;
        });
      }
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
      _selectedAnswers.clear();
      _quizEvaluated = false;
      _quizScore = 0;
      _noteCtrl.clear();
      _showTeacherQuestionSuccess = false;
    });
    _initLessonState();
  }

  Future<void> _toggleFavorite() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول لإضافة الدرس إلى المفضلة')),
      );
      return;
    }

    final newStatus = await _service.toggleFavorite(
      userId: userId,
      lessonId: _currentLesson.id,
    );
    if (mounted) {
      setState(() => _isFavorite = newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'تمت إضافة الدرس إلى المفضلة' : 'تمت إزالة الدرس من المفضلة',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareLesson() {
    Share.share(
      'شاهد درس: ${_currentLesson.title}\nفي منصة مراجعي التعليمية\n${_currentLesson.previewUrl}',
      subject: _currentLesson.title,
    );
  }

  Future<void> _handleDownload() async {
    final auth = context.read<AuthProvider>();

    if (!auth.isPro && _currentLesson.isPro) {
      ProFeatureGate.showProLockedDialog(
        context: context,
        featureName: 'تنزيل الفيديوهات للمشاهدة بدون إنترنت',
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadPercent = 0.05;
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
            content: Text('تم تنزيل الفيديو بنجاح! يمكنك الآن مشاهدته في أي وقت بدون إنترنت.'),
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

  Future<void> _saveNoteWithTimestamp(int seconds, String tag) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول لحفظ ملاحظاتك')),
      );
      return;
    }

    final content = _noteCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة نص الملاحظة قبل الحفظ')),
      );
      return;
    }

    setState(() => _isSavingNote = true);
    await _service.addTimestampNote(
      userId: userId,
      lessonId: _currentLesson.id,
      content: content,
      timestampSeconds: seconds,
      tag: tag,
    );
    if (mounted) {
      setState(() {
        _isSavingNote = false;
        _noteCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF10B981),
          content: Text('تم حفظ الملاحظة وربطها بتوقيت الفيديو بنجاح!'),
        ),
      );
    }
  }

  Future<void> _submitTeacherQuestion() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    final userName = auth.user?.displayName ?? 'طالب مراجعي';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول لطرح سؤال على الأستاذ')),
      );
      return;
    }

    final question = _teacherQuestionCtrl.text.trim();
    if (question.isEmpty) return;

    setState(() => _isSendingTeacherQuestion = true);
    await _service.addComment(
      lessonId: _currentLesson.id,
      userId: userId,
      userName: userName,
      userRole: 'طالب',
      content: question,
      isQuestionToTeacher: true,
    );

    if (mounted) {
      setState(() {
        _isSendingTeacherQuestion = false;
        _showTeacherQuestionSuccess = true;
        _teacherQuestionCtrl.clear();
      });
    }
  }

  Future<void> _postGeneralComment() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    final userName = auth.user?.displayName ?? 'طالب مراجعي';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول للمشاركة في النقاش')),
      );
      return;
    }

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPostingComment = true);
    await _service.addComment(
      lessonId: _currentLesson.id,
      userId: userId,
      userName: userName,
      userRole: 'طالب',
      content: text,
      isQuestionToTeacher: false,
    );

    if (mounted) {
      setState(() {
        _isPostingComment = false;
        _commentCtrl.clear();
      });
    }
  }

  void _checkQuiz(List<VideoQuizQuestion> questions) {
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i].correctIndex) {
        score++;
      }
    }

    setState(() {
      _quizEvaluated = true;
      _quizScore = score;
    });

    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    if (userId.isNotEmpty) {
      _service.saveQuizResult(
        userId: userId,
        lessonId: _currentLesson.id,
        score: score,
        total: questions.length,
      );
    }
  }

  void _resetQuiz() {
    setState(() {
      _selectedAnswers.clear();
      _quizEvaluated = false;
      _quizScore = 0;
    });
  }

  void _openInAppPdfViewer(VideoAttachment file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _InAppPdfModal(file: file),
    );
  }

  List<VideoQuizQuestion> _getEffectiveQuiz() {
    if (_currentLesson.quizQuestions.isNotEmpty) {
      return _currentLesson.quizQuestions;
    }
    // أسئلة ذكية افتراضية متطابقة مع التصميم المطلوب
    return const [
      VideoQuizQuestion(
        id: 'q1',
        question: '1. ما هو العامل الأساسي الذي يؤثر على استقرار النواة في التحولات النووية؟',
        options: [
          'أ) عدد النيوترونات فقط',
          'ب) نسبة عدد النيوترونات إلى عدد البروتونات (N/Z)',
          'ج) كتلة النواة الإجمالية',
          'د) طاقة الإشعاع',
        ],
        correctIndex: 1,
        explanation: 'استقرار النواة يحدده وادي الاستقرار الذي يعتمد على النسبة المتوازنة بين النيوترونات والبروتونات (N/Z).',
      ),
      VideoQuizQuestion(
        id: 'q2',
        question: '2. ما الذي يمثله ثابت النشاط الإشعاعي (λ) في قانون التناقص الإشعاعي؟',
        options: [
          'أ) عمر النصف للعينات',
          'ب) احتمال تفكك نواة في وحدة الزمن',
          'ج) عدد النيوكليونات الكلي',
        ],
        correctIndex: 1,
        explanation: 'الثابت الإشعاعي λ يمثل الاحتمال الإحصائي لتفكك النواة في الثانية الواحدة (s⁻¹).',
      ),
      VideoQuizQuestion(
        id: 'q3',
        question: '3. كلما كانت طاقة الربط النووي لكل نكليون أكبر، كلما كانت النواة:',
        options: [
          'أ) أقل استقراراً',
          'ب) أكثر استقراراً',
          'ج) عرضة للانشطار التلقائي السريع',
        ],
        correctIndex: 1,
        explanation: 'طاقة الربط لكل نكليون (El/A) هي المقياس الحقيقي لمدى تماسك واستقرار النواة.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    final quizQuestions = _getEffectiveQuiz();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'الرجوع',
        ),
        title: Text(
          widget.subject.title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isFavorite ? const Color(0xFF0051D5) : null,
            ),
            tooltip: 'حفظ الدرس',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة',
            onPressed: _shareLesson,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. عارض الفيديو الذكي مع شريط الاستئناف والشارات
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
                  if (!_isCompleted) {
                    setState(() => _isCompleted = true);
                    if (userId.isNotEmpty) {
                      _service.recordProgress(
                        userId: userId,
                        lesson: _currentLesson,
                        isCompleted: true,
                        lastPositionSeconds: _lastPositionSeconds,
                      );
                    }
                  }
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. بطاقة تحميل الفيديو للمشاهدة بدون إنترنت
                    _buildOfflineDownloadCard(isDark),

                    const SizedBox(height: 14),

                    // 3. شارات التصنيف والمشاهدات وعنوان الدرس
                    _buildLessonHeader(isDark),

                    const SizedBox(height: 16),

                    // 4. بطاقة الأستاذ المميزة
                    _buildTeacherCard(isDark),

                    const SizedBox(height: 16),

                    // 5. وصف الدرس الشامل
                    _buildDescriptionCard(isDark),

                    const SizedBox(height: 16),

                    // 6. ملفات الدرس المرفقة PDF
                    _buildAttachedFilesCard(isDark),

                    const SizedBox(height: 16),

                    // 7. مركز ملاحظات الطالب الخاصة مع وسوم الوقت
                    _buildStudentNotesCenter(isDark),

                    const SizedBox(height: 16),

                    // 8. اختبار قصير تفاعلي لتقييم الفهم
                    _buildInteractiveQuizCard(isDark, quizQuestions),

                    const SizedBox(height: 16),

                    // 9. التعليقات والنقاشات وطرح سؤال للأستاذ
                    _buildCommentsAndTeacherQACard(isDark),

                    const SizedBox(height: 20),

                    // 10. الدروس التالية المقترحة
                    _buildSuggestedLessonsSection(isDark),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  2. بطاقة تحميل الفيديو للمشاهدة بدون إنترنت
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOfflineDownloadCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE1FF).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download_for_offline_rounded,
                  color: Color(0xFF00236F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحميل الفيديو للمشاهدة بدون إنترنت',
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF191C1E),
                      ),
                    ),
                    Text(
                      'اختر الجودة المناسبة لتحميل الفيديو على جهازك',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : const Color(0xFF757682),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 0.5,
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _qualityButton('HD', 'HD - 340 MB', isDark),
                  const SizedBox(width: 8),
                  _qualityButton('SD', 'SD - 150 MB', isDark),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _isDownloaded
                      ? const Color(0xFF10B981)
                      : const Color(0xFF00236F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isDownloaded
                            ? Icons.check_circle_rounded
                            : Icons.download_rounded,
                        size: 16,
                      ),
                label: Text(
                  _isDownloading
                      ? '${(_downloadPercent * 100).toInt()}%'
                      : _isDownloaded
                          ? 'تم التنزيل'
                          : 'تحميل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isDownloading || _isDownloaded ? null : _handleDownload,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qualityButton(String value, String label, bool isDark) {
    final isSelected = _downloadQuality == value;
    return InkWell(
      onTap: () => setState(() => _downloadQuality = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00236F)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFECEEF0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF444651)),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  3. شارات الدرس والعنوان
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLessonHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDBE1FF).withValues(alpha: isDark ? 0.2 : 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.level.code} • ${widget.subject.title}',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF00236F),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF85F8C4).withValues(alpha: isDark ? 0.2 : 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: Color(0xFF004A32),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'محتوى مدقق',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF004A32),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: isDark ? Colors.white54 : const Color(0xFF757682),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentLesson.viewsCount > 1000 ? '${(_currentLesson.viewsCount / 1000).toStringAsFixed(1)}k' : _currentLesson.viewsCount} مشاهدة',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF757682),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _currentLesson.title,
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF191C1E),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  4. بطاقة الأستاذ
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTeacherCard(bool isDark) {
    final tName = _teacher?.name ?? _currentLesson.teacherName ?? 'الأستاذ أمين شريفي';
    final tPhoto = _teacher?.effectivePhotoUrl ?? _currentLesson.teacherPhotoUrl ?? '';
    final tSpecialty = _teacher?.specialty ?? 'خبير مادة العلوم الفيزيائية للمرحلة الثانوية';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00236F).withValues(alpha: 0.1),
              border: Border.all(
                color: const Color(0xFF0051D5).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: tPhoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: tPhoto,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF00236F),
                      size: 26,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF00236F),
                    size: 26,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tName,
                      style: GoogleFonts.tajawal(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF191C1E),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: Color(0xFF0051D5),
                    ),
                  ],
                ),
                Text(
                  tSpecialty,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF444651),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              if (_teacher != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeacherProfileScreen(teacher: _teacher!),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFECEEF0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الدروس',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF00236F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 11,
                    color: Color(0xFF00236F),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  5. وصف الدرس
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDescriptionCard(bool isDark) {
    final desc = _currentLesson.description.isNotEmpty
        ? _currentLesson.description
        : 'في هذا الدرس الشامل، سنتناول بعمق تفصيلي مفاهيم التحولات النووية (الاندماج والانشطار)، وكيفية حساب طاقة الربط النووي لكل نكليون، مع التطبيق العملي على نمذجة تناقص الإشعاع ونشاط العينات الحية. يتضمن الشرح حل 3 تمارين استنتاجية من بكالوريات سابقة بخطوات منهجية مبسطة.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_rounded,
                color: Color(0xFF00236F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'وصف الدرس',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF444651),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  6. ملفات الدرس المرفقة PDF
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAttachedFilesCard(bool isDark) {
    final files = _currentLesson.pdfFiles.isNotEmpty
        ? _currentLesson.pdfFiles
        : [
            const VideoAttachment(
              id: 'sample_pdf_1',
              title: 'ملخص القوانين ونماذج التمارين المقترحة.pdf',
              url: 'https://meraj3iapp.web.app',
              type: 'summary',
              fileSize: '2.4 ميجابايت',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_open_rounded,
                color: Color(0xFF00236F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'ملفات الدرس المرفقة',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.map((file) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'PDF',
                        style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.title,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF191C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${file.fileSize.isNotEmpty ? file.fileSize : '2.4 ميجابايت'} • تم التحميل 1.2k مرة',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: isDark ? Colors.white54 : const Color(0xFF757682),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_rounded, size: 20),
                    color: const Color(0xFF00236F),
                    tooltip: 'معاينة الملف داخل التطبيق',
                    onPressed: () => _openInAppPdfViewer(file),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded, size: 20),
                    color: const Color(0xFF0051D5),
                    tooltip: 'تحميل الملف',
                    onPressed: () async {
                      final uri = Uri.tryParse(file.url);
                      if (uri != null && file.url.startsWith('http')) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم بدء تحميل ملف PDF...')),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  7. مركز ملاحظات الطالب الخاصة مع وسوم الوقت
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStudentNotesCenter(bool isDark) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF00236F),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ملاحظاتك الخاصة',
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBE1FF).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'مزامنة تلقائية',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00236F),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: GoogleFonts.cairo(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'اكتب ملاحظتك هنا وسيتم ربطها بالتوقيت الحالي للفيديو...',
              hintStyle: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark ? Colors.white38 : const Color(0xFF757682),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _timestampTagButton(312, '⏱ 05:12 (قانون التناقص)', isDark),
                    _timestampTagButton(860, '⏱ 14:20 (طاقة الربط)', isDark),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00236F),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isSavingNote
                    ? null
                    : () => _saveNoteWithTimestamp(_lastPositionSeconds, 'ملاحظة عامة'),
                child: _isSavingNote
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'حفظ الملاحظة',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // قائمة الملاحظات المحفوظة
          StreamBuilder<List<VideoNote>>(
            stream: _service.streamTimestampNotes(userId, _currentLesson.id),
            builder: (context, snap) {
              final notes = snap.data ?? [];
              if (notes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0051D5)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'اضغط على أي وسم وقت أعلاه لربط الملاحظة باللحظة الدقيقة داخل الشرح.',
                          style: GoogleFonts.cairo(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: notes.map((note) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBE1FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⏱ ${note.formattedTimestamp}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00236F),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.content,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          onPressed: () => _service.deleteTimestampNote(note.id),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _timestampTagButton(int seconds, String label, bool isDark) {
    return InkWell(
      onTap: () {
        _saveNoteWithTimestamp(seconds, label);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFECEEF0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: isDark ? Colors.white70 : const Color(0xFF444651),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  8. اختبار قصير تفاعلي لتقييم الفهم
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildInteractiveQuizCard(bool isDark, List<VideoQuizQuestion> questions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.quiz_rounded,
                color: Color(0xFF00236F),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'اختبار قصير لتقييم الفهم',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // بطاقة النتيجة عند التقييم
          if (_quizEvaluated)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF85F8C4).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF004A32)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, color: Color(0xFF004A32), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'النتيجة: $_quizScore/${questions.length} - ${_quizScore == questions.length ? 'ممتاز! لقد أجبت بشكل صحيح على جميع الأسئلة' : 'عمل جيد! راجع الإجابات وحاول مجدداً'}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003120),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('إعادة'),
                    onPressed: _resetQuiz,
                  ),
                ],
              ),
            ),

          // الأسئلة
          ...questions.asMap().entries.map((entry) {
            final qIndex = entry.key;
            final q = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...q.options.asMap().entries.map((optEntry) {
                    final optIndex = optEntry.key;
                    final optText = optEntry.value;
                    final isSelected = _selectedAnswers[qIndex] == optIndex;
                    final isCorrect = optIndex == q.correctIndex;

                    Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6);
                    Color borderColor = Colors.transparent;
                    IconData? statusIcon;

                    if (_quizEvaluated) {
                      if (isCorrect) {
                        bgColor = const Color(0xFF85F8C4).withValues(alpha: 0.35);
                        borderColor = const Color(0xFF004A32);
                        statusIcon = Icons.check_circle_rounded;
                      } else if (isSelected && !isCorrect) {
                        bgColor = const Color(0xFFFFDAD6);
                        borderColor = const Color(0xFFBA1A1A);
                        statusIcon = Icons.cancel_rounded;
                      }
                    } else if (isSelected) {
                      bgColor = const Color(0xFFDBE1FF);
                      borderColor = const Color(0xFF00236F);
                    }

                    return InkWell(
                      onTap: _quizEvaluated
                          ? null
                          : () => setState(() => _selectedAnswers[qIndex] = optIndex),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: optIndex,
                              groupValue: _selectedAnswers[qIndex],
                              activeColor: const Color(0xFF00236F),
                              onChanged: _quizEvaluated
                                  ? null
                                  : (v) => setState(() => _selectedAnswers[qIndex] = v!),
                            ),
                            Expanded(
                              child: Text(
                                optText,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                                  fontWeight: isSelected || (_quizEvaluated && isCorrect)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (statusIcon != null)
                              Icon(
                                statusIcon,
                                size: 18,
                                color: isCorrect
                                    ? const Color(0xFF004A32)
                                    : const Color(0xFFBA1A1A),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),

          if (!_quizEvaluated)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00236F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _selectedAnswers.isEmpty ? null : () => _checkQuiz(questions),
                child: Text(
                  'تحقق من الإجابة',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  9. التعليقات والنقاشات وطرح سؤال للأستاذ
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCommentsAndTeacherQACard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_rounded, color: Color(0xFF00236F), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'التعليقات والنقاشات',
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF191C1E),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBE1FF).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '(24) تعليق',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00236F),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // صندوق سؤال خاص للأستاذ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDBE1FF).withValues(alpha: isDark ? 0.15 : 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00236F).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF00236F)),
                        const SizedBox(width: 6),
                        Text(
                          'طرح سؤال جديد على الأستاذ',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00236F),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00236F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'سؤال حصري',
                        style: GoogleFonts.cairo(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _teacherQuestionCtrl,
                  maxLines: 2,
                  style: GoogleFonts.cairo(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك المفصل الموجه حصرياً للأستاذ...',
                    hintStyle: GoogleFonts.cairo(fontSize: 11.5, color: const Color(0xFF757682)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                      icon: const Icon(Icons.attach_file_rounded, size: 16),
                      label: Text('إرفاق صورة', style: GoogleFonts.cairo(fontSize: 11)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تفعيل إرفاق الصور والملفات')),
                        );
                      },
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0051D5),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSendingTeacherQuestion ? null : _submitTeacherQuestion,
                      child: _isSendingTeacherQuestion
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('إرسال السؤال', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (_showTeacherQuestionSuccess) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF85F8C4).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF004A32)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'تم إرسال سؤالك إلى الأستاذ بنجاح وسيتم الرد عليك قريباً',
                            style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF003120)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // كتابة تعليق عام
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            style: GoogleFonts.cairo(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'اكتب سؤالك أو استفسارك حول الدرس ليجيب عليه الأستاذ أو الزملاء...',
              hintStyle: GoogleFonts.cairo(fontSize: 11.5, color: const Color(0xFF757682)),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00236F),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isPostingComment ? null : _postGeneralComment,
              child: _isPostingComment
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('نشر التعليق', style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 14),

          // قائمة التعليقات من Firestore مع عناصر نموذجية
          StreamBuilder<List<VideoComment>>(
            stream: _service.streamComments(_currentLesson.id),
            builder: (context, snap) {
              final comments = snap.data ?? [];

              // إذا كانت القائمة فارغة، نعرض مناقشات تفاعلية نموذجية تطابق التصميم
              if (comments.isEmpty) {
                return Column(
                  children: [
                    _buildCommentItem(
                      name: 'يوسف بن عيسى',
                      role: 'طالب',
                      time: 'منذ ساعتين',
                      text: 'أستاذ، هل يمكننا دائماً إهمال كتلة الإلكترونات في حساب نقص الكتلة (Δm) أم في حالات معينة فقط؟ شكراً على الشرح الرائع.',
                      likes: 12,
                      isTeacher: false,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildCommentItem(
                        name: 'الأستاذ أمين شريفي',
                        role: 'المعلم',
                        time: 'منذ ساعة',
                        text: 'أهلاً بك يا يوسف. عادة نهمل كتلة الإلكترونات لأنها صغيرة جداً مقارنة بكتلة النواة، لكن في بعض التمارين الخاصة بتحولات معينة يُطلب أخذها بعين الاعتبار إذا ذُكرت في نص التمرين.',
                        likes: 25,
                        isTeacher: true,
                        isDark: isDark,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: comments.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCommentItem(
                      name: c.userName,
                      role: c.userRole,
                      time: 'الآن',
                      text: c.content,
                      likes: c.likesCount,
                      isTeacher: c.userRole == 'المعلم' || c.userRole == 'أستاذ المادة',
                      isDark: isDark,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem({
    required String name,
    required String role,
    required String time,
    required String text,
    required int likes,
    required bool isTeacher,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTeacher
            ? const Color(0xFFDBE1FF).withValues(alpha: isDark ? 0.2 : 0.5)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF2F4F6)),
        borderRadius: BorderRadius.circular(12),
        border: isTeacher
            ? Border.all(color: const Color(0xFF00236F).withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTeacher
                          ? const Color(0xFF00236F)
                          : const Color(0xFF1E3A8A).withValues(alpha: 0.8),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : 'م',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                          ),
                          if (isTeacher) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: Color(0xFF0051D5),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        time,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: isDark ? Colors.white54 : const Color(0xFF757682),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isTeacher
                      ? const Color(0xFF00236F)
                      : (isDark ? Colors.white12 : const Color(0xFFECEEF0)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isTeacher
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF444651)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF444651),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF757682)),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF757682)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 15, color: Color(0xFF757682)),
                    const SizedBox(width: 4),
                    Text('رد', style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF757682))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  10. الدروس التالية المقترحة
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSuggestedLessonsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الدروس التالية المقترحة',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1E),
              ),
            ),
            Text(
              'عرض الكل (${widget.playlist.length})',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: const Color(0xFF0051D5),
                fontWeight: FontWeight.bold,
              ),
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
                  ? const Color(0xFFDBE1FF).withValues(alpha: isDark ? 0.2 : 0.5)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0051D5)
                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              leading: Container(
                width: 70,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF00236F).withValues(alpha: 0.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.effectiveThumbnailUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.effectiveThumbnailUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.play_circle_filled_rounded,
                          color: Color(0xFF00236F),
                        ),
                      )
                    : const Icon(
                        Icons.play_circle_filled_rounded,
                        color: Color(0xFF00236F),
                      ),
              ),
              title: Text(
                item.title,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0051D5)
                      : (isDark ? Colors.white : const Color(0xFF191C1E)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.teacherName ?? 'أستاذ مراجعي'} • ${item.duration.isNotEmpty ? item.duration : '38:15'}',
                style: GoogleFonts.cairo(
                  fontSize: 10.5,
                  color: isDark ? Colors.white54 : const Color(0xFF757682),
                ),
              ),
              trailing: item.isPro
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF003120),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF85F8C4),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () => _switchLesson(item),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  نافذة عارض الـ PDF الداخلي المدمج
// ─────────────────────────────────────────────────────────────────────────────
class _InAppPdfModal extends StatefulWidget {
  final VideoAttachment file;

  const _InAppPdfModal({required this.file});

  @override
  State<_InAppPdfModal> createState() => _InAppPdfModalState();
}

class _InAppPdfModalState extends State<_InAppPdfModal> {
  int _currentPage = 1;
  final int _totalPages = 4;
  double _zoomScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // شريط الرأس
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECEEF0),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'PDF',
                      style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.file.title,
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in_rounded, size: 20),
                  onPressed: () => setState(() => _zoomScale = (_zoomScale + 0.1).clamp(0.8, 1.8)),
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out_rounded, size: 20),
                  onPressed: () => setState(() => _zoomScale = (_zoomScale - 0.1).clamp(0.8, 1.8)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // محتوى صفحة PDF
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Transform.scale(
                scale: _zoomScale,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مذكرة التحولات النووية - ملخص شامل',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00236F),
                            ),
                          ),
                          Text(
                            'الصفحة $_currentPage من $_totalPages',
                            style: GoogleFonts.cairo(fontSize: 11, color: const Color(0xFF757682)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBE1FF).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '1. قانون التناقص الإشعاعي',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00236F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'عدد النوى غير المتفككة عند اللحظة t يعطى بالعلاقة الأساسية:\nN(t) = N₀ · e^(-λt)\nحيث λ هو ثابت النشاط الإشعاعي ويقدر بـ (s⁻¹)، وعمر النصف t½ يرتبط به بالعلاقة: t½ = ln(2) / λ',
                        style: GoogleFonts.cairo(fontSize: 12, height: 1.6, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBE1FF).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '2. طاقة الربط النووي ونقص الكتلة',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00236F),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'نقص الكتلة Δm لنواة (Z, A) مكونة من Z بروتون و (A-Z) نيوترون:\nΔm = [Z·m(p) + (A-Z)·m(n)] - m(nucleus)\nوتحسب طاقة الربط النووي El بضرب نقص الكتلة في مربع سرعة الضوء:\nEl = Δm · c²',
                        style: GoogleFonts.cairo(fontSize: 12, height: 1.6, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // شريط التنقل السفلي
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECEEF0),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('السابق'),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text(
                  '$_currentPage / $_totalPages',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00236F)),
                  label: const Text('التالي'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  onPressed: _currentPage < _totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
