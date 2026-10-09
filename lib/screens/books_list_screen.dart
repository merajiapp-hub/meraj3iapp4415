import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book.dart';
import '../services/content_service.dart';
import '../widgets/book_card.dart';
import '../widgets/geometric_sliver_app_bar.dart';

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
  final Set<int> _expandedIndices = {};

  List<Book>? _books;
  List<String> _grades = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<List<Book>>? _sub;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant BooksListScreen old) {
    super.didUpdateWidget(old);
    if (old.section != widget.section ||
        old.categoryFilter != widget.categoryFilter) {
      _sub?.cancel();
      _subscribe();
    }
  }

  void _subscribe() {
    setState(() {
      _loading = true;
      _error = null;
    });

    final category =
        widget.categoryFilter == 'الدروس' || widget.categoryFilter == 'التمارين'
        ? null
        : widget.categoryFilter;

    _sub =
        ContentService.watchBooksBySection(
          widget.section,
          category: category,
        ).listen(
          (books) {
            if (!mounted) return;
            // فلترة إضافية للدروس/التمارين
            List<Book> filtered = books;
            if (widget.categoryFilter == 'الدروس' ||
                widget.categoryFilter == 'التمارين') {
              filtered = books
                  .where(
                    (b) =>
                        b.category.contains('التمارين') ||
                        b.category.contains('الدروس'),
                  )
                  .toList();
            }
            setState(() {
              _books = filtered;
              _grades = _computeGrades(filtered);
              _loading = false;
            });
          },
          onError: (e) {
            if (!mounted) return;
            debugPrint('Books stream error: $e');
            setState(() {
              _books = [];
              _grades = [];
              _loading = false;
              _error =
                  'تعذّر تحميل الكتب من الخادم. تحقق من الاتصال وحاول مجددًا.';
            });
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<String> _computeGrades(List<Book> books) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = (widget.gradient as LinearGradient).colors.first;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          GeometricSliverAppBar(
            title: widget.categoryFilter,
            subtitle: widget.stageTitle,
            icon: widget.categoryFilter == 'الكتب المدرسية'
                ? Icons.menu_book_rounded
                : Icons.play_lesson_rounded,
            gradient: widget.gradient,
          ),

          if (_loading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _sub?.cancel();
                        _subscribe();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            )
          else if (_books == null || _books!.isEmpty)
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
                    const SizedBox(height: 8),
                    Text(
                      'سيتم إضافة المحتوى قريباً',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: Colors.grey[400],
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final grade = _grades[index];
                  final gradeBooks = _books!
                      .where((b) => b.grade == grade)
                      .toList();
                  final isExpanded = _expandedIndices.contains(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                                  alpha: isDark ? 0.2 : 0.04,
                                ),
                          blurRadius: isExpanded ? 14 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
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
                        leading: SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            _gradeIcon(grade),
                            color: isDark
                                ? Colors.white
                                : (isExpanded ? Colors.white : accentColor),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          grade,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
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
                            .map(
                              (book) => BookCard(
                                book: book,
                                gradient: widget.gradient,
                                isDark: isDark,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  );
                }, childCount: _grades.length),
              ),
            ),
        ],
      ),
    );
  }
}
