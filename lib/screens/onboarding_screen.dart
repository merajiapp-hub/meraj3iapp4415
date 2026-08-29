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
      description: 'تطبيق تعليمي متكامل يجمع كل ما تحتاجه للدراسة والتفوق في مكان واحد.',
    ),
    _OnboardingSlide(
      title: 'ملاحظاتك الذكية',
      subtitle: 'نظّم أفكارك بشكل مثالي',
      imagePath: '',
      fallbackIcon: Icons.note_alt_rounded,
      description: 'دفتر ملاحظات ذكي مع محرر نصوص غني، رسم يدوي، ومزامنة سحابية فورية.',
    ),
    _OnboardingSlide(
      title: 'استعد للامتحانات',
      subtitle: 'اختبر نفسك وتفوق',
      imagePath: '',
      fallbackIcon: Icons.quiz_rounded,
      description: 'مسابقات، اختبارات وطنية، وإحصائيات مفصّلة لمتابعة تقدمك الدراسي.',
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

  void _goToSignup() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignupScreen(),
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
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
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
                    // زر ابدأ الآن
                    SizedBox(
                      width: double.infinity,
                      height: isSmall ? 48 : 54,
                      child: ElevatedButton(
                        onPressed: _goToSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'ابدأ الآن',
                          style: GoogleFonts.tajawal(
                            fontSize: isSmall ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 10 : 14),

                    // زر تسجيل الدخول
                    SizedBox(
                      width: double.infinity,
                      height: isSmall ? 48 : 54,
                      child: OutlinedButton(
                        onPressed: _goToLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(
                            color: AppTheme.primaryColor.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.tajawal(
                            fontSize: isSmall ? 16 : 18,
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
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    slide.imagePath,
                    fit: BoxFit.contain,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                              AppTheme.primaryColor.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            slide.fallbackIcon,
                            size: isSmall ? 100 : 130,
                            color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                      );
                    },
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
