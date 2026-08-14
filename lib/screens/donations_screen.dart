import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/geometric_sliver_app_bar.dart';

class DonationsScreen extends StatelessWidget {
  const DonationsScreen({super.key});

  void _copyNumber(BuildContext context, String number, String appName) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تم نسخ رقم $appName بنجاح!',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // يرجى استبدال هذه الأرقام بالأرقام الفعلية الخاصة بك
    final paymentMethods = [
      {
        'name': 'Bankily',
        'image': 'assets/pay/Bankily.png',
        'number': '41919108', // استبدل برقمك
        'color': const Color(0xFF00B0FF),
      },
      {
        'name': 'Masrvi',
        'image': 'assets/pay/Masrvi.png',
        'number': '41919108', // استبدل برقمك
        'color': const Color(0xFFF57F17),
      },
      {
        'name': 'SEDAD',
        'image': 'assets/pay/SEDAD.png',
        'number': '41919108', // استبدل برقمك
        'color': const Color(0xFF1B5E20),
      },
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const GeometricSliverAppBar(
            title: 'دعم التطبيق',
            icon: Icons.volunteer_activism_rounded,
            gradient: AppTheme.primaryGradient,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppTheme.deepBlueGradient
                          : AppTheme.blueGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'مساهمتك تصنع الفارق!',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تطبيق MERAJ3I هو جهد شخصي ومجاني بالكامل. دعمك لنا يساعد في استمرار التطبيق، تطوير المزيد من المحتوى، وتغطية تكاليف الخوادم والتحديثات لخدمة جميع الطلاب.',
                          style: GoogleFonts.tajawal(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 15,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'طرق الدعم المتوفرة',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...paymentMethods.map(
                    (method) => _buildPaymentCard(
                      context: context,
                      name: method['name'] as String,
                      image: method['image'] as String,
                      number: method['number'] as String,
                      color: method['color'] as Color,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard({
    required BuildContext context,
    required String name,
    required String image,
    required String number,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _copyNumber(context, number, name),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // صورة التطبيق
                Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(image, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 20),
                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_android_rounded,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              number,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // زر النسخ
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.copy_rounded, color: color, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
