import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../models/book.dart';
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
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Book>> categorizedBooks = {};
    for (var b in widget.books) {
      if (!categorizedBooks.containsKey(b.category)) {
        categorizedBooks[b.category] = [];
      }
      categorizedBooks[b.category]!.add(b);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          widget.stage,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: categorizedBooks.isEmpty
          ? Center(
              child: Text(
                'لا توجد كتب مضافة بعد.',
                style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: categorizedBooks.length,
              itemBuilder: (context, index) {
                String category = categorizedBooks.keys.elementAt(index);
                List<Book> categoryBooks = categorizedBooks[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            category,
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 4, // Show 4 skeleton items
                              itemBuilder: (context, index) =>
                                  _buildSkeletonItem(),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categoryBooks.length,
                              itemBuilder: (context, bIndex) {
                                final book = categoryBooks[bIndex];
                                return Card(
                                  margin: const EdgeInsets.only(
                                    left: 16.0,
                                    bottom: 8.0,
                                  ),
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfViewerScreen(
                                            pdfUrl: book.url,
                                            title: book.title,
                                            book: book,
                                          ),
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 150,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.05),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      top: Radius.circular(16),
                                                    ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.menu_book_rounded,
                                                  size: 48,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              book.title,
                                              style: GoogleFonts.tajawal(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSkeletonItem() {
    return Card(
      margin: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 150,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Container(height: 12, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 12, width: 80, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
