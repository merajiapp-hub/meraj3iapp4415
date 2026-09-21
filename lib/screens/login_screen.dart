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
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  late final TabController _tabController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

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
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
    _loadSavedCredentials();
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

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPhone = prefs.getString('saved_phone');

    if ((savedEmail?.isNotEmpty ?? false) || (savedPhone?.isNotEmpty ?? false)) {
      if (!mounted) return;
      setState(() {
        _rememberMe = true;
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
    if (_isLoading) return;

    final isEmail = _tabController.index == 0;
    final id = (isEmail ? _emailController.text : _phoneController.text).trim();
    final pass = _passwordController.text.trim();

    if (id.isEmpty || pass.isEmpty) {
      AppNotification.show(context, 'الرجاء إدخال بيانات الدخول كاملة', isError: true);
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
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        if (isEmail) {
          await prefs.setString('saved_email', id);
          await prefs.remove('saved_phone');
        } else {
          await prefs.setString('saved_phone', id);
          await prefs.remove('saved_email');
        }
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_phone');
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
    const pageBg = Color(0xFFF3F7F5);
    const panelColor = Color(0xFFFFFFFF);

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
        backgroundColor: pageBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildGlassCard(),
                          const SizedBox(height: 16),
                          _buildGuestButton(),
                          const SizedBox(height: 10),
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
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 78,
          height: 78,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 14),
        Text(
          'مرحباً بعودتك',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF163B33),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'سجل الدخول للاستمرار في رحلتك',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: const Color(0xFF5F7071),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    const panelColor = Color(0xFFFFFFFF);
    const fieldBg = Color(0xFFF3F7F5);
    const dividerColor = Color(0xFFDDEAE7);
    const activeColor = Color(0xFF0B6B58);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE3EFEA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3F1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: activeColor,
              ),
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF4E615C),
              indicatorPadding: const EdgeInsets.all(4),
              labelStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: 'البريد'),
                Tab(text: 'الهاتف'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _tabController.index == 0
                ? _buildTextField(
                    key: const ValueKey('email'),
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'البريد الإلكتروني',
                    keyboardType: TextInputType.emailAddress,
                  )
                : _buildTextField(
                    key: const ValueKey('phone'),
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: 'رقم الهاتف',
                    keyboardType: TextInputType.phone,
                  ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            hint: 'كلمة المرور',
            isPassword: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (val) => setState(() => _rememberMe = val ?? false),
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? activeColor
                            : const Color(0xFFDAE8E4),
                      ),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تذكرني',
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFF556664),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  foregroundColor: activeColor,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'نسيت كلمة المرور؟',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D322E) : const Color(0xFFF5F9F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A43) : const Color(0xFFE0ECE9),
          width: 1,
        ),
      ),
      child: TextField(
        key: key,
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: GoogleFonts.tajawal(
          color: isDark ? Colors.white : const Color(0xFF21382F),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(
            color: const Color(0xFF7C8C88),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF4F6660),
            size: 18,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFF52615C),
                    size: 18,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'ليس لديك حساب؟',
          style: GoogleFonts.tajawal(
            color: const Color(0xFF5E665F),
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
              color: const Color(0xFF0B6B58),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton() {
    final guestEnabled = context.watch<AppConfigProvider>().allowGuestView;
    if (!guestEnabled) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: _isLoading ? null : _loginAsGuest,
      icon: Icon(
        Icons.person_outline_rounded,
        size: 20,
        color: Colors.white.withValues(alpha: 0.7),
      ),
      label: Text(
        'المتابعة كزائر',
        style: GoogleFonts.tajawal(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
