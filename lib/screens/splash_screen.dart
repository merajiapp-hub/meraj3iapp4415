import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/app_config_provider.dart';
import 'main_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _pulse;

  bool _showBiometricRetry = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward();

    // إبقاء شاشة التحميل ظاهرة مدة كافية لظهور الهوية البصرية بوضوح.
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) _proceed();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_navigating || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Timeout شامل — لن يتعلق التطبيق أبداً أكثر من 8 ثوانٍ
    try {
      await authProvider
          .getInitialAuthState()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('[Splash] Auth timeout — proceeding anyway');
        return null;
      });
    } catch (e) {
      debugPrint('[Splash] Auth error: $e');
    }

    if (!mounted) return;

    // تحقق من وضع الضيف أولاً
    if (authProvider.isGuest) {
      final appConfig = context.read<AppConfigProvider>();
      if (!appConfig.allowGuestView) {
        await authProvider.setGuestMode(false);
        _navigateTo(const LoginScreen());
        return;
      }
      _navigateTo(const MainScreen(isGuest: true));
      return;
    }

    // تحقق من تسجيل الدخول
    if (authProvider.user != null && authProvider.profileReady) {
      // التحقق البيومتري إذا كان مفعّلاً
      bool biometricsEnabled = false;
      try {
        final prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 3));
        biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      } catch (_) {}

      if (biometricsEnabled && mounted) {
        final localAuth = LocalAuthentication();
        bool authenticated = false;
        try {
          authenticated = await localAuth
              .authenticate(
                localizedReason: 'قم بالمصادقة لفتح التطبيق',
                options: const AuthenticationOptions(
                  stickyAuth: true,
                  biometricOnly: true,
                ),
              )
              .timeout(const Duration(seconds: 30));
        } catch (e) {
          debugPrint('[Splash] Biometric error: $e');
        }
        if (!authenticated && mounted) {
          setState(() => _showBiometricRetry = true);
          return;
        }
      }

      if (mounted) _navigateTo(const MainScreen());
    } else {
      bool hasSeenOnboarding = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      } catch (_) {}

      if (!hasSeenOnboarding && mounted) {
        _navigateTo(const OnboardingScreen());
      } else if (mounted) {
        _navigateTo(const LoginScreen());
      }
    }
  }

  void _navigateTo(Widget screen) {
    if (_navigating || !mounted) return;
    _navigating = true;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => CustomPaint(
                  painter: _SplashCurvesPainter(phase: _pulse.value),
                ),
              ),
            ),
            Center(
              child: Transform.translate(
                offset: const Offset(0, -45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) => FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 230,
                          height: 230,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.school_rounded,
                            size: 100,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -10),
                    child: Column(
                      children: [
                        const SizedBox(height: 22),
                        FadeTransition(
                          opacity: _taglineFade,
                          child: SlideTransition(
                            position: _taglineSlide,
                            child: Text(
                              'تعلّم • راجع • أتقن',
                              style: GoogleFonts.cairo(
                                color: AppTheme.primaryColor,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        FadeTransition(
                          opacity: _taglineFade,
                          child: SlideTransition(
                            position: _taglineSlide,
                            child: Text(
                              'وقل رب زدني علمًا',
                              style: GoogleFonts.amiri(
                                color: AppTheme.accentColor.withValues(alpha: 0.82),
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),

                  if (_showBiometricRetry) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.backgroundLight,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.fingerprint,
                              size: 52, color: AppTheme.primaryColor),
                          const SizedBox(height: 12),
                          Text(
                            'التحقق البيومتري مطلوب',
                            style: GoogleFonts.tajawal(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showBiometricRetry = false;
                                _navigating = false;
                              });
                              _proceed();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text('إعادة المحاولة',
                                style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                  ],
                  ],
                ),
              ),
            ),
            if (!_showBiometricRetry)
              Positioned(
                left: 0,
                right: 0,
                bottom: 225,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor.withValues(alpha: 0.78),
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'جارٍ التحميل...',
                      style: GoogleFonts.tajawal(
                        color: AppTheme.primaryColor.withValues(alpha: 0.68),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SplashCurvesPainter extends CustomPainter {
  final double phase;

  const _SplashCurvesPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final motion = (phase - 0.975) * size.width * 0.08;
    _drawWave(
      canvas,
      size,
      top: size.height * 0.79 + motion,
      depth: size.height * 0.15,
      color: AppTheme.primaryColor.withValues(alpha: 0.16),
    );
    _drawWave(
      canvas,
      size,
      top: size.height * 0.87 - motion * 0.7,
      depth: size.height * 0.11,
      color: AppTheme.lightGreen.withValues(alpha: 0.22),
    );
    _drawWave(
      canvas,
      size,
      top: size.height * 0.95 + motion * 0.45,
      depth: size.height * 0.08,
      color: AppTheme.secondaryColor.withValues(alpha: 0.30),
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double top,
    required double depth,
    required Color color,
  }) {
    final path = Path()..moveTo(-size.width * 0.2, size.height);
    path.lineTo(-size.width * 0.2, top);
    path.cubicTo(
      size.width * 0.08,
      top - depth,
      size.width * 0.30,
      top + depth * 0.8,
      size.width * 0.53,
      top,
    );
    path.cubicTo(
      size.width * 0.76,
      top - depth * 0.85,
      size.width * 0.98,
      top + depth * 0.7,
      size.width * 1.2,
      top - depth * 0.05,
    );
    path.lineTo(size.width * 1.2, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SplashCurvesPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

