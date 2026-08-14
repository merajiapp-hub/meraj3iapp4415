import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'سياسة الخصوصية',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.privacy_tip_rounded,
                      size: 60,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCard(
                  isDark: isDark,
                  icon: Icons.shield_rounded,
                  title: 'مقدمة',
                  content:
                      'نحن في MERAJ3I نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. توضح سياسة الخصوصية هذه كيفية جمع واستخدام وحماية معلوماتك عند استخدام التطبيق.',
                  color: const Color(0xFF8B5CF6),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.data_usage_rounded,
                  title: 'المعلومات التي نجمعها',
                  content:
                      'عند التسجيل، قد نطلب بعض المعلومات الأساسية مثل:\n\n• الاسم\n• البريد الإلكتروني\n• رقم الهاتف\n\nنجمع أيضاً بيانات حول استخدام التطبيق (مثل الكتب المفضلة والتقدم الدراسي) لتحسين تجربتك التعليمية.',
                  color: const Color(0xFF10B981),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.settings_applications_rounded,
                  title: 'كيف نستخدم المعلومات',
                  content:
                      'تُستخدم المعلومات المجموعة لـ:\n\n• توفير خدمات التطبيق وتحسينها\n• تخصيص المحتوى التعليمي لك\n• التواصل معك بخصوص التحديثات والتنبيهات\n• تحليل الأداء وحل المشكلات التقنية',
                  color: const Color(0xFF3B82F6),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.share_rounded,
                  title: 'مشاركة البيانات',
                  content:
                      'نحن لا نبيع بياناتك الشخصية أبدًا. قد نشارك بعض البيانات مجهولة المصدر مع شركاء التحليل (مثل Google Analytics) لفهم كيفية استخدام التطبيق وتحسينه.',
                  color: const Color(0xFFF59E0B),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.security_rounded,
                  title: 'أمن البيانات',
                  content:
                      'نحن نتخذ إجراءات أمنية لحماية بياناتك من الوصول غير المصرح به. يشمل ذلك التشفير وتأمين الاتصالات. ومع ذلك، لا توجد طريقة نقل عبر الإنترنت آمنة 100%.',
                  color: const Color(0xFFEF4444),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.delete_forever_rounded,
                  title: 'حذف الحساب',
                  content:
                      'يمكنك في أي وقت طلب حذف حسابك وجميع بياناتك المرتبطة من خلال الإعدادات أو بمراسلتنا. سيتم إزالة كافة البيانات بشكل نهائي.',
                  color: const Color(0xFFEC4899),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                height: 1.8,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
