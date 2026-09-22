import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_notification.dart';
import 'terms_of_use_screen.dart';
import 'privacy_policy_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isCreatingAccount = false;
  bool _acceptTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _safeBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String _selectedGender = 'ذكر';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _familyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _signup() async {
    if (_isLoading) return;
    final name = _nameController.text.trim();
    final familyName = _familyNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || familyName.isEmpty || phone.isEmpty || password.isEmpty) {
      AppNotification.show(
        context,
        'الرجاء تعبئة الاسم الأول والاسم العائلي ورقم الهاتف وكلمة المرور',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      AppNotification.show(context, 'كلمات المرور غير متطابقة', isError: true);
      return;
    }

    if (!_acceptTerms) {
      AppNotification.show(
        context,
        'يجب الموافقة على شروط الاستخدام وسياسة الخصوصية',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isCreatingAccount = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signUp(
      name,
      familyName,
      email,
      password,
      phone,
      _selectedGender,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isCreatingAccount = false;
    });

    if (error == null) {
      AppNotification.show(context, 'تم إنشاء الحساب والدخول بنجاح.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      AppNotification.show(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _safeBack();
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Container(
            color: background,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            _buildHeader(),
                            const SizedBox(height: 28),
                            _buildGlassCard(),
                            const SizedBox(height: 14),
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
    const titleColor = Color(0xFF163B33);
    const subtitleColor = Color(0xFF5F7071);

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'أنشئ حسابك الآن',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ابدأ رحلتك التعليمية من هنا',
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
    const cardColor = Colors.white;
    const fieldColor = Color(0xFFF7F9F8);
    const fieldBorder = Color(0xFFE8EFED);
    const textColor = Color(0xFF21382F);
    const hintColor = Color(0xFF7C9490);
    const accent = Color(0xFF0B6B58);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B6B58).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAuthField(
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            hint: 'الاسم الأول',
            fieldColor: fieldColor,
            fieldBorder: fieldBorder,
            textColor: textColor,
            hintColor: hintColor,
          ),
          const SizedBox(height: 12),
          _buildAuthField(
            controller: _familyNameController,
            icon: Icons.group_outlined,
            hint: 'اسم العائلة',
            fieldColor: fieldColor,
            fieldBorder: fieldBorder,
            textColor: textColor,
            hintColor: hintColor,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _buildAuthField(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            hint: 'رقم الهاتف',
            fieldColor: fieldColor,
            fieldBorder: fieldBorder,
            textColor: textColor,
            hintColor: hintColor,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: fieldBorder, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedGender,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4F6660)),
                dropdownColor: Colors.white,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                items: ['ذكر', 'أنثى'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'ذكر' ? Icons.male_rounded : Icons.female_rounded,
                          size: 20,
                          color: const Color(0xFF52615C),
                        ),
                        const SizedBox(width: 10),
                        Text(value, style: GoogleFonts.tajawal()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedGender = newValue);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _buildAuthField(
            controller: _confirmPasswordController,
            icon: Icons.lock_outline_rounded,
            hint: 'تأكيد كلمة المرور',
            fieldColor: fieldColor,
            fieldBorder: fieldBorder,
            textColor: textColor,
            hintColor: hintColor,
            isPassword: true,
            showToggle: true,
            toggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            isVisible: _isConfirmPasswordVisible,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  fillColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected) ? accent : Colors.transparent,
                  ),
                  checkColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFF9EB9B1),
                    width: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'أوافق على ',
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFF5E665F),
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                      ),
                      child: Text(
                        'الشروط',
                        style: GoogleFonts.tajawal(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      ' و ',
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFF5E665F),
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      ),
                      child: Text(
                        'سياسة الخصوصية',
                        style: GoogleFonts.tajawal(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isLoading || _isCreatingAccount) ? null : _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: (_isLoading || _isCreatingAccount)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'إنشاء حساب',
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
    const mutedColor = Color(0xFF5E665F);
    const accent = Color(0xFF0B6B58);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'هل لديك حساب بالفعل؟',
          style: GoogleFonts.tajawal(
            color: mutedColor,
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: _safeBack,
          child: Text(
            'تسجيل الدخول',
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
}
