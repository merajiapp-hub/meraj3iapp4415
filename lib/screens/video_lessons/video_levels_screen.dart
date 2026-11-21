import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video_lesson_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/video_lesson_service.dart';
import '../../../services/video_download_service.dart';
import '../../../theme/app_theme.dart';
import 'video_subjects_screen.dart';
import 'video_player_screen.dart';
import 'video_downloads_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// تعريف الأقسام الستة المعتمدة بشكل static (لا tree-shaking)
// ─────────────────────────────────────────────────────────────────────────────
class _LevelConfig {
  final String code;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _LevelConfig({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

const List<_LevelConfig> _kLevelConfigs = [
  _LevelConfig(
    code: 'كونكور',
    title: 'الكونكور',
    subtitle: 'Concours',
    icon: Icons.school_rounded,
    gradient: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ),
  _LevelConfig(
    code: '3AS',
    title: 'السنة الثالثة ثانوي',
    subtitle: '3ème AS',
    icon: Icons.auto_stories_rounded,
    gradient: [Color(0xFF064E3B), Color(0xFF059669)],
  ),
  _LevelConfig(
    code: '4AS',
    title: 'السنة الرابعة ثانوي',
    subtitle: '4ème AS',
    icon: Icons.menu_book_rounded,
    gradient: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  ),
  _LevelConfig(
    code: 'BAC D',
    title: 'باكالوريا علوم',
    subtitle: 'BAC D - Sciences de la nature',
    icon: Icons.science_rounded,
    gradient: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
  ),
  _LevelConfig(
    code: 'BAC C',
    title: 'باكالوريا رياضيات',
    subtitle: 'BAC C - Mathématiques',
    icon: Icons.calculate_rounded,
    gradient: [Color(0xFF7C2D12), Color(0xFFEA580C)],
  ),
  _LevelConfig(
    code: '6AF',
    title: 'السنة السادسة ابتدائي',
    subtitle: '6ème AF',
    icon: Icons.history_edu_rounded,
    gradient: [Color(0xFF164E63), Color(0xFF0891B2)],
  ),
];

_LevelConfig _configForLevel(VideoLevel level) {
  for (final cfg in _kLevelConfigs) {
    if (level.code == cfg.code || level.title.contains(cfg.code)) {
      return cfg;
    }
  }
  // fallback
  return _LevelConfig(
    code: level.code,
    title: level.title,
    subtitle: level.code,
    icon: Icons.video_library_rounded,
    gradient: const [Color(0xFF334155), Color(0xFF64748B)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// الشاشة الرئيسية
// ─────────────────────────────────────────────────────────────────────────────
class VideoLevelsScreen extends StatefulWidget {
  const VideoLevelsScreen({super.key});

  @override
  State<VideoLevelsScreen> createState() => _VideoLevelsScreenState();
}

class _VideoLevelsScreenState extends State<VideoLevelsScreen>
    with SingleTickerProviderStateMixin {
  final VideoLessonService _service = VideoLessonService();
  final VideoDownloadService _downloadService = VideoDownloadService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  String _searchQuery = '';
  int _downloadedCount = 0;
  bool _headerCollapsed = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _checkDownloads();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed = _scrollCtrl.offset > 60;
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
  }

  Future<void> _checkDownloads() async {
    final list = await _downloadService.getAllDownloads();
    if (mounted) setState(() => _downloadedCount = list.length);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080F1E) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ─── الخلفية التزيينية ───
          _buildBackground(isDark),

          // ─── المحتوى الكامل ───
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══ الهيدر المتحرك ═══
              SliverToBoxAdapter(
                child: _buildHeroHeader(isDark, size),
              ),

              // ═══ شريط البحث + زر التنزيلات ═══
              SliverToBoxAdapter(
                child: _buildSearchBar(isDark),
              ),

              // ═══ قسم أكمل المشاهدة ═══
              if (userId.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildRecentWatchedSection(userId, isDark),
                ),

              // ═══ قسم أحدث الدروس ═══
              SliverToBoxAdapter(
                child: _buildLatestLessonsSection(isDark),
              ),

              // ═══ عنوان قسم المراحل ═══
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  isDark,
                  icon: Icons.layers_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'المراحل الدراسية المعتمدة',
                  badge: '6 أقسام',
                  badgeColor: const Color(0xFF6366F1),
                ),
              ),

              // ═══ بطاقات الأقسام ═══
              _buildLevelsGrid(isDark),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── خلفية تزيينية ───
  Widget _buildBackground(bool isDark) {
    return Positioned.fill(
      child: Stack(
        children: [
          // دائرة زرقاء خلفية علوية
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // دائرة بنفسجية سفلية
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.12 : 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── الهيدر الرئيسي المميز ───
  Widget _buildHeroHeader(bool isDark, Size size) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2460), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // نقاط زخرفية
          Positioned(
            top: 20,
            left: 20,
            child: _decorativeDot(60, 0.07),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: _decorativeDot(40, 0.05),
          ),
          Positioned(
            bottom: 30,
            left: 60,
            child: _decorativeDot(80, 0.06),
          ),

          // المحتوى
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شارة علوية
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 13, color: Colors.white70),
                            const SizedBox(width: 5),
                            Text(
                              'منصة الدروس المصورة',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // زر التنزيلات
                      _buildDownloadBadge(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // أيقونة وعنوان
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // أيقونة play circle مع توهج
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF60A5FA).withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_circle_filled_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الدروس المصورة',
                              style: GoogleFonts.tajawal(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'شروحات وفيديوهات تعليمية احترافية\nلجميع المراحل والأقسام الدراسية',
                              style: GoogleFonts.tajawal(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // إحصائيات سريعة
                  _buildQuickStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeDot(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildDownloadBadge() {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VideoDownloadsScreen()),
          );
          _checkDownloads();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
              if (_downloadedCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_downloadedCount',
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<List<VideoLevel>>(
      stream: _service.streamLevels(),
      initialData: VideoLessonService.defaultLevels,
      builder: (context, snap) {
        final levels = snap.data ?? [];
        return Row(
          children: [
            _statChip(Icons.layers_rounded, '${levels.length} أقسام'),
            const SizedBox(width: 10),
            _statChip(Icons.video_library_rounded, 'آلاف الدروس'),
            const SizedBox(width: 10),
            _statChip(Icons.wifi_off_rounded, 'بدون إنترنت'),
          ],
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── شريط البحث ───
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'ابحث عن درس، مادة، أو أستاذ...',
            hintStyle: GoogleFonts.tajawal(
              fontSize: 13.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6), size: 22),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─── عنوان قسم ───
  Widget _buildSectionHeader(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badge,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge,
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor ?? iconColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── قسم أحدث الدروس ───
  Widget _buildLatestLessonsSection(bool isDark) {
    return StreamBuilder<List<VideoLesson>>(
      stream: _service.streamLatestLessons(limit: 5),
      builder: (context, snapshot) {
        final lessons = snapshot.data ?? [];
        if (lessons.isEmpty) return const SizedBox.shrink();

        return FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                isDark,
                icon: Icons.new_releases_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'أحدث الدروس المضافة',
                badge: 'جديد',
                badgeColor: const Color(0xFFF59E0B),
              ),
              SizedBox(
                height: 145,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) =>
                      _buildLatestLessonCard(lessons[index], lessons, isDark),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLatestLessonCard(
      VideoLesson lesson, List<VideoLesson> playlist, bool isDark) {
    final thumb = lesson.effectiveThumbnailUrl;
    return GestureDetector(
      onTap: () {
        final dummyLevel =
            VideoLevel(id: lesson.levelId, title: '', code: '', description: '');
        final dummySubject =
            VideoSubject(id: lesson.subjectId, levelId: '', title: '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              lesson: lesson,
              subject: dummySubject,
              level: dummyLevel,
              playlist: playlist,
            ),
          ),
        );
      },
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(left: 12, bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة مصغرة مع زر play
            SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumb.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _thumbnailPlaceholder(isDark),
                    )
                  else
                    _thumbnailPlaceholder(isDark),
                  // تدرج علوي للنص
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // زر play
                  Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  // شارة جديد
                  if (lesson.isNew)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'جديد',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // معلومات الدرس
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: GoogleFonts.tajawal(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lesson.duration.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 11,
                            color: Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          lesson.duration,
                          style: GoogleFonts.tajawal(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
      child: const Icon(Icons.movie_rounded, color: Colors.white38, size: 36),
    );
  }

  // ─── قسم أكمل المشاهدة ───
  Widget _buildRecentWatchedSection(String userId, bool isDark) {
    return StreamBuilder<List<VideoProgress>>(
      stream: _service.streamRecentWatched(userId),
      builder: (context, snapshot) {
        final recent = snapshot.data ?? [];
        if (recent.isEmpty) return const SizedBox.shrink();

        return FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                isDark,
                icon: Icons.history_rounded,
                iconColor: AppTheme.primaryColor,
                title: 'أكمل المشاهدة',
              ),
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: recent.length,
                  itemBuilder: (context, index) =>
                      _buildWatchProgressCard(recent[index], isDark),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWatchProgressCard(VideoProgress prog, bool isDark) {
    final resumeM = prog.lastPositionSeconds ~/ 60;
    final resumeS = prog.lastPositionSeconds % 60;
    final resumeStr =
        '${resumeM.toString().padLeft(2, '0')}:${resumeS.toString().padLeft(2, '0')}';
    final pct = prog.progressPercent.clamp(0.0, 1.0);
    final isCompleted = prog.isCompleted;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(left: 12, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (isCompleted
                  ? const Color(0xFF10B981)
                  : AppTheme.primaryColor)
              .withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF1D4ED8), AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCompleted ? 'تم الإكمال ✓' : 'استئناف من $resumeStr',
                  style: GoogleFonts.tajawal(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'متابعة الدرس',
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // شريط التقدم
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    backgroundColor:
                        isDark ? Colors.white12 : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? const Color(0xFF10B981)
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── شبكة الأقسام ───
  Widget _buildLevelsGrid(bool isDark) {
    return StreamBuilder<List<VideoLevel>>(
      stream: _service.streamLevels(),
      initialData: VideoLessonService.defaultLevels,
      builder: (context, snapshot) {
        final levels = snapshot.data ?? VideoLessonService.defaultLevels;

        // تصفية صارمة للأقسام الستة المعتمدة
        final allowedCodes = {'كونكور', '3AS', '4AS', 'BAC D', 'BAC C', '6AF'};
        var filtered = levels.where((l) {
          return allowedCodes.contains(l.code) ||
              allowedCodes.any((c) => l.title.contains(c));
        }).toList();

        // تطبيق البحث
        if (_searchQuery.isNotEmpty) {
          filtered = filtered
              .where((l) =>
                  l.title.toLowerCase().contains(_searchQuery) ||
                  l.code.toLowerCase().contains(_searchQuery))
              .toList();
        }

        // ترتيب ثابت حسب قائمة _kLevelConfigs
        filtered.sort((a, b) {
          final ai = _kLevelConfigs.indexWhere((c) =>
              a.code == c.code || a.title.contains(c.code));
          final bi = _kLevelConfigs.indexWhere((c) =>
              b.code == c.code || b.title.contains(c.code));
          return ai.compareTo(bi);
        });

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 56, color: Colors.grey.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'لا توجد نتائج لـ "$_searchQuery"',
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => FadeTransition(
                opacity: _fadeAnim,
                child: _buildLevelCard(filtered[index], isDark, index),
              ),
              childCount: filtered.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  MediaQuery.of(context).size.width > 600 ? 1.45 : 1.18,
            ),
          ),
        );
      },
    );
  }

  // ─── بطاقة قسم واحد (تصميم رشيق ومدمج) ───
  Widget _buildLevelCard(VideoLevel level, bool isDark, int index) {
    final cfg = _configForLevel(level);
    final gradColors = cfg.gradient;
    final accentColor = gradColors.last;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoSubjectsScreen(level: level)),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250 + index * 40),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: gradColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // زخرفة دائرة خلفية
              Positioned(
                bottom: -15,
                left: -15,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // المحتوى المدمج
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─ أيقونة + شارة الكود والشارة الجديدة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cfg.icon, color: Colors.white, size: 22),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cfg.code,
                                style: GoogleFonts.tajawal(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            _buildNewBadge(level),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ─ اسم القسم
                    Text(
                      cfg.title,
                      style: GoogleFonts.tajawal(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // ─ الاسم الفرعي
                    Text(
                      cfg.subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // ─ إحصائيات المواد والدروس
                    _buildLevelStats(level, isDark),

                    const SizedBox(height: 6),

                    // ─ زر الدخول الرشيق
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ابدأ التعلم',
                            style: GoogleFonts.tajawal(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// شارة «جديد» — تظهر إن وجد درس حديث في هذا القسم
  Widget _buildNewBadge(VideoLevel level) {
    return StreamBuilder<List<VideoLesson>>(
      stream: _service.streamLatestLessons(limit: 20),
      builder: (context, snap) {
        final hasNew = (snap.data ?? [])
            .any((l) => l.levelId == level.id && l.isNew);
        if (!hasNew) return const SizedBox.shrink();
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(0xFF10B981).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text(
            'جديد',
            style: GoogleFonts.tajawal(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  /// إحصائيات عدد المواد والدروس
  Widget _buildLevelStats(VideoLevel level, bool isDark) {
    return StreamBuilder<List<VideoSubject>>(
      stream: _service.streamSubjects(level.id),
      builder: (context, snap) {
        final subjects = snap.data ?? [];
        return Row(
          children: [
            _miniStat(
                Icons.book_rounded, '${subjects.length} مادة'),
            const SizedBox(width: 8),
            // عدد الدروس من أول مادة (تقريب)
            _miniStat(Icons.play_circle_outline_rounded,
                subjects.isEmpty ? '...' : 'دروس متعددة'),
          ],
        );
      },
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.tajawal(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
