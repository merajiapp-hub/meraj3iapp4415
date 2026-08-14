import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';
import 'login_screen.dart';

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
      duration: const Duration(milliseconds: 1500),
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
    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _logoController.forward();

    // ننتقل بعد 1.5 ثانية — أسرع بكثير من السابق (كان 1800ms)
    Future.delayed(const Duration(milliseconds: 1500), () {
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
      _navigateTo(const HomePage(isGuest: true));
      return;
    }

    // تحقق من تسجيل الدخول
    if (authProvider.user != null) {
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

      if (mounted) _navigateTo(const HomePage());
    } else {
      _navigateTo(const LoginScreen());
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // دوائر زخرفية
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: _pulse.value,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            // المحتوى الرئيسي
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الشعار
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) => FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 220,
                          height: 220,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.school_rounded,
                                size: 80, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  if (_showBiometricRetry) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.fingerprint,
                              size: 52, color: Colors.white),
                          const SizedBox(height: 12),
                          Text(
                            'التحقق البيومتري مطلوب',
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
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
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
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
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'جارٍ التحميل...',
                      style: GoogleFonts.tajawal(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
