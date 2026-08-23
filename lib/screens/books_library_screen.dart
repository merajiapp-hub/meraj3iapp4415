import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';


import '../models/book.dart';
import '../services/drive_url_service.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class BooksLibraryScreen extends StatefulWidget {
  final String stage;
  final List<Book> books;

  const BooksLibraryScreen({
    super.key,
    required this.stage,
    required this.books,
  });

  @override
  State<BooksLibraryScreen> createState() => _BooksLibraryScreenState();
}

class _BooksLibraryScreenState extends State<BooksLibraryScreen> {
  String _searchQuery = '';
  String _selectedCategory = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Book> get _filteredBooks {
    return widget.books.where((b) {
      final matchSearch = _searchQuery.isEmpty ||
          b.title.contains(_searchQuery) ||
          b.category.contains(_searchQuery) ||
          b.subject.contains(_searchQuery);
      final matchCategory =
          _selectedCategory.isEmpty || b.category == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  List<String> get _categories {
    final cats = widget.books.map((b) => b.category).toSet().toList();
    cats.sort();
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredBooks = _filteredBooks;

    // Group books by category
    final Map<String, List<Book>> categorizedBooks = {};
    for (final b in filteredBooks) {
      categorizedBooks.putIfAbsent(b.category, () => []).add(b);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.stage,
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : AppTheme.primaryColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'ابحث في الكتب...',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.tajawal(),
                  textDirection: TextDirection.rtl,
                ),
              ),
              // Category Filter Chips
              if (_categories.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildChip('الكل', '', isDark),
                      ..._categories.map((c) => _buildChip(c, c, isDark)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: filteredBooks.isEmpty
          ? _buildEmpty(isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categorizedBooks.length,
              itemBuilder: (context, index) {
                final category = categorizedBooks.keys.elementAt(index);
                final books = categorizedBooks[category]!;
                return _buildCategorySection(category, books, isDark);
              },
            ),
    );
  }

  Widget _buildChip(String label, String value, bool isDark) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.white24 : Colors.grey[300]!),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Book> books, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                category,
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${books.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Books Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 400 ? 3 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) => _buildBookCard(books[index], isDark),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBookCard(Book book, bool isDark) {
    final thumbnailUrl = book.thumbnailUrl;
    final hasValidLink = book.hasValidLink;
    final linkStatus = book.resolvedLinkStatus;

    return GestureDetector(
      onTap: () {
        if (!hasValidLink) {
          _showLinkIssueDialog(book);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: book.normalizedUrl,
              title: book.title,
              book: book,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl != null)
                      CachedNetworkImage(
                        imageUrl: thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildThumbnailPlaceholder(book, isDark),
                        errorWidget: (context, url, error) => _buildThumbnailPlaceholder(book, isDark),
                      )
                    else
                      _buildThumbnailPlaceholder(book, isDark),
                    // Status Badge (if link has issues)
                    if (linkStatus == DriveUrlService.statusUnknownFormat ||
                        linkStatus == DriveUrlService.statusEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'يحتاج مراجعة',
                                style: GoogleFonts.tajawal(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Tap overlay
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          onTap: () {
                            if (!hasValidLink) {
                              _showLinkIssueDialog(book);
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  pdfUrl: book.normalizedUrl,
                                  title: book.title,
                                  book: book,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Book Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.3,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    if (book.subject.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(Book book, bool isDark) {
    return Container(
      color: isDark
          ? AppTheme.primaryColor.withValues(alpha: 0.08)
          : AppTheme.primaryColor.withValues(alpha: 0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: 52,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          if (book.subject.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                book.subject,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLinkIssueDialog(Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.link_off_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text('رابط يحتاج مراجعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'رابط هذا الكتاب يحتاج إلى مراجعة من المسؤول.\nاسم الكتاب: ${book.title}',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('حسناً', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'لا توجد نتائج للبحث' : 'لا توجد كتب مضافة بعد.',
            style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
              child: Text('مسح البحث', style: GoogleFonts.tajawal(color: AppTheme.primaryColor)),
            ),
          ],
        ],
      ),
    );
  }

}
