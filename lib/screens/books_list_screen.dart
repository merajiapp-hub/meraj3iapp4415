import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/books_data.dart';
import '../models/book.dart';
import '../widgets/book_card.dart';

class BooksListScreen extends StatefulWidget {
  final String stageTitle;
  final String section;
  final String categoryFilter;
  final Gradient gradient;

  const BooksListScreen({
    super.key,
    required this.stageTitle,
    required this.section,
    required this.categoryFilter,
    required this.gradient,
  });

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  // تتبع أي مستوى مفتوح
  final Set<int> _expandedIndices = {};

  List<Book> _getBooks() {
    return BooksData.allBooks.where((b) {
      if (b.section != widget.section) return false;
      if (widget.categoryFilter == 'الدروس' ||
          widget.categoryFilter == 'التمارين') {
        return b.category.contains('التمارين') ||
            b.category.contains('الدروس');
      }
      return b.category.contains(widget.categoryFilter);
    }).toList();
  }

  List<String> _getGrades(List<Book> books) {
    final grades = books.map((b) => b.grade).toSet().toList();
    grades.sort((a, b) {
      int getVal(String s) {
        if (s.contains('الأولى')) return 1;
        if (s.contains('الثانية')) return 2;
        if (s.contains('الثالثة')) return 3;
        if (s.contains('الرابعة')) return 4;
        if (s.contains('الخامسة')) return 5;
        if (s.contains('السادسة')) return 6;
        if (s.contains('السابعة')) return 7;
        return 99;
      }
      return getVal(a).compareTo(getVal(b));
    });
    return grades;
  }

  /// أيقونة المستوى الدراسي
  IconData _gradeIcon(String grade) {
    if (grade.contains('الأولى')) return Icons.looks_one_rounded;
    if (grade.contains('الثانية')) return Icons.looks_two_rounded;
    if (grade.contains('الثالثة')) return Icons.looks_3_rounded;
    if (grade.contains('الرابعة')) return Icons.looks_4_rounded;
    if (grade.contains('الخامسة')) return Icons.looks_5_rounded;
    if (grade.contains('السادسة')) return Icons.looks_6_rounded;
    return Icons.layers_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final books = _getBooks();
    final grades = _getGrades(books);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = (widget.gradient as LinearGradient).colors.first;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── AppBar مع تدرج ──
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(right: 16, left: 60, bottom: 14),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.categoryFilter,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: screenWidth < 360 ? 13 : 15,
                    ),
                  ),
                  Text(
                    widget.stageTitle,
                    style: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(gradient: widget.gradient),
                child: Stack(
                  children: [
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      top: 40,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.categoryFilter == 'الكتب المدرسية'
                              ? Icons.menu_book_rounded
                              : Icons.play_lesson_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── المحتوى ──
          if (books.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 48,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد محتوى في هذا القسم',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final grade = grades[index];
                    final gradeBooks =
                        books.where((b) => b.grade == grade).toList();
                    final isExpanded = _expandedIndices.contains(index);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isExpanded
                              ? accentColor.withValues(alpha: 0.3)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : const Color(0xFFE2E8F0)),
                          width: isExpanded ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isExpanded
                                ? accentColor.withValues(alpha: 0.10)
                                : Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04),
                            blurRadius: isExpanded ? 14 : 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              if (expanded) {
                                _expandedIndices.add(index);
                              } else {
                                _expandedIndices.remove(index);
                              }
                            });
                          },
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),

                          // رمز المستوى الدراسي
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: isExpanded
                                  ? widget.gradient
                                  : LinearGradient(
                                      colors: [
                                        accentColor.withValues(alpha: 0.15),
                                        accentColor.withValues(alpha: 0.25),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _gradeIcon(grade),
                              color: isExpanded
                                  ? Colors.white
                                  : accentColor,
                              size: 22,
                            ),
                          ),

                          title: Text(
                            grade,
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),

                          subtitle: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 1),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(
                                      alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${gradeBooks.length} عنصر',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          iconColor: accentColor,
                          collapsedIconColor: isDark
                              ? Colors.grey[400]
                              : Colors.grey[500],

                          childrenPadding: const EdgeInsets.only(bottom: 8),
                          children: gradeBooks
                              .map((book) => BookCard(
                                    book: book,
                                    gradient: widget.gradient,
                                    isDark: isDark,
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                  childCount: grades.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
