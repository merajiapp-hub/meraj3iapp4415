import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // بيانات الشرائح
  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'مراجعي',
      subtitle: 'رفيقك للنجاح الدراسي',
      imagePath: 'assets/images/logo.png',
      fallbackIcon: Icons.school_rounded,
      description:
          'تطبيق تعليمي متكامل يجمع كل ما تحتاجه للدراسة والتفوق في مكان واحد.',
    ),
    _OnboardingSlide(
      title: 'ملاحظاتك الذكية',
      subtitle: 'نظّم أفكارك بشكل مثالي',
      imagePath: '',
      fallbackIcon: Icons.note_alt_rounded,
      description:
          'دفتر ملاحظات ذكي مع محرر نصوص غني، رسم يدوي، ومزامنة سحابية فورية.',
    ),
    _OnboardingSlide(
      title: 'استعد للامتحانات',
      subtitle: 'اختبر نفسك وتفوق',
      imagePath: '',
      fallbackIcon: Icons.quiz_rounded,
      description:
          'مسابقات، اختبارات وطنية، وإحصائيات مفصّلة لمتابعة تقدمك الدراسي.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  void _goNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToSignup() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignupScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _goToLogin() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF9),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Image.asset('assets/images/logo.png'),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'MERAJ3I',
                            style: GoogleFonts.cairo(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      if (_currentIndex < _slides.length - 1)
                        TextButton(
                          onPressed: _goToLogin,
                          child: Text(
                            'تخطي',
                            style: GoogleFonts.tajawal(color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── PageView للشرائح ──
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(_slides[index], isSmall);
                    },
                  ),
                ),

                // ── Dots Indicator ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),

                // ── الأزرار ──
                Padding(
                  padding: EdgeInsets.fromLTRB(32, 0, 32, isSmall ? 16 : 28),
                  child: Column(
                    children: [
                      if (_currentIndex < _slides.length - 1)
                        SizedBox(
                          width: double.infinity,
                          height: isSmall ? 50 : 56,
                          child: ElevatedButton.icon(
                            onPressed: _goNext,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              'التالي',
                              style: GoogleFonts.tajawal(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 8,
                              shadowColor: AppTheme.primaryColor.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          height: isSmall ? 50 : 56,
                          child: ElevatedButton.icon(
                            onPressed: _goToSignup,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(
                              'إنشاء حساب',
                              style: GoogleFonts.tajawal(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: isSmall ? 46 : 50,
                          child: OutlinedButton.icon(
                            onPressed: _goToLogin,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              'تسجيل الدخول',
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, bool isSmall) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: isSmall ? 12 : 24),

          // ── الاسم الكبير ──
          Text(
            slide.title,
            style: GoogleFonts.cairo(
              fontSize: isSmall ? 36 : 44,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // ── العنوان الفرعي ──
          Text(
            slide.subtitle,
            style: GoogleFonts.tajawal(
              fontSize: isSmall ? 17 : 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isSmall ? 20 : 32),

          // ── الصورة التوضيحية ──
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: -30,
                        right: -20,
                        child: _shape(
                          150,
                          Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Positioned(
                        bottom: -45,
                        left: -25,
                        child: _shape(
                          180,
                          Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: slide.imagePath.isNotEmpty
                            ? Image.asset(
                                slide.imagePath,
                                fit: BoxFit.contain,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                              )
                            : Icon(
                                slide.fallbackIcon,
                                size: isSmall ? 110 : 150,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: isSmall ? 12 : 20),

          // ── الوصف ──
          Text(
            slide.description,
            style: GoogleFonts.tajawal(
              fontSize: isSmall ? 13 : 15,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: isSmall ? 12 : 20),
        ],
      ),
    );
  }

  Widget _shape(double size, Color color) {
    return Transform.rotate(
      angle: -0.35,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData fallbackIcon;
  final String description;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.fallbackIcon,
    required this.description,
  });
}
