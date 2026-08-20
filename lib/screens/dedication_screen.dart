import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/geometric_sliver_app_bar.dart';

class DedicationScreen extends StatelessWidget {
  const DedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const GeometricSliverAppBar(
            title: 'الإهداء',
            icon: Icons.auto_awesome_rounded,
            gradient: AppTheme.purpleGradient,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Decorative Frame
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 60,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                          style: GoogleFonts.amiri(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'إلى كل طالب علم يسعى لبناء مستقبله ومستقبل وطنه..\nإلى كل من زرع فينا حب التعلم والاجتهاد..\n\nنهدي هذا العمل المتواضع، سائلين المولى عز وجل أن يكون عوناً ونبراساً يضيء طريق النجاح والتفوق للجميع.',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            height: 1.8,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: 80,
                          height: 2,
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'مطور التطبيق\nمحمد محمود عبد الرحمن',
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 80,
                          height: 1,
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'إهداء خاص',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عبد اللهِ سيدي محمد',
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
}
