import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/task_provider.dart';
import '../providers/reading_provider.dart';
import '../widgets/app_notification.dart';

import '../theme/app_theme.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'task_manager_screen.dart';
import 'settings_screen.dart';
import 'added_books_screen.dart';
import 'add_book_screen.dart';
import 'profile_screen.dart';
import 'reviews_screen.dart';

import 'student_competition_screen.dart';
import 'notes_screen.dart';

import 'info_screen.dart';
import 'login_screen.dart';
import 'stages_screen.dart';
import 'results/results_home_screen.dart';
import 'swedd_screen.dart';
import 'ai_search_screen.dart';
import 'exam_generator_screen.dart';
import 'downloads_screen.dart';
import 'contact_screen.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';
import 'national_exams_screen.dart';
import 'notifications_screen.dart';
import 'statistics_screen.dart';
import 'donations_screen.dart';
import 'dedication_screen.dart';
import 'student/progress_screen.dart';
import 'student/reading_list_screen.dart';
import 'student/reading_history_screen.dart';
import '../widgets/banner_ad_widget.dart';
import 'admin/admin_guard.dart';
import 'admin/admin_dashboard_screen.dart';
import '../features/smart_calculator/ui/screens/smart_calculator_screen.dart';
import 'direct_chat_screen.dart';


class HomePage extends StatefulWidget {
  final bool isGuest;
  const HomePage({super.key, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // نظام Toast الخروج
  bool _exitToastShown = false;


  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  final PageController _pageController = PageController(viewportFraction: 0.88, initialPage: 3000);
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TaskManagerScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
        break;
    }
  }

  /// إظهار Toast أنيق عند الضغط على زر الرجوع (مرتان للخروج)
  void _handleBackButton() {
    if (_exitToastShown) {
      SystemNavigator.pop();
      return;
    }
    _exitToastShown = true;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 80,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              // تدرج لوني بدل اللون الثابت لمظهر أكثر احترافية
              gradient: const LinearGradient(
                colors: [Color(0xFF1B2A2A), Color(0xFF0D3030)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار داخل دائرة بيضاء لتميّزه عن الخلفية الداكنة
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'اضغط مرة أخرى للخروج من التطبيق',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
      if (mounted) _exitToastShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackButton();
      },
      child: Scaffold(
        drawer: _buildDrawer(),
        floatingActionButton: _buildFloatingActionButton(),
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                // تم إيقاف إخفاء الشريط السفلي بناءً على طلب المستخدم
                return false;
              },
              child: CustomScrollView(
          slivers: [
            // ══════════════════════════════════════════
            //  Header — SliverAppBar محسّن
            // ══════════════════════════════════════════
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: 20,
                  right: 48,
                  bottom: 16,
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MERAJ3I',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                  ),
                  child: Stack(
                    children: [
                      // دوائر زخرفية
                      Positioned(
                        right: -40,
                        top: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -60,
                        bottom: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 100,
                        top: 20,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // نص ترحيبي في الـ Header الكامل
                      Positioned(
                        bottom: 52,
                        right: 20,
                        left: 60,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            final name = widget.isGuest
                                ? 'الزائر'
                                : (auth.user?.displayName ?? 'الطالب');
                            return Text(
                              'أهلاً، $name 👋',
                              style: GoogleFonts.tajawal(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // زر الإشعارات
                Consumer<NotificationsProvider>(
                  builder: (context, notifProvider, _) => Stack(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),
                      if (notifProvider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                notifProvider.unreadCount > 9
                                    ? '9+'
                                    : '${notifProvider.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        backgroundImage: Provider.of<AuthProvider>(
                          context,
                        ).profileImageProvider,
                        child:
                            Provider.of<AuthProvider>(
                                  context,
                                ).profileImageProvider ==
                                null
                            ? const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ),
              ],
            ),

            // ══════════════════════════════════════════
            //  Body Content
            // ══════════════════════════════════════════
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── شريط البحث ──
                        _buildSearchBar(isDark),
                        const SizedBox(height: 20),

                        // ── كرت الصفحة الرئيسية (Carousel) ──
                        _buildTopCarousel(isDark),
                        const SizedBox(height: 24),

                        // ── عنوان القسم الرئيسي ──
                        _buildSectionHeader('الخدمات الرئيسية', isDark),
                        const SizedBox(height: 14),

                        // ── Grid الأزرار الرئيسية الست ──
                        _buildMainServicesGrid(size, isDark),

                        const SizedBox(height: 28),
                        const BannerAdWidget(),
                        const SizedBox(height: 28),

                        // ── Footer ──
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Développé par Mohamed Mahmoud Abderrahmane',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '© 2026 MERAJ3I. جميع الحقوق محفوظة.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 120), // مساحة للشريط السفلي العائم لكي لا يغطي المحتوى
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // شريط التنقل السفلي الثابت
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _buildBottomNav(isDark),
      ),
    ],
  ),
  ),
);
}



  // ══════════════════════════════════════════════════════
  //  زر إضافة كتاب (FAB)
  // ══════════════════════════════════════════════════════
  Widget _buildFloatingActionButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 90), // مرفوع قليلاً لكي لا يصطدم بالشريط السفلي
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBookScreen()),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Grid الأزرار الرئيسية الست
  // ══════════════════════════════════════════════════════
  Widget _buildMainServicesGrid(Size size, bool isDark) {
    final services = [
      _ServiceItem(
        title: 'المراحل الدراسية',
        icon: Icons.school_rounded,
        gradient: AppTheme.blueGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StagesScreen()),
        ),
      ),
      _ServiceItem(
        title: 'التنافس بين الطلاب',
        icon: Icons.emoji_events_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB75E), Color(0xFFED8F03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: 'جديد',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentCompetitionScreen()),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResultsHomeScreen()),
        ),
      ),
      _ServiceItem(
        title: 'الامتحانات الوطنية',
        icon: Icons.menu_book_rounded,
        gradient: AppTheme.goldGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NationalExamsScreen()),
        ),
      ),
      _ServiceItem(
        title: 'MERAJ3I AI',
        icon: Icons.auto_awesome_rounded,
        gradient: AppTheme.purpleGradient,
        badge: 'AI',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiSearchScreen()),
        ),
      ),
      _ServiceItem(
        title: 'الحاسبة العلمية',
        icon: Icons.calculate_rounded,
        imagePath: 'assets/Calculator/Calculator.png',
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: 'جديد',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SmartCalculatorScreen()),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DirectChatScreen()),
        ),
      ),
      _ServiceItem(
        title: 'التنزيلات',
        icon: Icons.download_for_offline_rounded,
        gradient: AppTheme.greenGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DownloadsScreen()),
        ),
      ),
      _ServiceItem(
        title: 'ملاحظاتي',
        icon: Icons.notes_rounded,
        gradient: AppTheme.purpleGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotesScreen()),
        ),
      ),
      _ServiceItem(
        title: 'SWEDD',
        icon: Icons.health_and_safety_rounded,
        gradient: AppTheme.pinkGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SweddScreen()),
        ),
      ),
      // منقولة من الشريط الجانبي
      _ServiceItem(
        title: 'الاختبارات',
        icon: Icons.quiz_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamGeneratorScreen()),
        ),
      ),
      _ServiceItem(
        title: 'الإحصائيات',
        icon: Icons.bar_chart_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReadingListScreen()),
        ),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgressScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return _buildServiceCard(s, isDark, 0);
      },
    );
  }

  Widget _buildServiceCard(
    _ServiceItem service,
    bool isDark,
    double cardWidth,
  ) {
    return _AnimatedCard(
      onTap: service.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(32),
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
            // خط لوني علوي رفيع
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: service.gradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
              ),
            ),

            // المحتوى الرئيسي
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // الأيقونة
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: service.gradient,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: (service.gradient as LinearGradient)
                              .colors
                              .first
                              .withValues(alpha: 0.30),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: service.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset(
                              service.imagePath!,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Icon(service.icon, color: Colors.white, size: 18),
                  ),

                  // النص
                  Text(
                    service.title,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: isDark ? Colors.white : const Color(0xFF0A1A15),
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // شارة (Badge) اختيارية
            if (service.badge != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
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
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  شريط البحث
  // ══════════════════════════════════════════════════════
  Widget _buildSearchBar(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFD1EAE3),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppTheme.primaryColor.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ابحث عن الكتب والمذكرات...',
                style: GoogleFonts.tajawal(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'بحث',
                style: GoogleFonts.tajawal(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  كرت الصفحة الرئيسية (Carousel)
  // ══════════════════════════════════════════════════════
  Widget _buildTopCarousel(bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _carouselIndex = index % 3;
              });
            },
            itemBuilder: (context, index) {
              final itemIndex = index % 3;
              return _buildCarouselCard(itemIndex, isDark);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final isActive = index == _carouselIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF97316) : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(int index, bool isDark) {
    // الألوان المستوحاة من الوصف
    final List<Color> bgColors = [
      const Color(0xFF1E3A8A), // أزرق غامق للكرت الرئيسي
      const Color(0xFFF97316), // برتقالي
      const Color(0xFF10B981), // أخضر
    ];

    if (index == 0) {
      // الكرت الرئيسي المطلوب
      return _AnimatedCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SmartCalculatorScreen()),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColors[0],
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: bgColors[0].withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // نصوص الترحيب على اليمين (حسب اتجاه العربية)
              Positioned(
                right: 0,
                top: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final name = widget.isGuest
                            ? 'الزائر'
                            : (auth.user?.displayName?.split(' ').first ?? 'الطالب');
                        return Text(
                          'مرحبا، $name!',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'استعد للدراسة',
                      style: GoogleFonts.tajawal(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // الصورة على اليسار
              Positioned(
                left: 0,
                top: 0,
                bottom: 30,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(10),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/IM/IM1.jpg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'home_card_image',
                    child: Image.asset(
                      'assets/IM/IM1.jpg', // الصورة المطلوبة
                      width: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // في حال عدم وجود الصورة بعد، عرض عنصر نائب
                        return Container(
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school_rounded, color: Colors.white54, size: 40),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // شريط التقدم في الأسفل
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Text(
                      '1/10',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.1,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // الكروت الجانبية (برتقالي وأخضر)
      return _AnimatedCard(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColors[index],
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: bgColors[index].withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              index == 1 ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
              size: 60,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
  }


  // ══════════════════════════════════════════════════════
  //  عنوان القسم
  // ══════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0A1A15),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  //  شريط التنقل السفلي — هندسي وعصري
  // ══════════════════════════════════════════════════════
  Widget _buildBottomNav(bool isDark) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
      _NavItem(icon: Icons.favorite_rounded, label: 'المفضلة'),
      _NavItem(icon: Icons.task_alt_rounded, label: 'الخطة'),
      _NavItem(icon: Icons.person_rounded, label: 'حسابي'),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => _onItemTapped(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: isSelected ? 20 : 16,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.brandGradient : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[index].icon,
                      size: 24,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : Colors.grey[500]),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        items[index].label,
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  Drawer
  // ══════════════════════════════════════════════════════
  Widget _buildDrawer() {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final userName = user?.displayName ?? 'حساب الطالب';
    final userEmail = user?.email ?? '';

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 40,
              left: 20,
              right: 20,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.deepBlueGradient,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    backgroundImage: auth.profileImageProvider,
                    child: auth.profileImageProvider == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isGuest ? 'مستخدم زائر' : userName,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.isGuest
                      ? 'سجل دخولك للحصول على مميزات أكثر'
                      : userEmail,
                  style: GoogleFonts.tajawal(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 10),
              children: [
                _buildDrawerItem(Icons.library_books_rounded, 'الكتب المضافة', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddedBooksScreen()),
                  );
                }),
                _buildDrawerItem(Icons.history_edu_rounded, 'سجل القراءة', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(Icons.reviews_rounded, 'آراء المستخدمين', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReviewsScreen()),
                  );
                }),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(Icons.notifications_rounded, 'الإشعارات', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                }),

                _buildDrawerItem(Icons.settings_rounded, 'الإعدادات', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(Icons.info_rounded, 'عن التطبيق', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InfoScreen()),
                  );
                }),
                _buildDrawerItem(Icons.help_rounded, 'الأسئلة الشائعة', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaqScreen()),
                  );
                }),
                _buildDrawerItem(
                  Icons.privacy_tip_rounded,
                  'سياسة الخصوصية',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.volunteer_activism_rounded,
                  'دعم التطبيق',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DonationsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(Icons.auto_awesome_rounded, 'الإهداء', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DedicationScreen()),
                  );
                }),
                _buildDrawerItem(Icons.contact_support_rounded, 'اتصل بنا', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                  );
                }),
                _buildDrawerItem(Icons.gavel_rounded, 'شروط الاستخدام', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                  );
                }),
                if (auth.isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildDrawerItem(Icons.admin_panel_settings_rounded, 'لوحة الإدارة', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminGuard(child: AdminDashboardScreen())),
                    );
                  }),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  Image.asset('assets/images/logo.png', width: 22, height: 22, color: Colors.red),
                  'تسجيل الخروج',
                  () {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Column(
                          children: [
                            Image.asset('assets/images/logo.png', height: 60),
                            const SizedBox(height: 12),
                            Text(
                              'تسجيل الخروج',
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'هل أنت متأكد من أنك تريد تسجيل الخروج من حسابك؟',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.tajawal(
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'إلغاء',
                              style: GoogleFonts.tajawal(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await authProvider.signOut();
                              try {
                                await authProvider.signOutGoogle();
                              } catch (_) {}
                              if (context.mounted) {
                                Provider.of<FavoritesProvider>(context, listen: false).clearAll();
                                Provider.of<DownloadsProvider>(context, listen: false).clearAll();
                                Provider.of<TaskProvider>(context, listen: false).clearAll();
                                Provider.of<ReadingProvider>(context, listen: false).clearAll();
                                AppNotification.showLogout(context);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'تسجيل الخروج',
                              style: GoogleFonts.tajawal(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }, color: Colors.redAccent),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ══════════════════════════════════════════════════════
  //  عنصر Drawer
  // ══════════════════════════════════════════════════════
  Widget _buildDrawerItem(
    dynamic iconOrWidget, // IconData or Widget
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final leadingWidget = iconOrWidget is IconData
        ? Icon(iconOrWidget, color: color ?? AppTheme.primaryColor, size: 20)
        : (iconOrWidget as Widget);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: leadingWidget,
      ),
      title: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ══════════════════════════════════════════════════════
//  Model للخدمات
// ══════════════════════════════════════════════════════
class _ServiceItem {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final String? badge;
  final String? imagePath;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.badge,
    this.imagePath,
    required this.onTap,
  });
}

// ══════════════════════════════════════════════════════
//  Model لعناصر الشريط السفلي
// ══════════════════════════════════════════════════════
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ══════════════════════════════════════════════════════
//  AnimatedCard — تأثير الضغط
// ══════════════════════════════════════════════════════
class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedCard({required this.child, required this.onTap});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
