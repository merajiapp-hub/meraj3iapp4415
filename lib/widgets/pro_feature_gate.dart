import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/pro_subscription_screen.dart';
import '../theme/app_theme.dart';
import 'pro_badge.dart';

class ProFeatureGate {
  /// يتحقق من صلاحية الوصول للخدمة المحددة
  /// إذا كان المستخدم يملك Pro أو الخدمة مجانية، يتم تنفيذ onAllowed مباشرة.
  /// إذا كانت الخدمة مقفلة، تظهر نافذة الترقية المميزة.
  static void checkAccess({
    required BuildContext context,
    required String featureKey,
    required String featureName,
    required VoidCallback onAllowed,
  }) {
    final auth = context.read<AuthProvider>();

    // إذا كان حساب المستخدم Pro نشطاً، يُسمح له بالدخول فوراً
    if (auth.isPro) {
      onAllowed();
      return;
    }

    // عرض نافذة الترقية
    showProLockedDialog(
      context: context,
      featureName: featureName,
    );
  }

  static void showProLockedDialog({
    required BuildContext context,
    required String featureName,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D2A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),

              // الأيقونة والشارة الذهبية
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),

              const ProBadge(fontSize: 12),
              const SizedBox(height: 12),

              Text(
                'خدمة خاصة بمشتركي Pro',
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              Text(
                '«$featureName» متاحة حصرياً للمشتركين في باقة مراجعي Pro مع كافة الاختبارات والامتحانات وبدون أي إعلانات.',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // قائمة المميزات
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      icon: Icons.quiz_rounded,
                      text: 'فتح جميع الاختبارات الذكية والمحاكاة',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildBenefitRow(
                      icon: Icons.history_edu_rounded,
                      text: 'الوصول للامتحانات الوطنية مع الحلول النموذجية',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildBenefitRow(
                      icon: Icons.block_rounded,
                      text: 'إزالة الإعلانات نهائياً لتجربة دراسية نقية وسريعة',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildBenefitRow(
                      icon: Icons.verified_rounded,
                      text: 'شارة Pro ذهبية تبرز ملفك الشخصي',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // زر الترقية المباشر
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProSubscriptionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'ترقية الحساب والاشتراك الآن',
                        style: GoogleFonts.tajawal(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // زر الإغلاق
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'ليس الآن، سأتابع لاحقاً',
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
