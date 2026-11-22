import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/video_lesson_models.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/video_lesson_service.dart';
import '../../../services/video_download_service.dart';
import 'video_subjects_screen.dart';
import 'video_player_screen.dart';
import 'video_downloads_screen.dart';
import 'widgets/video_lesson_card.dart';

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
  return _LevelConfig(
    code: level.code,
    title: level.title,
    subtitle: level.code,
    icon: Icons.video_library_rounded,
    gradient: const [Color(0xFF334155), Color(0xFF64748B)],
  );
}

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

  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'BAC C', 'BAC D', '3AS', '4AS', 'Concours', '6AF'
  String _filterType = 'all'; // 'all', 'free', 'pro'
  int _downloadedCount = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<String> _categories = [
    'الكل',
    'BAC C',
    'BAC D',
    '3AS',
    '4AS',
    'كونكور',
    '6AF',
  ];

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
  }

  Future<void> _checkDownloads() async {
    final list = await _downloadService.getAllDownloads();
    if (mounted) setState(() => _downloadedCount = list.length);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  bool _matchesCategory(VideoLesson l, String category) {
    if (category == 'all' || category == 'الكل') return true;
    final lvl = l.levelId.toLowerCase();
    switch (category) {
      case 'BAC C':
        return lvl == 'bac_c' || lvl.contains('bac_c') || lvl.contains('bac c') || l.title.contains('BAC C') || l.title.contains('رياضيات');
      case 'BAC D':
        return lvl == 'bac_d' || lvl.contains('bac_d') || lvl.contains('bac d') || l.title.contains('BAC D') || l.title.contains('علوم');
      case '3AS':
        return lvl == '3as' || lvl.contains('3as') || l.title.contains('3AS') || l.title.contains('الثالثة');
      case '4AS':
        return lvl == '4as' || lvl.contains('4as') || l.title.contains('4AS') || l.title.contains('الرابعة') || l.title.contains('بريفيه') || l.title.contains('ختم الدروس');
      case 'كونكور':
        return lvl == 'concours' || lvl.contains('concours') || lvl.contains('konkour') || l.title.contains('كونكور') || l.title.contains('دخول السنة الأولى');
      case '6AF':
        return lvl == '6af' || lvl.contains('6af') || l.title.contains('6AF') || l.title.contains('السادسة');
      default:
        return lvl.contains(category.toLowerCase()) || l.title.contains(category);
    }
  }

  void _openFilterModal(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تصفية الدروس المصورة',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 14),
              Text('نوع المحتوى:', style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterChoiceChip('all', 'جميع الدروس'),
                  _filterChoiceChip('free', 'مجاني فقط'),
                  _filterChoiceChip('pro', 'دروس Pro المميزة'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00236F)),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('تطبيق التصفية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChoiceChip(String key, String label) {
    final isSelected = _filterType == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF00236F),
      labelStyle: GoogleFonts.cairo(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (val) {
        setState(() => _filterType = key);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 1. الرأس العلوي مع شعار مراجعي وأيقونات الإجراءات
                _buildTopHeader(isDark),

                const SizedBox(height: 16),

                // 2. شريط البحث والفلاتر
                _buildSearchAndFilterBar(isDark),

                const SizedBox(height: 14),

                // 3. أزرار التبويبات الأفقية للمراحل الدراسية
                _buildCategoryPills(isDark),

                const SizedBox(height: 20),

                // 4. قسم "أكمل المشاهدة" (Continue Watching)
                if (_selectedCategory == 'all' || _selectedCategory == 'الكل') ...[
                  _buildContinueWatchingSection(userId, isDark),
                  const SizedBox(height: 24),
                ],

                // 5. قسم "أحدث الدروس المميزة" (Featured Lessons)
                _buildFeaturedLessonsSection(isDark, auth.isPro),

                if (_selectedCategory == 'all' || _selectedCategory == 'الكل') ...[
                  const SizedBox(height: 24),
                  // 6. قسم "الأكثر مشاهدة هذا الأسبوع" (Most Watched)
                  _buildMostWatchedSection(isDark),
                ],

                const SizedBox(height: 24),

                // 7. قسم التصفح حسب المراحل الدراسية الستة
                _buildStagesGridSection(isDark),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  1. الرأس العلوي
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مراجعي',
              style: GoogleFonts.tajawal(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00236F),
              ),
            ),
            Text(
              'الدروس المصورة • شاهد دروسك، افهم أكثر، وتابع طريقك نحو النجاح',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF757682),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Badge(
                isLabelVisible: _downloadedCount > 0,
                label: Text('$_downloadedCount'),
                child: const Icon(Icons.download_rounded, color: Color(0xFF00236F)),
              ),
              tooltip: 'التحميلات المحفوظة',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VideoDownloadsScreen()),
                );
                _checkDownloads();
              },
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00236F),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  2. شريط البحث والفلاتر
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchAndFilterBar(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: GoogleFonts.cairo(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ابحث عن درس، أستاذ، أو مادة تعليمية...',
                hintStyle: GoogleFonts.cairo(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : const Color(0xFF757682),
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757682), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => _openFilterModal(isDark),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.tune_rounded, color: Color(0xFF00236F), size: 22),
                if (_filterType != 'all')
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0051D5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  3. التبويبات الأفقية للمراحل
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryPills(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = (_selectedCategory == 'all' && cat == 'الكل') ||
              (_selectedCategory == cat);

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = (cat == 'الكل') ? 'all' : cat;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00236F)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF2F4F6)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00236F).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    cat,
                    style: GoogleFonts.cairo(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF444651)),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  4. أكمل المشاهدة (Continue Watching)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildContinueWatchingSection(String userId, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أكمل المشاهدة',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1E),
              ),
            ),
            Text(
              'متابعة التقدم',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: const Color(0xFF0051D5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // الشريط الأزرق الرأسي
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: 5,
                  color: const Color(0xFF0051D5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 18, 12),
                child: Row(
                  children: [
                    // الصورة المصغرة مع زر التشغيل
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 65,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFF00236F).withValues(alpha: 0.15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF00236F),
                              child: const Icon(Icons.school, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Color(0xFF00236F),
                            size: 20,
                          ),
                        ),
                        Positioned(
                          bottom: 3,
                          left: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '14:20 / 45:00',
                              style: TextStyle(color: Colors.white, fontSize: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الفيزياء والرياضيات - BAC C',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: const Color(0xFF0051D5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'المتتاليات العددية ودراسة إشارتها بالتفصيل',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.65,
                              minHeight: 5,
                              backgroundColor: Color(0xFFE6E8EA),
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0051D5)),
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
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  5. أحدث الدروس المميزة (Featured Lessons)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturedLessonsSection(bool isDark, bool isProUser) {
    return StreamBuilder<List<VideoLesson>>(
      stream: _service.streamLatestLessons(limit: 8),
      builder: (context, snap) {
        var lessons = snap.data ?? [];

        // تصفية حسب القسم المختار مع الفصل الصارم بين المسابقات
        if (_selectedCategory != 'all' && _selectedCategory != 'الكل') {
          lessons = lessons.where((l) => _matchesCategory(l, _selectedCategory)).toList();
        }

        // تصفية حسب نوع المحتوى (مجاني / Pro)
        if (_filterType == 'free') {
          lessons = lessons.where((l) => !l.isPro).toList();
        } else if (_filterType == 'pro') {
          lessons = lessons.where((l) => l.isPro).toList();
        }

        // تطبيق البحث
        if (_searchQuery.isNotEmpty) {
          lessons = lessons.where((l) {
            return l.title.toLowerCase().contains(_searchQuery) ||
                (l.teacherName?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();
        }

        if (lessons.isEmpty) {
          if (_selectedCategory != 'all' && _selectedCategory != 'الكل') {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.video_library_outlined, size: 44, color: isDark ? Colors.white38 : Colors.black26),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد فيديوهات مضافة حالياً لمرحلة / مسابقة «$_selectedCategory»',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سيتم إضافة دروس وشروحات نموذجية خاصة بهذه المسابقة قريباً',
                    style: GoogleFonts.cairo(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          // إذا كان الكل فارغاً، نعرض النماذج الافتراضية
          lessons = [
            VideoLesson(
              id: 'mock_lesson_pro_1',
              levelId: 'bac_c',
              subjectId: 'phys',
              title: 'المراجعة الشاملة في التحولات النووية وطرق حل التمارين المعقدة',
              description: 'شرح تفصيلي لطاقة الربط النووي والتناقص الإشعاعي مع حل تمارين بكالوريا نموذجية.',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
              duration: '58 دقيقة',
              isPro: true,
              teacherName: 'الأستاذ أمين شريفي',
              viewsCount: 3400,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            VideoLesson(
              id: 'mock_lesson_free_2',
              levelId: '6af',
              subjectId: 'phil',
              title: 'منهجية المقال الفلسفي وضمان العلامة الكاملة في البكالوريا',
              description: 'الخطوات الذهبية لكتابة مقال فلسفي مقارن أو استقصائي متكامل.',
              videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
              duration: '32 دقيقة',
              isPro: false,
              teacherName: 'د. فاطمة الزهراء',
              viewsCount: 8100,
              createdAt: DateTime.now().subtract(const Duration(days: 2)),
              updatedAt: DateTime.now(),
            ),
          ];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFF00236F),
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'أحدث الدروس المميزة',
                      style: GoogleFonts.tajawal(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
                Text(
                  'عرض الكل',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: const Color(0xFF0051D5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...lessons.map((lesson) {
              return VideoLessonCard(
                lesson: lesson,
                subjectName: lesson.isPro ? 'علوم تجريبية' : 'آداب وفلسفة',
                isProUser: isProUser,
                onTap: () {
                  final dummyLevel = VideoLevel(
                    id: lesson.levelId,
                    title: 'باكالوريا',
                    code: 'BAC',
                    description: '',
                  );
                  final dummySubject = VideoSubject(
                    id: lesson.subjectId,
                    levelId: lesson.levelId,
                    title: lesson.isPro ? 'العلوم الفيزيائية' : 'الفلسفة',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        lesson: lesson,
                        subject: dummySubject,
                        level: dummyLevel,
                        playlist: lessons,
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  6. الأكثر مشاهدة هذا الأسبوع (Most Watched)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMostWatchedSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF00236F),
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  'الأكثر مشاهدة هذا الأسبوع',
                  style: GoogleFonts.tajawal(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1E),
                  ),
                ),
              ],
            ),
            Text(
              'عرض الكل',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: const Color(0xFF0051D5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // بطاقة 1: اللغة الإنجليزية
        _buildMostWatchedCard(
          subject: 'اللغة الإنجليزية',
          views: '12k مشاهدة',
          title: 'كيفية كتابة وضعية إدماجية احترافية في الإنجليزية',
          teacher: 'الأستاذ خالد بوزيد',
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // بطاقة 2: هندسة مدنية
        _buildMostWatchedCard(
          subject: 'هندسة مدنية',
          views: '9.5k مشاهدة',
          title: 'دراسة الحركة المستوية لجسم صلب - الجزء الأول',
          teacher: 'الأستاذ مراد بلعربي',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMostWatchedCard({
    required String subject,
    required String views,
    required String title,
    required String teacher,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 84,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF00236F).withValues(alpha: 0.15),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF00236F),
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Color(0xFF00236F),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: const Color(0xFF0051D5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      views,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: const Color(0xFF757682),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF191C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  teacher,
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  7. المراحل الدراسية الستة المعتمدة
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStagesGridSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المراحل والأقسام الدراسية',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF191C1E),
              ),
            ),
            Text(
              '6 أقسام معتمدة',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                color: const Color(0xFF757682),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<VideoLevel>>(
          stream: _service.streamLevels(),
          initialData: VideoLessonService.defaultLevels,
          builder: (context, snapshot) {
            final levels = snapshot.data ?? VideoLessonService.defaultLevels;
            final allowedCodes = {'كونكور', '3AS', '4AS', 'BAC D', 'BAC C', '6AF'};
            var filtered = levels.where((l) {
              return allowedCodes.contains(l.code) ||
                  allowedCodes.any((c) => l.title.contains(c));
            }).toList();

            filtered.sort((a, b) {
              final ai = _kLevelConfigs.indexWhere((c) =>
                  a.code == c.code || a.title.contains(c.code));
              final bi = _kLevelConfigs.indexWhere((c) =>
                  b.code == c.code || b.title.contains(c.code));
              return ai.compareTo(bi);
            });

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final lvl = filtered[index];
                final cfg = _configForLevel(lvl);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoSubjectsScreen(level: lvl),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: cfg.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cfg.gradient.first.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(cfg.icon, color: Colors.white, size: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                cfg.code,
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cfg.title,
                              style: GoogleFonts.tajawal(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              cfg.subtitle,
                              style: GoogleFonts.cairo(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
