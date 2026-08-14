import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/books_data.dart';
import '../models/book.dart';
import 'pdf_viewer_screen.dart';

class SweddScreen extends StatelessWidget {
  const SweddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sweddBooks = BooksData.allBooks
        .where((b) => b.section == BooksData.sSwedd)
        .toList();

    // Grouping by Grade (Year) -> Category
    final Map<String, Map<String, List<Book>>> grouped = {};
    for (final book in sweddBooks) {
      grouped.putIfAbsent(book.grade, () => {});
      grouped[book.grade]!.putIfAbsent(book.category, () => []).add(book);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مشروع SWEDD',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: sweddBooks.isEmpty
          ? _buildEmptyState(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تمكين المرأة',
                                style: GoogleFonts.tajawal(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'دعم النساء والفتيات في التعليم',
                                style: GoogleFonts.tajawal(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content by grade
                  ...grouped.entries.map((gradeEntry) {
                    final gradeName = _getFormattedGrade(gradeEntry.key);
                    final categoriesMap = gradeEntry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEC4899,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFEC4899,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  gradeName,
                                  style: GoogleFonts.tajawal(
                                    color: const Color(0xFFEC4899),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...categoriesMap.entries.map((categoryEntry) {
                          final categoryName = categoryEntry.key;
                          final books = categoryEntry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: ExpansionTile(
                              iconColor: const Color(0xFFEC4899),
                              title: Text(
                                categoryName,
                                style: GoogleFonts.tajawal(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              children: books.map((book) {
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).dividerColor.withValues(alpha: 0.1),
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEC4899,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.health_and_safety,
                                        color: Color(0xFFEC4899),
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      book.title,
                                      style: GoogleFonts.tajawal(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEC4899,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'عرض الكتاب',
                                        style: GoogleFonts.tajawal(
                                          color: const Color(0xFFEC4899),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfViewerScreen(
                                            pdfUrl: book.url,
                                            title: book.title,
                                            stageName: 'SWEDD',
                                            sectionName: book.category,
                                            book: book,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  String _getFormattedGrade(String grade) {
    switch (grade) {
      case 'الكل':
        return 'دليل عام للجميع';
      case '2':
        return 'السنة الثانية إعدادية';
      case '3':
        return 'السنة الثالثة إعدادية';
      case '4':
        return 'السنة الرابعة إعدادية';
      case '5':
        return 'السنة الخامسة ثانوية';
      case '6':
        return 'السنة السادسة ثانوية';
      case '7':
        return 'السنة السابعة ثانوية (الباكالوريا)';
      default:
        return grade;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            size: 80,
            color: Color(0xFFEC4899),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد محتويات حالياً لمشروع SWEDD',
            style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
