import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/app_config_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_notification.dart';
import 'account_suspended_screen.dart';
import 'main_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');

    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _rememberMe = true;
        _emailController.text = savedEmail;
      });
    }
  }

  void _login() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      AppNotification.show(context, 'الرجاء إدخال البريد الإلكتروني وكلمة المرور', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(email, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', email);
      } else {
        await prefs.remove('saved_email');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }

    if (error == 'suspended') {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountSuspendedScreen()),
      );
      return;
    }

    AppNotification.show(context, error, isError: true);
  }

  void _loginAsGuest() async {
    final appConfig = Provider.of<AppConfigProvider>(context, listen: false);
    if (!appConfig.allowGuestView) {
      AppNotification.show(
        context,
        'تم تعطيل دخول الضيف من إعدادات التطبيق في الوقت الحالي.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.setGuestMode(true);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen(isGuest: true)),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'استعادة كلمة المرور',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل البريد الإلكتروني المرتبط بالحساب ليصلك رابط الاستعادة.',
                style: GoogleFonts.tajawal(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) {
                        AppNotification.show(
                          context,
                          'يرجى إدخال البريد الإلكتروني',
                          isError: true,
                        );
                        return;
                      }

                      setDialogState(() => isSending = true);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final error = await auth.resetPassword(email);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (!mounted) return;
                      if (error == null) {
                        AppNotification.show(
                          context,
                          'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني',
                        );
                      } else {
                        AppNotification.show(context, error, isError: true);
                      }
                    },
              child: Text(
                isSending ? 'جارٍ الإرسال...' : 'إرسال',
                style: GoogleFonts.tajawal(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgStart = isDark ? const Color(0xFF091A16) : const Color(0xFFF3F7F5);
    final bgEnd = isDark ? const Color(0xFF122B25) : const Color(0xFFEAF6F2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgStart,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgStart, bgEnd],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildGlassCard(),
                            const SizedBox(height: 18),
                            _buildGuestButton(),
                            const SizedBox(height: 8),
                            _buildFooterLink(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF163B33);
    final subtitleColor = isDark ? const Color(0xFFB3D1CC) : const Color(0xFF5F7071);

    return Column(
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B6B58), Color(0xFF14A085)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B6B58).withValues(alpha: 0.30),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'مرحباً بعودتك',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'سجل دخولك لاستمرار رحلتك التعليمية',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF132C28) : Colors.white;
    final fieldColor = isDark ? const Color(0xFF183731) : const Color(0xFFF7FBF9);
    final fieldBorder = isDark ? const Color(0xFF2A4A43) : const Color(0xFFE5EEEA);
    final textColor = isDark ? Colors.white : const Color(0xFF21382F);
    final hintColor = isDark ? const Color(0xFFAECAC2) : const Color(0xFF7E9A95);
    final accent = const Color(0xFF0B6B58);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE3EFEA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAuthField(
            controller: _emailController,
            icon: Icons.email_outlined,
            hint: 'البريد الإلكتروني',
            fieldColor: fieldColor,
            fieldBorder: fieldBorder,
            textColor: textColor,
            hintColor: hintColor,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildAuthField(
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            hint: 'كلمة المرور',
            fieldColor: fieldColor,
            fieldBorder: fieldBorder,
            textColor: textColor,
            hintColor: hintColor,
            isPassword: true,
            showToggle: true,
            toggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            isVisible: _isPasswordVisible,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) => setState(() => _rememberMe = value ?? false),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected) ? accent : Colors.transparent,
                      ),
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: isDark ? const Color(0xFF6E9A8F) : const Color(0xFF9EB9B1),
                        width: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تذكرني',
                    style: GoogleFonts.tajawal(
                      color: isDark ? Colors.white70 : const Color(0xFF556664),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'تسجيل الدخول',
                      style: GoogleFonts.tajawal(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color fieldColor,
    required Color fieldBorder,
    required Color textColor,
    required Color hintColor,
    bool isPassword = false,
    bool showToggle = false,
    VoidCallback? toggleVisibility,
    bool isVisible = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: fieldBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !isVisible,
        textAlign: TextAlign.right,
        style: GoogleFonts.tajawal(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(color: hintColor, fontSize: 13.5),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          prefixIcon: Icon(icon, color: const Color(0xFF4F6660), size: 20),
          suffixIcon: showToggle
              ? IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFF52615C),
                    size: 20,
                  ),
                  onPressed: toggleVisibility,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white70 : const Color(0xFF5E665F);
    final accent = const Color(0xFF0B6B58);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: GoogleFonts.tajawal(
            color: mutedColor,
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          child: Text(
            'إنشاء حساب',
            style: GoogleFonts.tajawal(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guestEnabled = context.watch<AppConfigProvider>().allowGuestView;
    if (!guestEnabled) {
      return const SizedBox.shrink();
    }

    final primaryColor = isDark ? Colors.white : const Color(0xFF0B6B58);

    return TextButton.icon(
      onPressed: _isLoading ? null : _loginAsGuest,
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
      icon: Icon(
        Icons.person_outline_rounded,
        size: 20,
        color: primaryColor,
      ),
      label: Text(
        'المتابعة كزائر',
        style: GoogleFonts.tajawal(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: primaryColor.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
