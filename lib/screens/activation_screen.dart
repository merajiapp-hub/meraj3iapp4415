import 'package:flutter/material.dart';
import '../widgets/app_notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      AppNotification.show(context, 'الرجاء إدخال كود التفعيل', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _countdown = 10;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdown > 1) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
          // Activation system removed - show info message
          AppNotification.show(context, 'التطبيق متاح للجميع بدون تفعيل.');
        }
      }
    });
  }

  void _contactAdmin(String stage, String codePrefix) async {
    final String message = Uri.encodeComponent(
      'أريد كود تفعيل $stage ($codePrefix)',
    );
    final Uri url = Uri.parse('https://wa.me/22244154142?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        AppNotification.show(context, 'لا يمكن فتح واتساب', isError: true);
      }
    }
  }

  Widget _buildContactButton(String title, String prefix, IconData icon) {
    return InkWell(
      onTap: () => _contactAdmin(title, prefix),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green[700], size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تفعيل الحساب (Premium)',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 60,
                  color: AppTheme.accentColor,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'تفعيل محتوى مراجعي',
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'الرجاء إدخال كود التفعيل الخاص بمرحلتك للوصول إلى كافة الميزات والمحتوى.',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'كود التفعيل',
                  hintText: 'MERAJ3I-XXXXXXXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SpinKitThreeBounce(
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'جاري التحقق من الكود $_countdown',
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'تفعيل المحتوى',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              Text(
                'للحصول على كود التفعيل، تواصل معنا عبر واتساب باختيار مرحلتك:',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildContactButton('المرحلة الابتدائية', 'ME', Icons.school),
                  _buildContactButton('إعدادية', 'RA', Icons.menu_book),
                  _buildContactButton('ثانوية علوم', 'JI', Icons.science),
                  _buildContactButton('ثانوية رياضيات', 'MA', Icons.calculate),
                  _buildContactButton('آداب عصرية', 'AB', Icons.history_edu),
                  _buildContactButton('آداب أصلية', 'BE', Icons.mosque),
                  _buildContactButton('الاشتراك الشامل', 'Premium', Icons.star),
                ],
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(isGuest: true),
                    ),
                  );
                },
                child: Text(
                  'المتابعة كضيف (تصفح فقط)',
                  style: GoogleFonts.tajawal(
                    color: Colors.grey[600],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
