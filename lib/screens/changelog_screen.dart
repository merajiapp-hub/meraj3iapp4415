import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class _ChangelogEntry {
  final String version;
  final String date;
  final List<_ChangelogItem> items;

  const _ChangelogEntry({required this.version, required this.date, required this.items});
}

class _ChangelogItem {
  final String text;
  final _ChangelogType type;

  const _ChangelogItem(this.text, this.type);
}

enum _ChangelogType { feature, fix, improvement, remove }

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  static const List<_ChangelogEntry> _changelog = [
    _ChangelogEntry(
      version: '2.5.0',
      date: 'أغسطس 2026',
      items: [
        _ChangelogItem('بطاقة الطالب الرقمية مع مشاركة كصورة', _ChangelogType.feature),
        _ChangelogItem('صفحة تطور مستوى الطالب ورسوم بيانية', _ChangelogType.feature),
        _ChangelogItem('قائمة القراءة وسجل القراءة مع تتبع الصفحات', _ChangelogType.feature),
        _ChangelogItem('مركز المراجعة الشامل', _ChangelogType.feature),
        _ChangelogItem('مولّد الاختبارات بفلترة المادة والمستوى', _ChangelogType.feature),
        _ChangelogItem('العد التنازلي للامتحانات والأحداث المهمة', _ChangelogType.feature),
        _ChangelogItem('إصلاح قارئ PDF: جودة الخطوط العربية', _ChangelogType.fix),
        _ChangelogItem('تحسين سرعة تحميل الكتب', _ChangelogType.improvement),
      ],
    ),
    _ChangelogEntry(
      version: '2.4.0',
      date: 'يوليو 2026',
      items: [
        _ChangelogItem('الجدول الدراسي مع التقويم والتذكيرات', _ChangelogType.feature),
        _ChangelogItem('صوت الإنجاز عند إتمام المهام', _ChangelogType.feature),
        _ChangelogItem('تصدير قوائم الناجحين والراسبين كـ PDF', _ChangelogType.feature),
        _ChangelogItem('تحسين الشريط السفلي العائم', _ChangelogType.improvement),
        _ChangelogItem('إصلاح الوضع الليلي في بعض الشاشات', _ChangelogType.fix),
      ],
    ),
    _ChangelogEntry(
      version: '2.3.0',
      date: 'يونيو 2026',
      items: [
        _ChangelogItem('صفحة التبرع مع روابط تطبيقات الدفع', _ChangelogType.feature),
        _ChangelogItem('إضافة قسم كتب مرفوعة من المجتمع', _ChangelogType.feature),
        _ChangelogItem('نتائج البكالوريا والبريفي 2026', _ChangelogType.feature),
        _ChangelogItem('إحصائيات مدرسة SWEDD', _ChangelogType.feature),
        _ChangelogItem('تحسين أداء البحث عن النتائج', _ChangelogType.improvement),
      ],
    ),
    _ChangelogEntry(
      version: '2.2.0',
      date: 'مايو 2026',
      items: [
        _ChangelogItem('إضافة ميزة MERAJ3I AI', _ChangelogType.feature),
        _ChangelogItem('تحسين واجهة صفحة الكتب المدرسية', _ChangelogType.improvement),
        _ChangelogItem('دعم وضع عدم الاتصال (قراءة بدون إنترنت)', _ChangelogType.feature),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('سجل التحديثات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _changelog.length,
        itemBuilder: (context, i) {
          final entry = _changelog[i];
          final isLatest = i == 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isLatest ? AppTheme.primaryGradient : null,
                      color: isLatest ? null : (isDark ? AppTheme.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: isLatest ? null : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v${entry.version}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isLatest ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'الأحدث',
                              style: GoogleFonts.cairo(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    entry.date,
                    style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: entry.items.map((item) => _buildItem(item, isDark)).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(_ChangelogItem item, bool isDark) {
    final (icon, color) = switch (item.type) {
      _ChangelogType.feature => (Icons.add_circle_rounded, Colors.green),
      _ChangelogType.fix => (Icons.bug_report_rounded, Colors.red),
      _ChangelogType.improvement => (Icons.trending_up_rounded, Colors.blue),
      _ChangelogType.remove => (Icons.remove_circle_rounded, Colors.orange),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: GoogleFonts.cairo(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
