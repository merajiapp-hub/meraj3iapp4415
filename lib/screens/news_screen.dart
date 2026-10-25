import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

class NewsScreen extends StatefulWidget {
  final String? selectedId;

  const NewsScreen({super.key, this.selectedId});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _detailOpened = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A1A15);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF52645E);

    if (widget.selectedId != null && !_detailOpened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final route = ModalRoute.of(context);
        if (route == null || route.isCurrent) {
          setState(() => _detailOpened = true);
        }
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          CurvedHeader(
            title: 'آخر الأخبار',
            gradient: AppTheme.brandGradient,
            showBackButton: true,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news')
                  .orderBy('publishedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ أثناء جلب الأخبار.',
                      style: GoogleFonts.tajawal(color: textSecondary),
                    ),
                  );
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isPublished'] == true;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.newspaper_rounded,
                          size: 64,
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Text('لا يوجد أخبار', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 8),
                        Text('لم يتم نشر أي أخبار حتى الآن.', style: GoogleFonts.tajawal(fontSize: 14, color: textSecondary)),
                      ],
                    ),
                  );
                }

                final selectedIndex = widget.selectedId != null
                    ? docs.indexWhere((doc) => doc.id == widget.selectedId)
                    : -1;

                if (widget.selectedId != null && !_detailOpened && selectedIndex != -1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final item = docs[selectedIndex];
                    final data = item.data() as Map<String, dynamic>;
                    final title = data['title']?.toString() ?? 'بدون عنوان';
                    final body = data['body']?.toString() ?? '';
                    final ts = data['publishedAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat('dd MMMM yyyy', 'ar').format(ts.toDate())
                        : '';
                    setState(() => _detailOpened = true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _NewsDetailScreen(
                          title: title,
                          body: body,
                          date: dateStr,
                        ),
                      ),
                    );
                  });
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title']?.toString() ?? 'بدون عنوان';
                    final body = data['body']?.toString() ?? '';
                    final ts = data['publishedAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat('dd MMMM yyyy', 'ar').format(ts.toDate())
                        : '';
                    final isNew = ts != null && DateTime.now().difference(ts.toDate()).inDays <= 3;

                    return InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _NewsDetailScreen(
                              title: title,
                              body: body,
                              date: dateStr,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppTheme.surfaceDark,
                                    const Color(0xFF173A33),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFE9F8F4),
                                  ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(
                              alpha: isDark ? 0.24 : 0.12,
                            ),
                            width: 1.1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: isDark ? 0.12 : 0.08,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -10,
                              left: -10,
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 12, right: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(
                                            alpha: isDark ? 0.2 : 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.newspaper_rounded,
                                          color: isDark
                                              ? AppTheme.lightGreen
                                              : AppTheme.primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(
                                            alpha: 0.11,
                                          ),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          'أخبار',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isNew)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'جديد',
                                            style: GoogleFonts.tajawal(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    title,
                                    style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.tajawal(
                                        fontSize: 13,
                                        color: textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'اقرأ المزيد',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String date;

  const _NewsDetailScreen({required this.title, required this.body, required this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: Column(
        children: [
          CurvedHeader(title: 'تفاصيل الخبر', gradient: AppTheme.brandGradient),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        date,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      body,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        height: 1.9,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
