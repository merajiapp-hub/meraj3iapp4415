import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

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
                'شروط الاستخدام',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.gavel_rounded,
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
                  icon: Icons.info_outline_rounded,
                  title: 'مقدمة',
                  content:
                      'تحدد هذه الاتفاقية الشروط والأحكام التي تحكم استخدام تطبيق MERAJ3I. باستخدامك للتطبيق فإنك توافق على الالتزام بهذه الشروط. إذا كنت لا توافق على هذه الشروط فيجب عليك عدم استخدام التطبيق.',
                  color: const Color(0xFF3B82F6),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.phone_android_rounded,
                  title: 'استخدام التطبيق',
                  content:
                      'يهدف تطبيق MERAJ3I إلى مساعدة الطلاب على المراجعة وتنظيم الدراسة من خلال توفير الكتب الدراسية والمواد التعليمية وأدوات تنظيم المراجعة.\n\n• يجب استخدام التطبيق للأغراض التعليمية فقط.\n• يُمنع استخدام التطبيق لأي نشاط غير قانوني أو ضار.',
                  color: const Color(0xFF10B981),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.person_outline_rounded,
                  title: 'الحسابات',
                  content:
                      'عند إنشاء حساب داخل التطبيق يجب على المستخدم تقديم معلومات صحيحة، والحفاظ على سرية بيانات تسجيل الدخول، وعدم مشاركة الحساب مع الآخرين. المستخدم مسؤول عن جميع الأنشطة التي تتم باستخدام حسابه.',
                  color: const Color(0xFF8B5CF6),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.menu_book_rounded,
                  title: 'المحتوى داخل التطبيق',
                  content:
                      'يحتوي التطبيق على مواد تعليمية مثل الكتب، الدروس، التمارين، والامتحانات. جميع هذه المواد مخصصة للاستخدام الشخصي والتعليمي فقط. يُمنع إعادة نشر أو بيع أو توزيع المحتوى بدون إذن.',
                  color: const Color(0xFFF59E0B),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'تحديد المسؤولية',
                  content:
                      'نحن نسعى لتقديم أفضل تجربة ممكنة، ولكن لا نضمن أن التطبيق سيعمل بدون انقطاع في جميع الأوقات. التطبيق يقدم محتوى تعليمي للمساعدة في الدراسة فقط.',
                  color: const Color(0xFFEF4444),
                ),
                _buildCard(
                  isDark: isDark,
                  icon: Icons.update_rounded,
                  title: 'التعديلات',
                  content:
                      'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إشعار المستخدمين بأي تغييرات هامة، ويُعتبر استمرار استخدام التطبيق موافقة على الشروط المعدلة.',
                  color: const Color(0xFF0EA5E9),
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
