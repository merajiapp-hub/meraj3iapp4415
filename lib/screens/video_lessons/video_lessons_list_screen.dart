import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/video_lesson_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/video_lesson_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/curved_header.dart';
import '../../../widgets/pro_feature_gate.dart';
import 'widgets/video_lesson_card.dart';
import 'video_player_screen.dart';

class VideoLessonsListScreen extends StatefulWidget {
  final VideoLevel level;
  final VideoSubject subject;
  final VideoUnit? unit;

  const VideoLessonsListScreen({
    super.key,
    required this.level,
    required this.subject,
    this.unit,
  });

  @override
  State<VideoLessonsListScreen> createState() => _VideoLessonsListScreenState();
}

class _VideoLessonsListScreenState extends State<VideoLessonsListScreen> {
  final VideoLessonService _service = VideoLessonService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'free', 'pro'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleLessonTap(
    BuildContext context,
    VideoLesson lesson,
    List<VideoLesson> playlist,
  ) {
    final auth = context.read<AuthProvider>();

    // فحص صلاحية Pro
    if (lesson.isPro && !auth.isPro) {
      ProFeatureGate.showProLockedDialog(
        context: context,
        featureName: 'الدرس: ${lesson.title}',
      );
      return;
    }

    // الانتقال إلى مشغل الفيديو
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          lesson: lesson,
          subject: widget.subject,
          level: widget.level,
          unit: widget.unit,
          playlist: playlist,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    final subjectColor = Color(widget.subject.colorHex);

    final title = widget.unit != null
        ? widget.unit!.title
        : widget.subject.title;
    final subtitle = widget.unit != null
        ? '${widget.level.code} • ${widget.subject.title}'
        : widget.level.title;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // رأس الصفحة
          CurvedHeader(
            title: title,
            subtitle: subtitle,
            gradient: LinearGradient(
              colors: [
                subjectColor,
                subjectColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          // شريط البحث والتصفية
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن درس أو فيديو بالاسم...',
                    hintStyle: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // فلاتر: الكل، مجاني، Pro
                Row(
                  children: [
                    _buildFilterChip('all', 'جميع الدروس', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('free', 'المجانية فقط', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('pro', 'Pro المشتركين', isDark),
                  ],
                ),
              ],
            ),
          ),

          // قائمة الدروس مع متابعة التقدم والمفضلة
          Expanded(
            child: StreamBuilder<List<VideoLesson>>(
              stream: _service.streamLessons(
                levelId: widget.level.id,
                subjectId: widget.subject.id,
                unitId: widget.unit?.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allLessons = snapshot.data ?? [];
                if (allLessons.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.video_camera_back_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لم تتم إضافة دروس مصورة هنا بعد',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'سيتم رفع الشروحات قريباً من قبل إدارة التطبيق',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // تصفية حسب البحث ونوع الفيديو
                final filtered = allLessons.where((l) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      l.title.toLowerCase().contains(_searchQuery) ||
                      l.description.toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;

                  if (_selectedFilter == 'free') return !l.isPro;
                  if (_selectedFilter == 'pro') return l.isPro;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد دروس تطابق هذا البحث',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  );
                }

                // استماع لتقدم المستخدم
                return StreamBuilder<Map<String, bool>>(
                  stream: _service.streamSubjectProgress(
                    userId: userId,
                    subjectId: widget.subject.id,
                  ),
                  builder: (context, progSnap) {
                    final progressMap = progSnap.data ?? {};
                    final completedCount = allLessons
                        .where((l) => progressMap[l.id] == true)
                        .length;
                    final progressPercent = allLessons.isNotEmpty
                        ? (completedCount / allLessons.length)
                        : 0.0;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        // شريط تقدم الطالب في المادة
                        if (allLessons.isNotEmpty && userId.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: subjectColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'نسبة تقدمك في هذه المادة',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      '${(progressPercent * 100).toInt()}% ($completedCount من ${allLessons.length})',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: subjectColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progressPercent,
                                    minHeight: 7,
                                    backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(subjectColor),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // قائمة بطاقات الدروس
                        ...filtered.map((lesson) {
                          final isCompleted = progressMap[lesson.id] == true;

                          return VideoLessonCard(
                            lesson: lesson,
                            subjectName: widget.subject.title,
                            unitName: widget.unit?.title,
                            isCompleted: isCompleted,
                            isProUser: auth.isPro,
                            onTap: () => _handleLessonTap(context, lesson, filtered),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? AppTheme.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
