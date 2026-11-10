import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/downloads_provider.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import 'pdf_viewer_screen.dart';

/// صفحة مخصصة ومستقلة لكتب قسم معين تم تنزيلها
class DownloadedSectionBooksScreen extends StatefulWidget {
  final String sectionName;

  const DownloadedSectionBooksScreen({
    super.key,
    required this.sectionName,
  });

  @override
  State<DownloadedSectionBooksScreen> createState() =>
      _DownloadedSectionBooksScreenState();
}

class _DownloadedSectionBooksScreenState
    extends State<DownloadedSectionBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static int getEducationalOrder(String text) {
    final s = text.toLowerCase().trim();
    int stageScore = 0;
    if (s.contains('ابتدائ')) {
      stageScore = 1000;
    } else if (s.contains('إعداد') || s.contains('اعداد')) {
      stageScore = 2000;
    } else if (s.contains('ثانوي')) {
      stageScore = 3000;
    } else if (s.contains('امتحان') ||
        s.contains('concours') ||
        s.contains('brevet') ||
        s.contains('bac')) {
      stageScore = 4000;
    } else if (s.contains('swedd')) {
      stageScore = 5000;
    } else {
      stageScore = 6000;
    }

    int gradeScore = 0;
    if (s.contains('أول') || s.contains('الاول') || s.contains('الأول') || s.contains('1')) {
      gradeScore = 1;
    } else if (s.contains('ثان') || s.contains('الثاني') || s.contains('2')) {
      gradeScore = 2;
    } else if (s.contains('ثالث') || s.contains('الثالث') || s.contains('3')) {
      gradeScore = 3;
    } else if (s.contains('رابع') || s.contains('الرابع') || s.contains('4')) {
      gradeScore = 4;
    } else if (s.contains('خامس') || s.contains('الخامس') || s.contains('5')) {
      gradeScore = 5;
    } else if (s.contains('سادس') || s.contains('السادس') || s.contains('6')) {
      gradeScore = 6;
    } else if (s.contains('سابع') || s.contains('السابع') || s.contains('7')) {
      gradeScore = 7;
    } else if (s.contains('ثامن') || s.contains('الثامن') || s.contains('8')) {
      gradeScore = 8;
    } else if (s.contains('تاسع') || s.contains('التاسع') || s.contains('9')) {
      gradeScore = 9;
    } else if (s.contains('باك') || s.contains('bac')) {
      gradeScore = 10;
    }

    return stageScore + gradeScore;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DownloadsProvider>();

    final sectionBooks = provider.downloads.where((b) {
      return getSectionName(b) == widget.sectionName;
    }).toList();

    final totalSizeMb = sectionBooks.fold<double>(
      0.0,
      (acc, b) => acc + b.fileSizeMb,
    );

    final filteredBooks = sectionBooks.where((b) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return b.title.toLowerCase().contains(q) ||
          b.grade.toLowerCase().contains(q) ||
          b.subject.toLowerCase().contains(q);
    }).toList();

    // تجميع وترتيب الكتب حسب المرحلة/السنة الدراسية (من الأصغر إلى الأكبر)
    final Map<String, List<DownloadedBook>> booksByGrade = {};
    for (final book in filteredBooks) {
      final grade = book.grade.trim().isNotEmpty ? book.grade.trim() : 'كتب عامة';
      booksByGrade.putIfAbsent(grade, () => []).add(book);
    }

    final sortedGrades = booksByGrade.keys.toList()
      ..sort((a, b) {
        final orderA = getEducationalOrder(a);
        final orderB = getEducationalOrder(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.compareTo(b);
      });

    for (final list in booksByGrade.values) {
      list.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          CurvedHeader(
            title: widget.sectionName,
            subtitle: sectionBooks.isNotEmpty
                ? '${sectionBooks.length} ${sectionBooks.length == 1 ? "كتاب محفوظ" : "كتب محفوظة"} • ${totalSizeMb.toStringAsFixed(1)} MB'
                : 'لا توجد كتب في هذا القسم',
            gradient: isDark
                ? AppTheme.deepBlueGradient
                : AppTheme.primaryGradient,
            showBackButton: true,
            trailing: sectionBooks.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'حذف جميع كتب هذا القسم',
                    onPressed: () => _confirmDeleteAll(provider, sectionBooks),
                  )
                : null,
          ),
          Expanded(
            child: sectionBooks.isEmpty
                ? _buildEmptySection(isDark)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      // حقل البحث إذا كان هناك أكثر من كتاب
                      if (sectionBooks.length > 2) ...[
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
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.04,
                                ),
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
                              hintText: 'ابحث في كتب ${widget.sectionName}...',
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
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        size: 18,
                                      ),
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
                      ],

                      // قائمة الكتب
                      if (filteredBooks.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 56,
                                  color: isDark ? Colors.white24 : Colors.black26,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد كتب تطابق بحثك',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        ...sortedGrades.expand((grade) {
                          final gradeBooks = booksByGrade[grade]!;
                          final gradeMb = gradeBooks.fold<double>(
                            0.0,
                            (acc, b) => acc + b.fileSizeMb,
                          );

                          return [
                            _GradeDividerBar(
                              gradeName: grade,
                              bookCount: gradeBooks.length,
                              totalMb: gradeMb,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            ...gradeBooks.map(
                              (book) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SectionDownloadedBookCard(
                                  db: book,
                                  isDark: isDark,
                                  onDelete: () =>
                                      _confirmDeleteBook(provider, book),
                                  onShare: () => _shareBook(book),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ];
                        }),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تم حذف جميع كتب هذا القسم',
              style: GoogleFonts.cairo(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لقد قمت بحذف كل الكتب المنزلة لهذا القسم. سيختفي زر هذا القسم تلقائياً من صفحة التنزيلات.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              label: Text(
                'العودة إلى التنزيلات',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareBook(DownloadedBook db) {
    SharePlus.instance.share(
      ShareParams(
        text:
            '📚 كتاب: ${db.title}\nالمرحلة: ${db.section}\nالصف: ${db.grade}\n\nمتوفر في تطبيق مراجعي للدراسة والامتحانات.',
        subject: db.title,
      ),
    );
  }

  Future<void> _confirmDeleteBook(
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
          'هل تريد حذف كتاب "${db.title}" نهائياً من الذاكرة المحلية؟',
          style: GoogleFonts.cairo(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف الكتاب بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAll(
    DownloadsProvider provider,
    List<DownloadedBook> books,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'حذف جميع كتب القسم',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف جميع الكتب المنزلة (${books.length} كتاب) في قسم "${widget.sectionName}"؟',
          style: GoogleFonts.cairo(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
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
              'حذف الكل',
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
      for (final b in books) {
        await provider.removeDownload(b.uniqueKey);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم حذف جميع كتب هذا القسم بنجاح',
            style: GoogleFonts.cairo(),
          ),
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

class _GradeDividerBar extends StatelessWidget {
  final String gradeName;
  final int bookCount;
  final double totalMb;
  final bool isDark;

  const _GradeDividerBar({
    required this.gradeName,
    required this.bookCount,
    required this.totalMb,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gradeName,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$bookCount كتب • ${totalMb.toStringAsFixed(1)} MB',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة الكتاب داخل صفحة القسم المخصصة
class _SectionDownloadedBookCard extends StatelessWidget {
  final DownloadedBook db;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _SectionDownloadedBookCard({
    required this.db,
    required this.isDark,
    required this.onDelete,
    required this.onShare,
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
                // غلاف / أيقونة الكتاب
                Container(
                  width: 52,
                  height: 60,
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
                            errorWidget: (_, _, _) => const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppTheme.primaryColor,
                          size: 28,
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
                                  alpha: 0.09,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                db.grade,
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
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

                // أزرار الإجراءات (مشاركة وحذف)
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                  tooltip: 'مشاركة',
                  onPressed: onShare,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 21,
                    color: Colors.redAccent,
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
