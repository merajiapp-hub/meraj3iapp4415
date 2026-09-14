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

  late AnimationController _contentController;
  late Animation<double> _contentAnim;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      title: 'رفيقك للنجاح الدراسي',
      subtitle: 'كل ما تحتاجه في مكان واحد',
      description:
          'تطبيق تعليمي متكامل يجمع كل ما تحتاجه للدراسة والتفوق في مكان واحد.',
      icon: Icons.school_rounded,
    ),
    _OnboardingSlide(
      title: 'ملاحظات ذكية',
      subtitle: 'نظّم أفكارك بأسلوبك',
      description:
          'محرر نصوص غني، رسم يدوي، ومزامنة سحابية فورية. ملاحظاتك دائماً بين يديك.',
      icon: Icons.edit_note_rounded,
    ),
    _OnboardingSlide(
      title: 'اختبر مستواك',
      subtitle: 'استعد وتفوق على نفسك',
      description:
          'اختبارات وطنية، مسابقات، وتقارير مفصلة لمتابعة مستواك في كل مادة.',
      icon: Icons.emoji_events_rounded,
    ),
    _OnboardingSlide(
      title: 'مكتبتك الرقمية',
      subtitle: 'آلاف الكتب والمراجع',
      description:
          'تصفّح وحمّل الكتب المدرسية والمراجع العلمية مجاناً وبدون إعلانات.',
      icon: Icons.menu_book_rounded,
    ),
    _OnboardingSlide(
      title: 'ابدأ رحلتك الآن',
      subtitle: 'خطوة واحدة نحو التفوق',
      description:
          'سجّل حسابك المجاني وانضم لآلاف الطلاب الذين اختاروا مراجعي طريقاً للنجاح.',
      icon: Icons.rocket_launch_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentAnim = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }

  void _goNext() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
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
        pageBuilder: (_, _, _) => const SignupScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _goToLogin() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── المحتوى ──
            SafeArea(
              child: Column(
                children: [
                  // شريط علوي
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentIndex == 0)
                          Text(
                            'MERAJ3I',
                            style: GoogleFonts.cairo(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 17,
                            ),
                          )
                        else
                          const SizedBox(width: 70),
                        if (_currentIndex < _slides.length - 1)
                          GestureDetector(
                            onTap: _goToLogin,
                            child: Text(
                              'تخطي',
                              style: GoogleFonts.tajawal(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                        _contentController.reset();
                        _contentController.forward();
                      },
                      itemCount: _slides.length,
                      itemBuilder: (_, index) =>
                          _buildSlide(_slides[index], isSmall, size),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(28, 0, 28, isSmall ? 18 : 26),
                    child: _buildBottomNavigation(isSmall),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, bool isSmall, Size size) {
    return FadeTransition(
      opacity: _contentAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_contentAnim),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              SizedBox(height: isSmall ? 16 : 24),

              Expanded(
                flex: isSmall ? 5 : 6,
                child: Center(child: _buildVisual(slide, isSmall)),
              ),

              SizedBox(height: isSmall ? 20 : 32),

              // ── النصوص ──
              Text(
                slide.title,
                style: GoogleFonts.cairo(
                  fontSize: isSmall ? 28 : 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF202124),
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              Text(
                slide.subtitle,
                style: GoogleFonts.tajawal(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmall ? 10 : 14),

              Text(
                slide.description,
                style: GoogleFonts.tajawal(
                  fontSize: isSmall ? 14 : 16,
                  color: const Color(0xFF4D4D4D),
                  height: 1.65,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: isSmall ? 10 : 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisual(_OnboardingSlide slide, bool isSmall) {
    final icon = slide.icon ?? Icons.school_rounded;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth * 0.72).clamp(190.0, 300.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.9,
                height: size * 0.9,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.055),
                  shape: BoxShape.circle,
                ),
              ),
              Positioned(
                top: size * 0.02,
                right: size * 0.08,
                child: Container(
                  width: size * 0.16,
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: size * 0.08,
                left: size * 0.03,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.secondaryColor.withValues(alpha: 0.55),
                  size: size * 0.13,
                ),
              ),
              if (slide == _slides.first)
                Image.asset(
                  'assets/images/logo.png',
                  width: size * 0.55,
                  height: size * 0.55,
                  fit: BoxFit.contain,
                )
              else
                Container(
                  width: size * 0.46,
                  height: size * 0.46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: size * 0.24,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(bool isSmall) {
    final isLast = _currentIndex == _slides.length - 1;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 64),
            Row(
              children: List.generate(_slides.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 28 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
            _buildRoundNavigationButton(
              icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              onPressed: isLast ? _goToSignup : _goNext,
              size: isSmall ? 62 : 70,
            ),
          ],
        ),
        if (isLast) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _goToLogin,
            child: Text(
              'لديّ حساب — تسجيل الدخول',
              style: GoogleFonts.tajawal(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoundNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: Material(
        color: AppTheme.primaryColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: Colors.white, size: size * 0.4),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String subtitle;
  final String description;
  final IconData? icon;

  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    required this.description,
    this.icon,
  });
}
