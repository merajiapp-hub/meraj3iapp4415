import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/auth_provider.dart';
import '../../shared/layout/admin_layout.dart';
import '../../core/theme/admin_colors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // First attempt to sign in
    final error = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    // Give it a brief moment for auth state to update and admin status to be checked
    await Future.delayed(const Duration(milliseconds: 500));

    if (!authProvider.isAdmin) {
      // If signed in but not an admin, sign them out and show error
      await authProvider.signOut();
      setState(() {
        _errorMessage = 'عذراً، هذا الحساب لا يملك صلاحيات الإدارة';
        _isLoading = false;
      });
      return;
    }

    // Success - navigate to dashboard
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0F172A) : AdminColors.background;
    final panelBg = isDark ? const Color(0xFF111827) : Colors.white;
    final textMain = isDark ? Colors.white : AdminColors.textDark;
    final textSoft = isDark ? Colors.white70 : AdminColors.textLight;
    final border = isDark ? Colors.white12 : AdminColors.borderSoft;
    final fieldBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
    final fieldText = isDark ? Colors.white : AdminColors.textDark;

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Container(
              decoration: BoxDecoration(
                color: panelBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 820;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(30),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AdminColors.primary, Color(0xFF0E63D2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.business_center_rounded, color: AdminColors.primaryDeep, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'MERAJ3I Admin',
                                          style: GoogleFonts.tajawal(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      width: 220,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 84),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Text(
                                      'نظام إدارة متكامل',
                                      style: GoogleFonts.tajawal(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'إدارة المستخدمين، الكتب، الإشعارات والتحليلات من لوحة واحدة.',
                                      style: GoogleFonts.tajawal(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.7,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تسجيل الدخول',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'مرحباً بك مجدداً في لوحة الإدارة',
                                      style: GoogleFonts.tajawal(
                                        color: textSoft,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    if (_errorMessage != null)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.error_outline_rounded, color: Colors.red.shade500),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: GoogleFonts.tajawal(
                                                  color: Colors.red.shade500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    TextField(
                                      controller: _emailController,
                                      style: GoogleFonts.tajawal(color: fieldText),
                                      decoration: InputDecoration(
                                        labelText: 'البريد الإلكتروني',
                                        labelStyle: GoogleFonts.tajawal(color: textSoft),
                                        prefixIcon: const Icon(Icons.email_outlined),
                                        filled: true,
                                        fillColor: fieldBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminColors.primary, width: 1.5),
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                    ),
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: _passwordController,
                                      style: GoogleFonts.tajawal(color: fieldText),
                                      decoration: InputDecoration(
                                        labelText: 'كلمة المرور',
                                        labelStyle: GoogleFonts.tajawal(color: textSoft),
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: textSoft,
                                          ),
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                        filled: true,
                                        fillColor: fieldBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: AdminColors.primary, width: 1.5),
                                        ),
                                      ),
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _login(),
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AdminColors.primary, Color(0xFF0E63D2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.business_center_rounded, color: AdminColors.primaryDeep, size: 28),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'MERAJ3I Admin',
                                      style: GoogleFonts.tajawal(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: panelBg,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تسجيل الدخول',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'مرحباً بك مجدداً في لوحة الإدارة',
                                      style: GoogleFonts.tajawal(color: textSoft),
                                    ),
                                    const SizedBox(height: 20),
                                    if (_errorMessage != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: isDark ? 0.18 : 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.tajawal(color: Colors.red.shade500, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    TextField(
                                      controller: _emailController,
                                      style: GoogleFonts.tajawal(color: fieldText),
                                      decoration: InputDecoration(
                                        labelText: 'البريد الإلكتروني',
                                        labelStyle: GoogleFonts.tajawal(color: textSoft),
                                        prefixIcon: const Icon(Icons.email_outlined),
                                        filled: true,
                                        fillColor: fieldBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: border),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _passwordController,
                                      style: GoogleFonts.tajawal(color: fieldText),
                                      decoration: InputDecoration(
                                        labelText: 'كلمة المرور',
                                        labelStyle: GoogleFonts.tajawal(color: textSoft),
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: textSoft),
                                          onPressed: () {
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                        filled: true,
                                        fillColor: fieldBg,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: border),
                                        ),
                                      ),
                                      obscureText: _obscurePassword,
                                      onSubmitted: (_) => _login(),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AdminColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : Text('تسجيل الدخول', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
