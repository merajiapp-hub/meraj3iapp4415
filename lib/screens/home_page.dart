import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/task_provider.dart';
import '../providers/reading_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_notification.dart';

import '../theme/app_theme.dart';
import 'search_screen.dart';

import 'settings_screen.dart';

import 'profile_screen.dart';
import 'reviews_screen.dart';

import 'info_screen.dart';
import 'login_screen.dart';
import 'stages_screen.dart';
import 'references_screen.dart';
import 'contact_screen.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';
import 'national_exams_screen.dart';
import 'notifications_screen.dart';
import 'donations_screen.dart';
import 'dedication_screen.dart';
import 'student/reading_history_screen.dart';
import '../widgets/banner_ad_widget.dart';
import '../features/smart_calculator/ui/screens/smart_calculator_screen.dart';
import 'services_screen.dart';

class HomePage extends StatefulWidget {
  final bool isGuest;
  const HomePage({super.key, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // نظام Toast الخروج
  bool _exitToastShown = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final PageController _pageController = PageController(
    viewportFraction: 0.88,
    initialPage: 3000,
  );
  int _carouselIndex = 0;
  Timer? _carouselTimer;

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

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
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
                ),
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
        body: Column(
          children: [
            _buildHomeToolbar(isDark),
            // ══════════════════════════════════════════
            //  Header Fixed Section (AppBar + Carousel)
            // ══════════════════════════════════════════
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 16),
              child: Stack(
                children: [
                  // دوائر زخرفية
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40,
                    bottom: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  _buildTopCarousel(isDark),
                ],
              ),
            ),

            // ══════════════════════════════════════════
            //  Body Content (Scrollable)
            // ══════════════════════════════════════════
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── عنوان القسم الرئيسي ──
                        _buildSectionHeader('الخدمات الرئيسية', isDark),
                        const SizedBox(height: 14),

                        // ── Grid الأزرار الرئيسية ──
                        _buildMainServicesGrid(size, isDark),

                        const SizedBox(height: 28),
                        const BannerAdWidget(),
                      ],
                    ),
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
  //  Grid الأزرار الرئيسية الست
  // ══════════════════════════════════════════════════════
  Widget _buildMainServicesGrid(Size size, bool isDark) {
    final services = [
      _ServiceItem(
        title: 'المراحل الدراسية',
        icon: Icons.school_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StagesScreen()),
        ),
      ),
      _ServiceItem(
        title: 'الامتحانات الوطنية',
        icon: Icons.menu_book_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NationalExamsScreen()),
        ),
      ),
      _ServiceItem(
        title: 'الحاسبة العلمية',
        icon: Icons.calculate_rounded,
        imagePath: 'assets/Calculator/Calculator.png',
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SmartCalculatorScreen()),
        ),
      ),
      _ServiceItem(
        title: 'المزيد من الخدمات',
        icon: Icons.grid_view_rounded,
        gradient: AppTheme.primaryGradient,
        badge: null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServicesScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
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
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildServiceIcon(service, isDark, size: 40),
                    const SizedBox(height: 12),
                    // النص
                    Text(
                      service.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF0A1A15),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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

  Widget _buildServiceIcon(
    _ServiceItem service,
    bool isDark, {
    required double size,
  }) {
    if (service.imagePath != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(service.imagePath!, fit: BoxFit.contain),
      );
    }

    return Icon(
      service.icon,
      size: size,
      color: isDark ? Colors.white : AppTheme.primaryColor,
    );
  }

  // ══════════════════════════════════════════════════════
  //  شريط البحث
  // ══════════════════════════════════════════════════════
  Widget _buildHomeToolbar(bool isDark) {
    return Material(
      color: isDark ? AppTheme.surfaceDark : Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Builder(
                builder: (ctx) => _homeToolbarButton(
                  icon: Icons.menu_rounded,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                  tooltip: 'القائمة الجانبية',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildSearchBar(isDark)),
              const SizedBox(width: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => _homeToolbarButton(
                  icon: themeProvider.isDarkMode
                      ? Icons.wb_sunny_rounded
                      : Icons.nights_stay_rounded,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                  tooltip: 'تبديل الوضع',
                  onPressed: () =>
                      themeProvider.toggleTheme(!themeProvider.isDarkMode),
                ),
              ),
              Consumer<NotificationsProvider>(
                builder: (context, notifProvider, _) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _homeToolbarButton(
                      icon: Icons.notifications_rounded,
                      color: isDark ? Colors.white : AppTheme.primaryColor,
                      tooltip: 'الإشعارات',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    if (notifProvider.unreadCount > 0)
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeToolbarButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 24),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ابحث عن الكتب والمذكرات...',
                style: GoogleFonts.tajawal(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'بحث',
                style: GoogleFonts.tajawal(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
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
  //  كرت المستخدم
  // ══════════════════════════════════════════════════════
  Widget _buildUserCard(bool isDark) {
    final auth = context.read<AuthProvider>();
    final name = widget.isGuest ? 'زائر' : (auth.user?.displayName ?? 'مستخدم');
    return GestureDetector(
      onTap: widget.isGuest
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              backgroundImage: auth.profileImageProvider,
              child: auth.profileImageProvider == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'مرحباً بك،',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      name,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isGuest)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white70 : AppTheme.primaryColor,
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
    final List<Widget> carouselItems = [
      _buildUserCard(isDark),
      _buildCarouselImageCard('assets/IM/IM1.jpg'),
      _buildCarouselImageCard('assets/IM/IM2.jpg'),
      _buildCarouselImageCard('assets/IM/IM3.jpg'),
    ];

    return Column(
      children: [
        SizedBox(
          height: 155,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _carouselIndex = index % carouselItems.length;
              });
            },
            itemBuilder: (context, index) {
              final itemIndex = index % carouselItems.length;
              return carouselItems[itemIndex];
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(carouselItems.length, (index) {
            final isActive = index == _carouselIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }


  Widget _buildCarouselImageCard(String imagePath) {
    return _AnimatedCard(
      onTap: () {
        // فتح الصورة بشكل كامل وواضح
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
                  child: Image.asset(imagePath, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover, // تغطية مساحة الكرت بشكل جذاب
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.isGuest ? 'مستخدم زائر' : userName,
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                _buildDrawerItem(Icons.library_books_rounded, 'مراجع أخرى', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReferencesScreen()),
                  );
                }),
                _buildDrawerItem(Icons.history_edu_rounded, 'سجل القراءة', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReadingHistoryScreen(),
                    ),
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerItem(
                  Image.asset(
                    'assets/images/logo.png',
                    width: 22,
                    height: 22,
                    color: Colors.red,
                  ),
                  'تسجيل الخروج',
                  () {
                    final isDark =
                        Theme.of(context).brightness == Brightness.dark;
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: isDark
                              ? AppTheme.surfaceDark
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                await authProvider.signOut();

                                if (context.mounted) {
                                  Provider.of<FavoritesProvider>(
                                    context,
                                    listen: false,
                                  ).clearAll();
                                  Provider.of<DownloadsProvider>(
                                    context,
                                    listen: false,
                                  ).clearAll();
                                  Provider.of<TaskProvider>(
                                    context,
                                    listen: false,
                                  ).clearAll();
                                  Provider.of<ReadingProvider>(
                                    context,
                                    listen: false,
                                  ).clearAll();
                                  AppNotification.showLogout(context);
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
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
                  },
                  color: Colors.redAccent,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : (color ?? AppTheme.primaryColor);
    final leadingWidget = iconOrWidget is IconData
        ? Icon(iconOrWidget, color: iconColor, size: 22)
        : (iconOrWidget as Widget);

    return ListTile(
      leading: leadingWidget,
      title: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : color,
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
