import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import 'pdf_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class AddedBooksScreen extends StatefulWidget {
  const AddedBooksScreen({super.key});

  @override
  State<AddedBooksScreen> createState() => _AddedBooksScreenState();
}

class _AddedBooksScreenState extends State<AddedBooksScreen> {
  String _filterSection = '';
  String _filterSubject = '';
  String _filterGrade = '';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'الكتب المضافة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(isDark),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('uploaded_books')
            .orderBy('uploadDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر تحميل الكتب',
                style: GoogleFonts.tajawal(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty(isDark);
          }

          final docs = snapshot.data!.docs;
          var books = docs.map((d) => Book.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

          // تطبيق الفلاتر
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            books = books.where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.subject.toLowerCase().contains(q) ||
              b.section.toLowerCase().contains(q)
            ).toList();
          }
          if (_filterSection.isNotEmpty) {
            books = books.where((b) => b.section == _filterSection).toList();
          }
          if (_filterSubject.isNotEmpty) {
            books = books.where((b) => b.subject == _filterSubject).toList();
          }
          if (_filterGrade.isNotEmpty) {
            books = books.where((b) => b.grade == _filterGrade).toList();
          }

          // جمع الفلاتر المتاحة
          final sections = docs.map((d) => (d.data() as Map<String, dynamic>)['section'] as String? ?? '').where((s) => s.isNotEmpty).toSet().toList();
          final subjects = docs.map((d) => (d.data() as Map<String, dynamic>)['subject'] as String? ?? '').where((s) => s.isNotEmpty).toSet().toList();
          final grades = docs.map((d) => (d.data() as Map<String, dynamic>)['grade'] as String? ?? '').where((s) => s.isNotEmpty).toSet().toList();

          return Column(
            children: [
              // شريط الفلاتر
              if (sections.isNotEmpty || subjects.isNotEmpty)
                _buildFilterBar(sections, subjects, grades, isDark),
              // عداد الكتب
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${books.length} كتاب',
                      style: GoogleFonts.tajawal(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_filterSection.isNotEmpty || _filterSubject.isNotEmpty || _filterGrade.isNotEmpty || _searchQuery.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _filterSection = '';
                          _filterSubject = '';
                          _filterGrade = '';
                          _searchQuery = '';
                          _searchCtrl.clear();
                        }),
                        icon: const Icon(Icons.clear, size: 16),
                        label: Text('مسح الفلاتر', style: GoogleFonts.tajawal(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: books.isEmpty
                    ? Center(
                        child: Text('لا توجد كتب مطابقة', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          return _buildBookCard(context, books[index], docs[index], isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v.trim()),
      decoration: InputDecoration(
        hintText: 'ابحث عن كتاب...',
        hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]),
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppTheme.primaryColor.withValues(alpha: 0.15),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      style: GoogleFonts.tajawal(),
    );
  }

  Widget _buildFilterBar(List<String> sections, List<String> subjects, List<String> grades, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('المرحلة', _filterSection, sections, isDark, (v) => setState(() => _filterSection = v)),
          const SizedBox(width: 8),
          _buildFilterChip('المادة', _filterSubject, subjects, isDark, (v) => setState(() => _filterSubject = v)),
          const SizedBox(width: 8),
          _buildFilterChip('السنة', _filterGrade, grades, isDark, (v) => setState(() => _filterGrade = v)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options, bool isDark, Function(String) onSelect) {
    return PopupMenuButton<String>(
      onSelected: (v) => onSelect(v == selected ? '' : v),
      itemBuilder: (_) => [
        PopupMenuItem(value: '', child: Text('الكل', style: GoogleFonts.tajawal())),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o, style: GoogleFonts.tajawal()))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected.isNotEmpty
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected.isNotEmpty ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.isNotEmpty ? selected : label,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: selected.isNotEmpty ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: selected.isNotEmpty ? Colors.white : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'لا توجد كتب مضافة حالياً',
            style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك رفع الكتب من زر + في الصفحة الرئيسية',
            style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book, QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final uploadDate = data['uploadDate'] != null
        ? (data['uploadDate'] as Timestamp).toDate()
        : null;
    final dateStr = uploadDate != null ? DateFormat('yyyy/MM/dd').format(uploadDate) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: book.url,
              title: book.title,
              stageName: book.section,
              sectionName: book.category,
              book: book,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة الغلاف
              _buildCoverImage(book, isDark),
              const SizedBox(width: 14),
              // معلومات الكتاب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم الكتاب
                    Text(
                      book.title,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // الشارات التفصيلية
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (book.section.isNotEmpty) _buildInfoBadge(book.section, Icons.school_rounded, Colors.blue),
                        if (book.grade.isNotEmpty) _buildInfoBadge(book.grade, Icons.grade_rounded, Colors.orange),
                        if (book.subject.isNotEmpty) _buildInfoBadge(book.subject, Icons.subject_rounded, AppTheme.primaryColor),
                        if (book.category.isNotEmpty) _buildInfoBadge(book.category, Icons.category_rounded, Colors.purple),
                      ],
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'تاريخ الإضافة: $dateStr',
                            style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    // أزرار الإجراءات
                    _buildActionButtons(context, book, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(Book book, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        height: 95,
        child: book.coverUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: book.coverUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => _buildDefaultCover(isDark),
              )
            : _buildDefaultCover(isDark),
      ),
    );
  }

  Widget _buildDefaultCover(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildInfoBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Book book, bool isDark) {
    return Row(
      children: [
        // زر فتح
        Expanded(
          child: SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    pdfUrl: book.url,
                    title: book.title,
                    stageName: book.section,
                    sectionName: book.category,
                    book: book,
                  ),
                ),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: Text('فتح', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // زر تنزيل
        Consumer<DownloadsProvider>(
          builder: (context, downloads, _) {
            final isDownloaded = downloads.isDownloaded(book.uniqueKey);
            return SizedBox(
              width: 34,
              height: 34,
              child: IconButton.filled(
                padding: EdgeInsets.zero,
                onPressed: isDownloaded
                    ? () => AppNotification.show(context, 'تم تنزيل هذا الكتاب مسبقاً')
                    : () => _downloadBook(context, book, downloads),
                icon: Icon(
                  isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isDownloaded
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.blue.withValues(alpha: 0.1),
                  foregroundColor: isDownloaded ? Colors.green : Colors.blue,
                ),
                tooltip: isDownloaded ? 'تم التنزيل' : 'تنزيل',
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        // زر مفضلة
        Consumer<FavoritesProvider>(
          builder: (context, favorites, _) {
            final isFav = favorites.isFavorite(book.uniqueKey);
            return SizedBox(
              width: 34,
              height: 34,
              child: IconButton.filled(
                padding: EdgeInsets.zero,
                onPressed: () => favorites.toggleFavorite(context, book),
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isFav
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  foregroundColor: isFav ? Colors.red : Colors.grey,
                ),
                tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _downloadBook(BuildContext context, Book book, DownloadsProvider downloads) async {
    if (book.url.isEmpty) {
      AppNotification.show(context, 'الرابط غير متوفر', isError: true);
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${book.uniqueKey}.pdf';
      final savePath = '${dir.path}/$fileName';

      String processedUrl = book.url;
      if (book.url.contains('drive.google.com/file/d/')) {
        final id = book.url.split('/d/')[1].split('/')[0].split('?')[0];
        processedUrl = 'https://docs.google.com/uc?export=download&id=$id';
      }

      await Dio().download(processedUrl, savePath);
      final file = File(savePath);
      if (await file.exists()) {
        final sizeMb = (await file.length()) / (1024 * 1024);
        await downloads.addDownload(DownloadedBook.fromBook(book, savePath, sizeMb));
        if (context.mounted) AppNotification.show(context, '✅ تم تنزيل "${book.title}" بنجاح');
      }
    } catch (e) {
      if (context.mounted) AppNotification.show(context, 'فشل التنزيل، تحقق من الاتصال', isError: true);
    }
  }
}
