import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'faq_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  final String _appVersion = 'الإصدار 5.2.0';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.deepBlueGradient,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    // شعار التطبيق فقط - بدون إطار ولا بطاقة
                    Image.asset(
                      'assets/images/logo.png',
                      width: 130,
                      height: 130,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _appVersion,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('ما هو تطبيق MERAJ3I؟'),
                _buildTextCard(
                  isDark: isDark,
                  content:
                      'تطبيق MERAJ3I هو تطبيق تعليمي مصمم لمساعدة الطلاب على تنظيم مراجعتهم الدراسية والوصول بسهولة إلى الكتب والمواد التعليمية. يوفر التطبيق بيئة تعليمية متكاملة تساعد على الدراسة بفعالية.',
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('✨ ما الجديد في الإصدار 5.2.0'),
                _buildListCard(
                  isDark: isDark,
                  items: [
                    'إصلاح جذري لمحرك الذكاء الاصطناعي (Gemini 1.5 Flash) وتصفير أخطاء الاتصال',
                    'حل نهائي لمشكلة تنزيل وحفظ ملفات الـ PDF مع إضافة شاشة معاينة احترافية',
                    'تطوير نظام الإحصائيات ليعتمد كلياً على الأرقام الحقيقية والمفضلة',
                    'إعادة تصميم بطاقات نتائج الطلاب لتصبح أكثر احترافية وجمالاً',
                    'تحسين شاشة التنزيلات لفصل الكتب عن النتائج المحفوظة',
                    'تحسين نظام الإشعارات والتوافق مع التحديثات الجديدة (Flutter Local Notifications)',
                  ],
                  iconColor: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('أهداف التطبيق'),
                _buildListCard(
                  isDark: isDark,
                  items: [
                    'تسهيل الوصول إلى الكتب المدرسية والملخصات',
                    'مساعدة الطلاب على تنظيم جداول المراجعة',
                    'توفير أدوات دراسية حديثة وفعالة',
                    'دعم التعلم الذاتي والمستمر',
                  ],
                  iconColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('المميزات الرئيسية'),
                _buildListCard(
                  isDark: isDark,
                  items: [
                    'مكتبة شاملة للكتب الدراسية والمذكرات',
                    'إمكانية التحميل والقراءة بدون إنترنت',
                    'منظم دراسي ذكي لإدارة المراجعات والمهام',
                    'قسم خاص بالذكاء الاصطناعي للإجابة على الأسئلة',
                    'متابعة للامتحانات الوطنية والمسابقات',
                  ],
                  iconColor: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('الفئة المستهدفة'),
                _buildTextCard(
                  isDark: isDark,
                  content:
                      'التطبيق موجه للطلاب في جميع المراحل الدراسية الذين يسعون لتحسين مستواهم الأكاديمي وتنظيم وقتهم بشكل أفضل للحصول على أعلى الدرجات.',
                ),
                const SizedBox(height: 30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.help_outline_rounded,
                        label: 'الأسئلة الشائعة',
                        color: AppTheme.primaryColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FaqScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.star_rate_rounded,
                        label: 'تقييم التطبيق',
                        color: const Color(0xFFF59E0B),
                        onTap: () async {
                          final url = Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.meraj3i.app',
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'تم التطوير بكل ❤️ من أجل مستقبل أفضل',
                        style: GoogleFonts.tajawal(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© 2026 MERAJ3I. جميع الحقوق محفوظة.',
                        style: GoogleFonts.tajawal(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextCard({required bool isDark, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Text(
        content,
        style: GoogleFonts.tajawal(
          fontSize: 15,
          height: 1.8,
          color: isDark ? Colors.white70 : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildListCard({
    required bool isDark,
    required List<String> items,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      height: 1.5,
                      color: isDark ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
