import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../providers/app_config_provider.dart';
import 'student_competition_screen.dart';
import 'results/results_home_screen.dart';
import 'direct_chat_screen.dart';
import 'swedd_screen.dart';
import 'published_exams_screen.dart';
import 'student/reading_list_screen.dart';
import 'student/progress_screen.dart';
import 'countdown_screen.dart';
import '../features/virtual_lab/pages/virtual_lab_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/pro_badge.dart';
import '../widgets/pro_feature_gate.dart';

import '../widgets/curved_header.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
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
          Column(
            children: [
              const CurvedHeader(
                title: 'جميع الخدمات',
                gradient: AppTheme.brandGradient,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: _buildAllServicesGrid(context, size, isDark),
                ),
              ),
            ],
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
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => _checkFeatureAndNavigate(
          context,
          'competition_enabled',
          const StudentCompetitionScreen(),
        ),
      ),
      _ServiceItem(
        title: 'نتائج المسابقات',
        icon: Icons.leaderboard_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => _checkFeatureAndNavigate(
          context,
          null,
          const ResultsHomeScreen(),
        ),
      ),
      _ServiceItem(
        title: 'المراسلة',
        icon: Icons.chat_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const DirectChatScreen()),
      ),
      _ServiceItem(
        title: 'SWEDD',
        icon: Icons.health_and_safety_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const SweddScreen()),
      ),
      _ServiceItem(
        title: 'الاختبارات',
        icon: Icons.quiz_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        isProOnly: true,
        onTap: () => ProFeatureGate.checkAccess(
          context: context,
          featureKey: 'quizzes',
          featureName: 'الاختبارات الذكية',
          onAllowed: () => _checkFeatureAndNavigate(
            context,
            'quizzes_enabled',
            const PublishedExamsScreen(),
          ),
        ),
      ),
      _ServiceItem(
        title: 'قائمة القراءة',
        icon: Icons.menu_book_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const ReadingListScreen()),
      ),
      _ServiceItem(
        title: 'العد التنازلي للمسابقات والعطل',
        icon: Icons.timer_rounded,
        gradient: AppTheme.brandGradient,
        badge: 'جديد',
        onTap: () => _checkFeatureAndNavigate(
          context,
          null,
          const CountdownScreen(),
        ),
      ),
      _ServiceItem(
        title: 'تطور المستوى',
        icon: Icons.trending_up_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () =>
            _checkFeatureAndNavigate(context, null, const ProgressScreen()),
      ),
      _ServiceItem(
        title: 'المختبر الافتراضي (3D)',
        icon: Icons.science_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: '3D تفاعلي',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VirtualLabPage()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: ResponsiveHelper.gridDelegate(
        maxExtent: 220,
        childAspectRatio: 1.15,
        spacing: 12,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return _buildServiceCard(s, isDark);
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Icon(
                    service.icon,
                    color: isDark ? Colors.white : AppTheme.primaryColor,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
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
                  ),
                ],
              ),
            ),
          ),
          if (service.isProOnly)
            Positioned(
              top: 8,
              left: 8,
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.isPro) {
                    return const ProBadge(fontSize: 8.5, showCrown: false);
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 10, color: Color(0xFFF59E0B)),
                        SizedBox(width: 2),
                        Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
  final bool isProOnly;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.badge,
    this.isProOnly = false,
    required this.onTap,
  });
}
