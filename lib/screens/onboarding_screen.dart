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
      title: '',
      subtitle: 'رفيقك للنجاح الدراسي',
      description: 'تطبيق تعليمي متكامل يجمع كل ما تحتاجه للدراسة والتفوق في مكان واحد.',
    ),
    _OnboardingSlide(
      title: 'ملاحظات ذكية',
      subtitle: 'نظّم أفكارك بأسلوبك',
      description: 'محرر نصوص غني، رسم يدوي، ومزامنة سحابية فورية. ملاحظاتك دائماً بين يديك.',
      icon: Icons.edit_note_rounded,
    ),
    _OnboardingSlide(
      title: 'الامتحانات',
      subtitle: 'استعد وتفوق على نفسك',
      description: 'اختبارات وطنية، مسابقات، وتقارير مفصلة لمتابعة مستواك في كل مادة.',
      icon: Icons.emoji_events_rounded,
    ),
    _OnboardingSlide(
      title: 'المكتبة الرقمية',
      subtitle: 'آلاف الكتب والمراجع',
      description: 'تصفّح وحمّل الكتب المدرسية والمراجع العلمية مجاناً وبدون إعلانات.',
      icon: Icons.menu_book_rounded,
    ),
    _OnboardingSlide(
      title: 'انضم الآن',
      subtitle: 'ابدأ رحلة التفوق اليوم',
      description: 'سجّل حسابك المجاني وانضم لآلاف الطلاب الذين اختاروا مراجعي طريقاً للنجاح.',
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

                  // مؤشرات الصفحات
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final isActive = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 30 : 7,
                          height: 7,
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

                  // الأزرار
                  Padding(
                    padding: EdgeInsets.fromLTRB(28, 0, 28, isSmall ? 18 : 30),
                    child: _currentIndex < _slides.length - 1
                        ? _buildNextButton(isSmall)
                        : _buildFinalButtons(isSmall),
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
                child: Center(
                  child: slide.icon == null
                      ? Image.asset('assets/images/logo.png', fit: BoxFit.contain)
                      : const SizedBox.shrink(),
                ),
              ),

              SizedBox(height: isSmall ? 20 : 32),

              // ── النصوص ──
              if (slide.title.isNotEmpty)
                Text(
                  slide.title,
                  style: GoogleFonts.cairo(
                    fontSize: isSmall ? 34 : 42,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 6),

              Text(
                slide.subtitle,
                style: GoogleFonts.tajawal(
                  fontSize: isSmall ? 16 : 19,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmall ? 10 : 14),

              Text(
                slide.description,
                style: GoogleFonts.tajawal(
                  fontSize: isSmall ? 13 : 15,
                  color: Colors.grey.shade500,
                  height: 1.7,
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

  Widget _buildNextButton(bool isSmall) {
    return SizedBox(
      width: double.infinity,
      height: isSmall ? 52 : 58,
      child: ElevatedButton(
        onPressed: _goNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'التالي',
          style: GoogleFonts.tajawal(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFinalButtons(bool isSmall) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: isSmall ? 52 : 58,
          child: ElevatedButton(
            onPressed: _goToSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'إنشاء حساب مجاني',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _goToLogin,
          child: Text(
            'لديّ حساب — تسجيل الدخول',
            style: GoogleFonts.tajawal(
              color: AppTheme.primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
