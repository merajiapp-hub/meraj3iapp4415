import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import '../models/announcement_data.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String? selectedId;

  const AnnouncementsScreen({super.key, this.selectedId});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  bool _detailOpened = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final backgroundColor = isDark
        ? AppTheme.backgroundDark
        : AppTheme.backgroundLight;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A1A15);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF52645E);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          CurvedHeader(
            title: 'الإعلانات',
            gradient: AppTheme.brandGradient,
            showBackButton: true,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('createdAt', descending: true)
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
                      'حدث خطأ أثناء جلب الإعلانات.',
                      style: GoogleFonts.tajawal(color: textSecondary),
                    ),
                  );
                }

                final docs = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return AnnouncementData.isActive(data);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          size: 64,
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا يوجد إعلانات',
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'لم يتم نشر أي إعلانات حتى الآن.',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
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
                    final body = AnnouncementData.body(data);
                    final ts = data['createdAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat('dd MMMM yyyy', 'ar').format(ts.toDate())
                        : '';
                    setState(() => _detailOpened = true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _AnnouncementDetailScreen(
                          title: title,
                          body: body,
                          date: dateStr,
                        ),
                      ),
                    );
                  });
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title']?.toString() ?? 'بدون عنوان';
                    final body = AnnouncementData.body(data);
                    final ts = data['createdAt'] as Timestamp?;
                    final dateStr = ts != null
                        ? DateFormat('dd MMMM yyyy', 'ar').format(ts.toDate())
                        : '';
                    final isNew = ts != null && DateTime.now().difference(ts.toDate()).inDays <= 3;

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _AnnouncementDetailScreen(
                              title: title,
                              body: body,
                              date: dateStr,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppTheme.surfaceDark,
                                    const Color(0xFF153D32),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFF0F9F6),
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
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -10,
                              left: -10,
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(
                                            alpha: isDark ? 0.2 : 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.campaign_rounded,
                                          color: isDark
                                              ? AppTheme.lightGreen
                                              : AppTheme.primaryColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
                                          'إعلانات',
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
                                  const SizedBox(height: 9),
                                  Text(
                                    title,
                                    style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    dateStr,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 7),
                                    Text(
                                      body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.tajawal(
                                        fontSize: 12,
                                        color: textSecondary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      Text(
                                        'اقرأ المزيد',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 12,
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

class _AnnouncementDetailScreen extends StatelessWidget {
  final String title;
  final String body;
  final String date;

  const _AnnouncementDetailScreen({
    required this.title,
    required this.body,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: Column(
        children: [
          CurvedHeader(
            title: 'تفاصيل الإعلان',
            gradient: AppTheme.brandGradient,
          ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
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
