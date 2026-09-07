import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/app_config_provider.dart';
import 'student_competition_screen.dart';
import 'results/results_home_screen.dart';
import 'ai_search_screen.dart';
import 'direct_chat_screen.dart';
import 'downloads_screen.dart';
import 'swedd_screen.dart';
import 'exam_generator_screen.dart';
import 'student/reading_list_screen.dart';
import 'student/progress_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'جميع الخدمات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _backgroundShape(
              220,
              AppTheme.primaryColor.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -60,
            child: _backgroundShape(
              260,
              AppTheme.secondaryColor.withValues(alpha: 0.08),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'اختر الخدمة التي تناسبك',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _buildAllServicesGrid(context, size, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundShape(double size, Color color) {
    return Transform.rotate(
      angle: -0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
      ),
    );
  }

  void _checkFeatureAndNavigate(
    BuildContext context,
    String? featureKey,
    Widget screen,
  ) {
    if (featureKey != null) {
      final isEnabled = context.read<AppConfigProvider>().isFeatureEnabled(
        featureKey,
      );
      if (!isEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'هذه الخدمة قيد الصيانة حالياً',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildAllServicesGrid(BuildContext context, Size size, bool isDark) {
    final services = [
      _ServiceItem(
        title: 'التنافس بين الطلاب',
        icon: Icons.emoji_events_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: 'جديد',
        onTap: () => _checkFeatureAndNavigate(
          context,
          'competition_enabled',
          const StudentCompetitionScreen(),
        ),
      ),
      _ServiceItem(
        title: 'نتائج المسابقات',
        icon: Icons.leaderboard_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: null,
        onTap: () => _checkFeatureAndNavigate(
          context,
          'results_enabled',
          const ResultsHomeScreen(),
        ),
      ),
      _ServiceItem(
        title: 'MERAJ3I AI',
        icon: Icons.auto_awesome_rounded,
        gradient: AppTheme.purpleGradient,
        badge: 'AI',
        onTap: () => _checkFeatureAndNavigate(
          context,
          'ai_enabled',
          const AiSearchScreen(),
        ),
      ),
      _ServiceItem(
        title: 'المراسلة',
        icon: Icons.chat_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: 'جديد',
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const DirectChatScreen()),
      ),
      _ServiceItem(
        title: 'التنزيلات',
        icon: Icons.download_for_offline_rounded,
        gradient: AppTheme.greenGradient,
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const DownloadsScreen()),
      ),
      _ServiceItem(
        title: 'SWEDD',
        icon: Icons.health_and_safety_rounded,
        gradient: AppTheme.pinkGradient,
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const SweddScreen()),
      ),
      _ServiceItem(
        title: 'الاختبارات',
        icon: Icons.quiz_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => _checkFeatureAndNavigate(
          context,
          'quizzes_enabled',
          const ExamGeneratorScreen(),
        ),
      ),
      _ServiceItem(
        title: 'قائمة القراءة',
        icon: Icons.menu_book_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const ReadingListScreen()),
      ),
      _ServiceItem(
        title: 'تطور المستوى',
        icon: Icons.trending_up_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const ProgressScreen()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 3 ? 1.05 : 1.15,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            return _buildServiceCard(s, isDark);
          },
        );
      },
    );
  }

  Widget _buildServiceCard(_ServiceItem service, bool isDark) {
    return GestureDetector(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (service.gradient as LinearGradient).colors.first
                  .withValues(alpha: isDark ? 0.18 : 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : (service.gradient as LinearGradient).colors.first.withValues(
                    alpha: 0.12,
                  ),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: service.gradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: service.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (service.gradient as LinearGradient)
                              .colors
                              .first
                              .withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(service.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service.title,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0A1A15),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (service.badge != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: service.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    service.badge!,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final String? badge;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.badge,
    required this.onTap,
  });
}
