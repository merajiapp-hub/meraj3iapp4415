import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/downloads_provider.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import '../widgets/banner_ad_widget.dart';
import 'pdf_viewer_screen.dart';
import 'downloaded_section_books_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  // 0 = عرض حسب أزرار الأقسام (الافتراضي)، 1 = عرض كل الكتب مع شريط فاصل
  int _viewMode = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String getSectionName(DownloadedBook book) {
    if (book.section.trim().isNotEmpty) {
      return book.section.trim();
    }
    if (book.category.trim().isNotEmpty) {
      return book.category.trim();
    }
    return 'قسم عام';
  }

  static IconData getSectionIcon(String section) {
    final s = section.toLowerCase();
    if (s.contains('ابتدائ')) return Icons.menu_book_rounded;
    if (s.contains('إعداد') || s.contains('اعداد')) {
      return Icons.auto_stories_rounded;
    }
    if (s.contains('ثانوي')) return Icons.school_rounded;
    if (s.contains('امتحان') ||
        s.contains('concours') ||
        s.contains('brevet') ||
        s.contains('bac')) {
      return Icons.emoji_events_rounded;
    }
    if (s.contains('swedd')) return Icons.volunteer_activism_rounded;
    return Icons.collections_bookmark_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          Consumer<DownloadsProvider>(
            builder: (context, provider, _) {
              final count = provider.downloads.length;
              final totalMb = provider.downloads.fold<double>(
                0.0,
                (acc, b) => acc + b.fileSizeMb,
              );
              return CurvedHeader(
                title: 'التنزيلات',
                subtitle: count > 0
                    ? '$count ${count == 1 ? "كتاب محفوظ" : "كتب محفوظة"} • ${totalMb.toStringAsFixed(1)} MB'
                    : 'الكتب المحفوظة للقراءة دون إنترنت',
                gradient: isDark
                    ? AppTheme.deepBlueGradient
                    : AppTheme.primaryGradient,
                showBackButton: false,
              );
            },
          ),
          Expanded(
            child: Consumer<DownloadsProvider>(
              builder: (context, provider, child) {
                final books = provider.downloads;
                if (books.isEmpty) {
                  return _buildEmptyState(isDark);
                }
                return _buildBody(provider, books, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    DownloadsProvider provider,
    List<DownloadedBook> allBooks,
    bool isDark,
  ) {
    // تجميع الكتب حسب الأقسام
    final Map<String, List<DownloadedBook>> grouped = {};
    for (final book in allBooks) {
      final sec = getSectionName(book);
      grouped.putIfAbsent(sec, () => []).add(book);
    }

    final totalMb = allBooks.fold<double>(
      0.0,
      (acc, b) => acc + b.fileSizeMb,
    );

    // تصفية نتائج البحث إن وُجدت
    final query = _searchQuery.trim().toLowerCase();
    final searchFilteredBooks = query.isEmpty
        ? allBooks
        : allBooks.where((b) {
            return b.title.toLowerCase().contains(query) ||
                b.section.toLowerCase().contains(query) ||
                b.grade.toLowerCase().contains(query);
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── بطاقة إحصائية عليا لمكتبتي المنزلة ──
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.offline_pin_rounded,
                      color: AppTheme.secondaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مكتبتي دون اتصال',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'الكتب منظمة ومحفوظة بالكامل للقراءة دون إنترنت',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _StatBadge(
                    icon: Icons.menu_book_rounded,
                    label: '${allBooks.length} كتب',
                  ),
                  const SizedBox(width: 8),
                  _StatBadge(
                    icon: Icons.category_rounded,
                    label: '${grouped.keys.length} أقسام',
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${totalMb.toStringAsFixed(1)} MB',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF083D2F),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── شريط التبديل بين طريقة العرض (حسب الأقسام / كل الكتب) ──
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeSwitchButton(
                  title: 'أزرار الأقسام المخصصة',
                  icon: Icons.grid_view_rounded,
                  isSelected: _viewMode == 0,
                  onTap: () => setState(() => _viewMode = 0),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ModeSwitchButton(
                  title: 'كل الكتب مع فواصل',
                  icon: Icons.view_agenda_rounded,
                  isSelected: _viewMode == 1,
                  onTap: () => setState(() => _viewMode = 1),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),

        // ── شريط البحث ──
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.cairo(
              fontSize: 13.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث في الكتب المنزلة...',
              hintStyle: GoogleFonts.cairo(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),

        // ── نتائج البحث المباشر (عند الكتابة في البحث) ──
        if (query.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              'نتائج البحث (${searchFilteredBooks.length})',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          if (searchFilteredBooks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'لا توجد كتب منزلة تطابق بحثك',
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            )
          else
            ...searchFilteredBooks.map(
              (book) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DownloadedBookCard(
                  db: book,
                  isDark: isDark,
                  onDelete: () => _confirmDeleteBook(context, provider, book),
                ),
              ),
            ),
        ] else if (_viewMode == 0) ...[
          // ════════════════════════════════════════════════════════════════════
          //  النمط 1: أزرار مخصصة لكل قسم تم تنزيل كتب منه (المطلوب أساساً)
          // ════════════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              'أقسام الكتب المنزلة (${grouped.keys.length})',
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...grouped.entries.map((entry) {
            final sectionName = entry.key;
            final sectionBooks = entry.value;
            final sectionMb = sectionBooks.fold<double>(
              0.0,
              (acc, b) => acc + b.fileSizeMb,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DownloadedSectionCard(
                sectionName: sectionName,
                bookCount: sectionBooks.length,
                totalMb: sectionMb,
                icon: getSectionIcon(sectionName),
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DownloadedSectionBooksScreen(
                        sectionName: sectionName,
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ] else ...[
          // ════════════════════════════════════════════════════════════════════
          //  النمط 2: جميع الكتب مع شريط فاصل مخصص ومميز لكل قسم
          // ════════════════════════════════════════════════════════════════════
          ...grouped.entries.expand((entry) {
            final sectionName = entry.key;
            final sectionBooks = entry.value;
            final sectionMb = sectionBooks.fold<double>(
              0.0,
              (acc, b) => acc + b.fileSizeMb,
            );

            return [
              // ── شريط فاصل بين أقسام الكتب ──
              _SectionDividerBar(
                sectionName: sectionName,
                bookCount: sectionBooks.length,
                totalMb: sectionMb,
                icon: getSectionIcon(sectionName),
                isDark: isDark,
                onOpenSection: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DownloadedSectionBooksScreen(
                        sectionName: sectionName,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              ...sectionBooks.map(
                (book) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DownloadedBookCard(
                    db: book,
                    isDark: isDark,
                    onDelete: () => _confirmDeleteBook(context, provider, book),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ];
          }),
        ],
        const SizedBox(height: 16),
        const BannerAdWidget(),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(
                  alpha: isDark ? 0.2 : 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_for_offline_rounded,
                size: 54,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'لا توجد كتب محفوظة حالياً',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'عند تنزيل أي كتاب من مراحل التطبيق، سيتم إنشاء زر وصفحة مخصصة لقسمه تلقائياً هنا لتقرأه في أي وقت دون إنترنت.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBook(
    BuildContext context,
    DownloadsProvider provider,
    DownloadedBook db,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'تأكيد الحذف',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد حذف كتاب "${db.title}" نهائياً من التنزيلات؟',
          style: GoogleFonts.cairo(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeDownload(db.uniqueKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الكتاب بنجاح', style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  بطاقة / زر القسم المخصص (يُنشأ تلقائياً عند تنزيل كتاب من القسم)
// ─────────────────────────────────────────────────────────────────────────────

class _DownloadedSectionCard extends StatelessWidget {
  final String sectionName;
  final int bookCount;
  final double totalMb;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _DownloadedSectionCard({
    required this.sectionName,
    required this.bookCount,
    required this.totalMb,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(
              alpha: isDark ? 0.15 : 0.08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // أيقونة القسم
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),

                // بيانات القسم
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionName,
                        style: GoogleFonts.cairo(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$bookCount ${bookCount == 1 ? "كتاب منزّل" : "كتب منزّلة"}',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${totalMb.toStringAsFixed(1)} MB',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // زر الانتقال
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(
                      alpha: isDark ? 0.2 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'فتح',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 13,
                        color: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  شريط فاصل مميز بين أقسام الكتب
// ─────────────────────────────────────────────────────────────────────────────

class _SectionDividerBar extends StatelessWidget {
  final String sectionName;
  final int bookCount;
  final double totalMb;
  final IconData icon;
  final bool isDark;
  final VoidCallback onOpenSection;

  const _SectionDividerBar({
    required this.sectionName,
    required this.bookCount,
    required this.totalMb,
    required this.icon,
    required this.isDark,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(
          alpha: isDark ? 0.2 : 0.08,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(
            alpha: isDark ? 0.35 : 0.2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionName,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '$bookCount ${bookCount == 1 ? "كتاب" : "كتب"} • ${totalMb.toStringAsFixed(1)} MB',
                  style: GoogleFonts.cairo(
                    fontSize: 10.5,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onOpenSection,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'صفحة القسم',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  بطاقة الكتاب المنزّل
// ─────────────────────────────────────────────────────────────────────────────

class _DownloadedBookCard extends StatelessWidget {
  final DownloadedBook db;
  final bool isDark;
  final VoidCallback onDelete;

  const _DownloadedBookCard({
    required this.db,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  pdfUrl: '',
                  title: db.title,
                  localPath: db.localPath,
                  stageName: db.section,
                  sectionName: db.category,
                  book: Book(
                    id: db.id,
                    title: db.title,
                    section: db.section,
                    grade: db.grade,
                    category: db.category,
                    subject: db.subject,
                    url: '',
                    coverUrl: db.thumbnailUrl ?? '',
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // صورة الغلاف أو الأيقونة
                Container(
                  width: 50,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: db.thumbnailUrl != null && db.thumbnailUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: db.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppTheme.primaryColor,
                              size: 26,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppTheme.primaryColor,
                          size: 26,
                        ),
                ),
                const SizedBox(width: 14),

                // تفاصيل الكتاب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        db.title,
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (db.grade.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                db.grade,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${db.fileSizeMb.toStringAsFixed(1)} MB',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // زر المشاركة
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 19,
                    color: Colors.grey,
                  ),
                  tooltip: 'مشاركة',
                  onPressed: () {
                    Share.share(
                      '📚 كتاب: ${db.title}\nالمرحلة: ${db.section}\nالصف: ${db.grade}\n\nمتوفر في تطبيق مراجعي للدراسة والامتحانات.',
                      subject: db.title,
                    );
                  },
                ),

                // زر الحذف
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 21,
                  ),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  أدوات مساعدة صغيرة
// ─────────────────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.secondaryColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSwitchButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _ModeSwitchButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
