import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/remote_config_service.dart';
import '../../services/results_service.dart';
import '../../models/competition_model.dart';
import '../../providers/favorite_results_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/results_skeleton.dart';
import 'results_list_screen.dart';
import 'global_search_screen.dart';

// ─── Gradient helpers per type ──────────────────────────────────────────────

Gradient _gradientForType(CompetitionType type) {
  switch (type) {
    case CompetitionType.concours:
      return AppTheme.deepBlueGradient;
    case CompetitionType.brevet:
      return AppTheme.greenGradient;
    case CompetitionType.bac:
      return AppTheme.secondaryGradient;
    case CompetitionType.complementary:
      return AppTheme.purpleGradient;
    case CompetitionType.excellence:
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    case CompetitionType.generic:
      return const LinearGradient(
        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  }
}

ExamType _examTypeFor(CompetitionType t) {
  switch (t) {
    case CompetitionType.concours: return ExamType.concours;
    case CompetitionType.brevet: return ExamType.brevet;
    case CompetitionType.bac: return ExamType.bac;
    case CompetitionType.complementary: return ExamType.complementary;
    case CompetitionType.excellence: return ExamType.excellence;
    case CompetitionType.generic: return ExamType.bac;
  }
}

double _passScoreFor(CompetitionType t) =>
    t == CompetitionType.concours ? 85.0 : 10.0;
double _maxScoreFor(CompetitionType t) =>
    t == CompetitionType.concours ? 200.0 : 20.0;
String _scoreLabelFor(CompetitionType t) =>
    t == CompetitionType.concours ? 'المجموع' : 'المعدل';
bool _showBranchFor(CompetitionType t) =>
    t == CompetitionType.bac || t == CompetitionType.complementary || t == CompetitionType.generic;

// ────────────────────────────────────────────────────────────────────────────

class ResultsHomeScreen extends StatefulWidget {
  const ResultsHomeScreen({super.key});

  @override
  State<ResultsHomeScreen> createState() => _ResultsHomeScreenState();
}

class _ResultsHomeScreenState extends State<ResultsHomeScreen> {
  bool _loading = true;
  String? _error;
  List<CompetitionModel> _competitions = [];

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = _competitions.isEmpty;
      _error = null;
    });
    try {
      final service = RemoteConfigService.instance;
      await service.initialize();
      final list = await service.fetchCompetitions(forceRefresh: forceRefresh);
      if (mounted) setState(() => _competitions = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذر تحميل معلومات المسابقات.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRefresh() => _loadCompetitions(forceRefresh: true);

  void _navigateToComp(CompetitionModel comp) {
    if (!comp.isPublished || comp.link.isEmpty) return;
    final gradient = _gradientForType(comp.type);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsListScreen(
          title: comp.title,
          csvUrl: comp.link,
          examType: _examTypeFor(comp.type),
          gradient: gradient,
          emoji: comp.displayEmoji,
          passScore: _passScoreFor(comp.type),
          maxScore: _maxScoreFor(comp.type),
          scoreLabel: _scoreLabelFor(comp.type),
          showBranch: _showBranchFor(comp.type),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // قسّم المسابقات إلى أساسية وامتياز وإضافية
    final main = _competitions.where((c) =>
      c.type == CompetitionType.concours ||
      c.type == CompetitionType.brevet ||
      c.type == CompetitionType.bac ||
      c.type == CompetitionType.complementary
    ).toList();

    final excellence = _competitions.where((c) => c.type == CompetitionType.excellence).toList();
    final extra = _competitions.where((c) => c.type == CompetitionType.generic).toList();

    // المفضلة
    final favorites = context.watch<FavoriteResultsProvider>().items;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GlobalSearchScreen(competitions: _competitions),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  '🏆 نتائج المسابقات الوطنية',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 24),
                          child: Icon(Icons.emoji_events_rounded, size: 48, color: Colors.white12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: HomeSkeleton(),
                    )
                  : _error != null
                      ? _buildError()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── بحث سريع ──
                              _buildSearchBar(),
                              const SizedBox(height: 20),

                              // ── المسابقات الأساسية ──
                              if (main.isNotEmpty) ...[
                                _sectionLabel('📋 المسابقات الأساسية', isDark),
                                const SizedBox(height: 10),
                                _buildDynamicGrid(main, isDark),
                                const SizedBox(height: 20),
                              ],

                              // ── الامتياز ──
                              if (excellence.isNotEmpty) ...[
                                _sectionLabel('⭐ نتائج الامتياز', isDark),
                                const SizedBox(height: 10),
                                _buildExcellenceRow(excellence, isDark),
                                const SizedBox(height: 20),
                              ],

                              // ── مسابقات إضافية ديناميكية ──
                              if (extra.isNotEmpty) ...[
                                _sectionLabel('📝 مسابقات أخرى', isDark),
                                const SizedBox(height: 10),
                                _buildDynamicGrid(extra, isDark),
                                const SizedBox(height: 20),
                              ],

                              // ── المفضلة ──
                              if (favorites.isNotEmpty) ...[
                                _sectionLabel('❤️ نتائجك المفضلة', isDark),
                                const SizedBox(height: 10),
                                _buildFavoritesSection(favorites, isDark),
                                const SizedBox(height: 20),
                              ],

                              // ── معلومات التحديث ──
                              _buildCacheInfo(isDark),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'اسحب للأسفل لتحديث النتائج من المصدر مباشرة.',
                                        style: GoogleFonts.tajawal(fontSize: 12, color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GlobalSearchScreen(competitions: _competitions)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            Text(
              'ابحث عن طالب، مدرسة، ولاية...',
              style: GoogleFonts.tajawal(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicGrid(List<CompetitionModel> items, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items.map((comp) {
        return _buildCompCard(
          emoji: comp.displayEmoji,
          label: comp.title,
          gradient: _gradientForType(comp.type),
          published: comp.isPublished,
          isDark: isDark,
          onTap: comp.isPublished ? () => _navigateToComp(comp) : null,
        );
      }).toList(),
    );
  }

  Widget _buildExcellenceRow(List<CompetitionModel> items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Row(
      children: items.take(2).map((comp) {
        final color = comp.rawKey.contains('concours')
            ? const Color(0xFFF59E0B)
            : const Color(0xFF8B5CF6);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: comp.isPublished ? () => _navigateToComp(comp) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: comp.isPublished
                      ? color.withValues(alpha: 0.12)
                      : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: comp.isPublished
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                  border: Border.all(
                    color: comp.isPublished
                        ? color.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Text(comp.displayEmoji, style: TextStyle(fontSize: 22, color: comp.isPublished ? null : Colors.grey[400])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comp.title,
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: comp.isPublished ? (isDark ? Colors.white : Colors.black87) : Colors.grey[400],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            comp.isPublished ? 'متاح' : 'قريباً...',
                            style: GoogleFonts.tajawal(fontSize: 10, color: comp.isPublished ? color : Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFavoritesSection(List<FavoriteResultItem> favorites, bool isDark) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = favorites[i];
          final statusColor = item.result.isPassed
              ? const Color(0xFF16A34A)
              : item.result.status == 'الدورة التكميلية'
                  ? Colors.blue
                  : Colors.red;
          return GestureDetector(
            onTap: () {
              // البحث عن المسابقة المناسبة للانتقال إليها
              final comp = _competitions.firstWhere(
                (c) => _examTypeFor(c.type) == item.examType,
                orElse: () => _competitions.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultsListScreen(
                    title: item.title,
                    csvUrl: comp.link,
                    examType: item.examType,
                    gradient: _gradientForType(comp.type),
                    emoji: comp.displayEmoji,
                    passScore: _passScoreFor(comp.type),
                    maxScore: _maxScoreFor(comp.type),
                    scoreLabel: _scoreLabelFor(comp.type),
                    showBranch: _showBranchFor(comp.type),
                    initialSearchQuery: item.result.name.isNotEmpty ? item.result.name : item.result.id,
                  ),
                ),
              );
            },
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.result.name.isNotEmpty ? item.result.name : item.result.id,
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.result.status,
                    style: GoogleFonts.tajawal(
                      fontSize: 11, fontWeight: FontWeight.bold, color: statusColor,
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

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildCompCard({
    required String emoji,
    required String label,
    required Gradient gradient,
    required bool published,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: published ? gradient : null,
          color: published
              ? null
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          boxShadow: published
              ? [
                  BoxShadow(
                    color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
          border: published
              ? null
              : Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: TextStyle(fontSize: 22, color: published ? null : Colors.grey[400])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: published ? Colors.white : Colors.grey[400],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      published ? 'النتائج متاحة' : 'قريبًا...',
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: published ? Colors.white70 : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (published)
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCacheInfo(bool isDark) {
    final firstComp = _competitions.isNotEmpty ? _competitions.first : null;
    if (firstComp == null) return const SizedBox.shrink();
    return FutureBuilder<DateTime?>(
      future: ResultsService.lastUpdated(_examTypeFor(firstComp.type), firstComp.link),
      builder: (context, snap) {
        final dt = snap.data;
        if (dt == null) return const SizedBox.shrink();
        final diff = DateTime.now().difference(dt);
        String timeAgo;
        if (diff.inMinutes < 2) {
          timeAgo = 'منذ لحظات';
        } else if (diff.inMinutes < 60) {
          timeAgo = 'منذ ${diff.inMinutes} دقيقة';
        } else if (diff.inHours < 24) {
          timeAgo = 'منذ ${diff.inHours} ساعة';
        } else {
          timeAgo = 'منذ ${diff.inDays} يوم';
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.update_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                'آخر تحديث: $timeAgo',
                style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? Colors.white38 : Colors.grey[500]),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _onRefresh,
                child: Text(
                  'تحديث الآن',
                  style: GoogleFonts.tajawal(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.tajawal(fontSize: 15, color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      ),
    );
  }
}
