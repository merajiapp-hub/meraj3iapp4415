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
    const pageBg = Color(0xFFF3F7F5);
    const panelColor = Color(0xFFFFFFFF);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _safeBack();
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
        const SizedBox(height: 10),
        Text(
          'أنشئ حسابك الآن',
          textAlign: TextAlign.center,
          style: GoogleFonts.tajawal(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF163B33),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ابدأ رحلتك التعليمية من هنا',
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _nameController,
            icon: Icons.person_outline_rounded,
            hint: 'الاسم الأول',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _familyNameController,
            icon: Icons.group_outlined,
            hint: 'اسم العائلة',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emailController,
            icon: Icons.email_outlined,
            hint: 'البريد الإلكتروني',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _phoneController,
            icon: Icons.phone_outlined,
            hint: 'رقم الهاتف',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0ECE9), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedGender,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: const Color(0xFF24332D),
                ),
                items: ['ذكر', 'أنثى'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'ذكر' ? Icons.male_rounded : Icons.female_rounded,
                          size: 18,
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
          _buildTextField(
            controller: _passwordController,
            icon: Icons.lock_outline_rounded,
            hint: 'كلمة المرور',
            isPassword: true,
            isConfirm: false,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            icon: Icons.lock_outline_rounded,
            hint: 'تأكيد كلمة المرور',
            isPassword: true,
            isConfirm: true,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                  fillColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF0B6B58)
                        : const Color(0xFFDAE8E4),
                  ),
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
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
                          color: const Color(0xFF0B6B58),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      ' و',
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
                          color: const Color(0xFF0B6B58),
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
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isLoading || _isCreatingAccount) ? null : _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6B58),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                      'إنشاء الحساب',
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
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isVisible = isConfirm ? _isConfirmPasswordVisible : _isPasswordVisible;
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0ECE9), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: GoogleFonts.tajawal(
          color: const Color(0xFF24332D),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(
            color: const Color(0xFF7B847F),
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF52615C),
            size: 18,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: const Color(0xFF52615C),
                    size: 18,
                  ),
                  onPressed: () => setState(() {
                    if (isConfirm) {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    } else {
                      _isPasswordVisible = !_isPasswordVisible;
                    }
                  }),
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
          'هل لديك حساب بالفعل؟',
          style: GoogleFonts.tajawal(
            color: const Color(0xFF5E665F),
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: _safeBack,
          child: Text(
            'تسجيل الدخول',
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
}
