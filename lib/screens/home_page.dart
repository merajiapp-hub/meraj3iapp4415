import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';

import '../providers/reading_provider.dart';
import '../data/books_data.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'task_manager_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'info_screen.dart';
import 'login_screen.dart';
import 'stages_screen.dart';
import 'swedd_screen.dart';
import 'ai_search_screen.dart';
import 'quiz_screen.dart';
import 'downloads_screen.dart';
import 'contact_screen.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';
import 'national_exams_screen.dart';
import 'notifications_screen.dart';
import 'statistics_screen.dart';
import '../widgets/banner_ad_widget.dart';
import 'results/results_home_screen.dart';

class HomePage extends StatefulWidget {
  final bool isGuest;
  const HomePage({super.key, this.isGuest = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<String> _wisdomQuotes = [
    "من جد وجد، ومن زرع حصد.",
    "العلم يبني بيوتاً لا عماد لها.",
    "الوقت كالسيف إن لم تقطعه قطعك.",
    "لا تؤجل عمل اليوم إلى الغد.",
    "رحلة الألف ميل تبدأ بخطوة.",
    "النجاح هو نتيجة الإصرار والعمل الدؤوب.",
    "اقرأ لتعلم، وتعلم لتعمل، واعمل لتنجح.",
  ];

  late String _currentWisdom;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _currentWisdom = _wisdomQuotes[Random().nextInt(_wisdomQuotes.length)];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldPop = await _showExitDialog(context) ?? false;
        if (shouldPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: _buildDrawer(),
        bottomNavigationBar: _buildBottomNav(isDark),
        body: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(
                  left: 20,
                  right: 48,
                  bottom: 16,
                ),
                title: Text(
                  'MERAJ3I',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.deepBlueGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 80,
                        bottom: -20,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // زر الإشعارات مع مؤشر عدد غير المقروءة
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
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
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

            // Body Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar
                        _buildSearchBar(isDark),
                        const SizedBox(height: 24),

                        // Wisdom Box
                        _buildWisdomBox(),
                        const SizedBox(height: 28),

                        // الخدمات الرئيسية - أفقية
                        Text(
                          'الخدمات الرئيسية',
                          style: GoogleFonts.tajawal(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildHorizontalServiceCard(
                                title: 'المراحل',
                                icon: Icons.school_rounded,
                                gradient: AppTheme.primaryGradient,
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StagesScreen(),
                                  ),
                                ),
                              ),
                              _buildHorizontalServiceCard(
                                title: 'النتائج',
                                icon: Icons.emoji_events_rounded,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B35), Color(0xFFE53935)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ResultsHomeScreen(),
                                  ),
                                ),
                              ),
                              _buildHorizontalServiceCard(
                                title: 'الوطنية',
                                icon: Icons.menu_book_rounded,
                                gradient: AppTheme.goldGradient,
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NationalExamsScreen(),
                                  ),
                                ),
                              ),
                              _buildHorizontalServiceCard(
                                title: 'الذكاء',
                                icon: Icons.auto_awesome_rounded,
                                gradient: AppTheme.purpleGradient,
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AiSearchScreen(),
                                  ),
                                ),
                              ),
                              _buildHorizontalServiceCard(
                                title: 'التنزيلات',
                                icon: Icons.download_for_offline_rounded,
                                gradient: AppTheme.greenGradient,
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DownloadsScreen(),
                                  ),
                                ),
                              ),
                              _buildHorizontalServiceCard(
                                title: 'SWEDD',
                                icon: Icons.health_and_safety_rounded,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899),
                                    Color(0xFFBE185D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isDark: isDark,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SweddScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // أكمل القراءة
                        Consumer<ReadingProvider>(
                          builder: (context, reading, _) {
                            if (reading.readCount == 0) {
                              return const SizedBox.shrink();
                            }

                            final readBooks = BooksData.allBooks
                                .where((b) => reading.isRead(b.uniqueKey))
                                .take(6)
                                .toList();

                            if (readBooks.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            return Column(
                              children: [
                                _buildSectionTitle(
                                  'أكمل القراءة',
                                  Icons.auto_stories_rounded,
                                  AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 16),
                                _buildBooksHorizontalList(readBooks, isDark),
                                const SizedBox(height: 32),
                              ],
                            );
                          },
                        ),

                        // المضاف حديثاً
                        _buildSectionTitle(
                          'المضاف حديثاً',
                          Icons.new_releases_rounded,
                          AppTheme.secondaryColor,
                        ),
                        const SizedBox(height: 16),
                        _buildBooksHorizontalList(
                          BooksData.allBooks.take(6).toList(),
                          isDark,
                        ),

                        const SizedBox(height: 32),

                        // الأكثر قراءة
                        _buildSectionTitle(
                          'الأكثر قراءة',
                          Icons.local_fire_department_rounded,
                          Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        _buildBooksHorizontalList(
                          BooksData.allBooks.skip(10).take(6).toList(),
                          isDark,
                        ),

                        const SizedBox(height: 32),
                        const BannerAdWidget(),
                        const SizedBox(height: 32),
                        // Footer
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
                                '© 2025 MERAJ3I. جميع الحقوق محفوظة.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'المفضلة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'الخطة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'حسابي',
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'ابحث عن الكتب والمذكرات...',
                style: GoogleFonts.tajawal(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWisdomBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFFCD34D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حكمة اليوم',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _currentWisdom,
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalServiceCard({
    required String title,
    required IconData icon,
    required Gradient gradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return _AnimatedCard(
      onTap: onTap,
      child: Container(
        width: 105,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withValues(
                alpha: 0.15,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          child: Row(
            children: [
              Text(
                'عرض الكل',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBooksHorizontalList(List<Book> books, bool isDark) {
    if (books.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _AnimatedCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    pdfUrl: book.url,
                    title: book.title,
                    book: book,
                  ),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: AppTheme.primaryColor,
                            size: 40,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                book.category,
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // الشريط اللوني العلوي الرفيع
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
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
                      color: Colors.white.withValues(alpha: 0.2),
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

                _buildDrawerItem(Icons.quiz_rounded, 'الاختبارات', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                }),
                _buildDrawerItem(Icons.bar_chart_rounded, 'الإحصائيات', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                  );
                }),
                _buildDrawerItem(Icons.notifications_rounded, 'الإشعارات', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                }),
                _buildDrawerItem(
                  Icons.calendar_today_rounded,
                  'خطة الدراسة',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TaskManagerScreen(),
                      ),
                    );
                  },
                ),
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
                _buildDrawerItem(Icons.logout_rounded, 'تسجيل الخروج', () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
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

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'هل تريد الخروج؟',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.exit_to_app_rounded,
              size: 50,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '﷽\nاللهم صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى سَيِّدِنَا مُحَمَّدٍ',
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'خروج',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color ?? AppTheme.primaryColor, size: 20),
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

// Simple custom widget for scaling effect on tap
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
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
