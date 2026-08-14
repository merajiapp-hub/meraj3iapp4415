import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_notification.dart';
import 'home_page.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late TabController _tabController;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
    _loadSavedCredentials();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = false;
    try {
      canCheck =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      // Ignored
    }
    setState(() => _canCheckBiometrics = canCheck);
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPhone = prefs.getString('saved_phone');
    final savedPassword = prefs.getString('saved_password');
    if (savedPassword != null) {
      setState(() {
        _rememberMe = true;
        _passwordController.text = savedPassword;
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
          _tabController.index = 0;
        } else if (savedPhone != null && savedPhone.isNotEmpty) {
          _phoneController.text = savedPhone;
          _tabController.index = 1;
        }
      });
    }
  }

  void _login() async {
    final isEmail = _tabController.index == 0;
    final id = isEmail
        ? _emailController.text.trim()
        : _phoneController.text.trim();
    final pass = _passwordController.text.trim();

    if (id.isEmpty || pass.isEmpty) {
      AppNotification.show(
        context,
        'الرجاء إدخال بيانات الدخول كاملة',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = isEmail
        ? await authProvider.signIn(id, pass)
        : await authProvider.signInWithPhone(id, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        if (isEmail) {
          prefs.setString('saved_email', id);
          prefs.remove('saved_phone');
        } else {
          prefs.setString('saved_phone', id);
          prefs.remove('saved_email');
        }
        prefs.setString('saved_password', pass);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('saved_email');
        prefs.remove('saved_phone');
        prefs.remove('saved_password');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      AppNotification.show(context, error, isError: true);
    }
  }

  void _loginWithBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPhone = prefs.getString('saved_phone');
    final savedPassword = prefs.getString('saved_password');

    if (savedPassword == null || (savedEmail == null && savedPhone == null)) {
      if (!mounted) return;
      AppNotification.show(
        context,
        'لم يتم العثور على بيانات محفوظة لاستخدام البصمة',
        isError: true,
      );
      return;
    }

    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'قم بالمصادقة لتسجيل الدخول',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppNotification.show(context, 'فشلت المصادقة البيومترية', isError: true);
    }

    if (!mounted) return;
    if (authenticated) {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final error = savedEmail != null && savedEmail.isNotEmpty
          ? await authProvider.signIn(savedEmail, savedPassword)
          : await authProvider.signInWithPhone(savedPhone!, savedPassword);

      if (!mounted) return;
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        AppNotification.show(context, error, isError: true);
      }
    }
  }

  void _loginAsGuest() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.setGuestMode(true);
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage(isGuest: true)),
    );
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      AppNotification.show(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepBlueGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildGlassCard(),
                          const Spacer(),
                          const SizedBox(height: 20),
                          _buildGuestButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // شعار التطبيق الحقيقي — بدون حواف أو كروت
        Image.asset(
          'assets/images/logo.png',
          width: 150,
          height: 150,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 16),
        Text(
          'أهلاً بك مجدداً',
          style: GoogleFonts.tajawal(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'قم بتسجيل الدخول للمتابعة',
          style: GoogleFonts.tajawal(
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tabs
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppTheme.primaryColor,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              labelStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'البريد الإلكتروني'),
                Tab(text: 'رقم الهاتف'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Input Fields based on Tab
          SizedBox(
            height: 70,
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  hint: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  hint: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            hint: 'كلمة المرور',
            isPassword: true,
          ),

          const SizedBox(height: 16),
          // Remember me & Forgot Password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val!),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تذكرني',
                    style: GoogleFonts.tajawal(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'تسجيل الدخول',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          // Biometrics
          const SizedBox(height: 20),
          if (_canCheckBiometrics) ...[
            GestureDetector(
              onTap: _loginWithBiometrics,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تسجيل الدخول بالبصمة',
                    style: GoogleFonts.tajawal(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ─── Google Sign-In ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'أو',
                  style: GoogleFonts.tajawal(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _loginWithGoogle,
              icon: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 22,
                  height: 22,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              label: Text(
                'تسجيل الدخول بـ Google',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ليس لديك حساب؟',
                style: GoogleFonts.tajawal(
                  color: Colors.white.withValues(alpha: 0.7),
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
                  'سجل الآن',
                  style: GoogleFonts.tajawal(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        style: GoogleFonts.tajawal(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(
            color: Colors.white.withValues(alpha: 0.4),
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.transparent,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'استعادة كلمة المرور',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور.',
                style: GoogleFonts.tajawal(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.tajawal(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    hintStyle: GoogleFonts.tajawal(color: Colors.white38),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.white38,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) return;
                      setDialogState(() => isSending = true);
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final error = await authProvider.resetPassword(email);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (error == null) {
                        if (!mounted) return;
                        AppNotification.show(
                          context,
                          'تم إرسال رابط الاسترداد إلى $email',
                        );
                      } else {
                        if (!mounted) return;
                        AppNotification.show(context, error, isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'إرسال',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return TextButton.icon(
      onPressed: _isLoading ? null : _loginAsGuest,
      icon: Icon(
        Icons.person_outline_rounded,
        color: Colors.white.withValues(alpha: 0.7),
      ),
      label: Text(
        'المتابعة كزائر',
        style: GoogleFonts.tajawal(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
