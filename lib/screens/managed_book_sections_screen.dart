import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/books_data.dart';
import '../data/competitions_books.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import 'pdf_viewer_screen.dart';

String _normalizeText(String? value) =>
    (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

String _bookContentKey(Book book) => [
  _normalizeText(book.section),
  _normalizeText(book.grade),
  _normalizeText(book.category),
  _normalizeText(book.title),
  _normalizeText(book.subject),
  book.url.trim(),
  book.solutionUrl.trim(),
].join('\u0000');

int _bookSortOrder(Book book) => book.order;

int competitionGroupSortOrder(String grade) {
  final key = grade.toLowerCase();
  if (key.contains('concours')) return 0;
  if (key.contains('brevet') || key.contains('ابريفة')) return 1;
  if (key.contains('bac') ||
      key.contains('baccala') ||
      key.contains('بكالوريا') ||
      key.contains('باكالوريا') ||
      (key.contains('السابعة') && key.contains('ثانوية'))) {
    return 2;
  }
  return 3;
}

int competitionSubjectSortOrder(String subject) {
  final key = _normalizeText(subject);
  if (key.contains('العربية') || key.contains('arabe')) return 0;
  if (key.contains('الفرنسية') ||
      key.contains('français') ||
      key.contains('francais')) {
    return 1;
  }
  return 2;
}

int competitionYearSort(String grade) {
  final match = RegExp(r'(\d{4})').firstMatch(grade);
  final value = match == null
      ? 9999
      : int.tryParse(match.group(1) ?? '') ?? 9999;
  return value;
}

String _competitionSolutionKey(Book book) {
  if (book.examKey.trim().isNotEmpty) return _normalizeText(book.examKey);
  final subject = book.subject.trim().isNotEmpty
      ? book.subject
      : book.title.replaceFirst(
          RegExp(
            '^${RegExp.escape(book.grade)}\\s*[-–—:]?\\s*',
            caseSensitive: false,
          ),
          '',
        );
  return '${_normalizeText(book.grade)}::${_normalizeText(subject)}';
}

bool _isSeparateSolutionBook(Book book) {
  final type = book.documentType.trim().toLowerCase();
  if (type == 'solution' || type == 'حل') return true;
  if (type == 'exam' || type == 'book' || type == 'امتحان') return false;
  final category = _normalizeText(book.category);
  return category == 'الحل' ||
      category == 'الحلول' ||
      category == 'solutions' ||
      category == 'solution';
}

List<Book> attachBundledCompetitionSolutions(Iterable<Book> books) {
  final allBooks = books.toList();
  final separateSolutions = allBooks
      .where((book) => _isSeparateSolutionBook(book))
      .toList();
  final explicitlyManagedKeys = separateSolutions
      .map(_competitionSolutionKey)
      .toSet();
  final explicitSolutions = <String, String>{
    for (final solution in separateSolutions)
      if (solution.isActive && solution.url.trim().isNotEmpty)
        _competitionSolutionKey(solution): solution.url,
  };
  final bundledSolutions = <String, String>{
    for (final book in CompetitionsBooks.books)
      if (book.solutionUrl.trim().isNotEmpty)
        _competitionSolutionKey(book): book.solutionUrl,
  };

  return allBooks.where((book) => !_isSeparateSolutionBook(book)).map((book) {
    if (book.section != BooksData.sCompetitions) {
      return book;
    }
    if (book.solutionUrl.trim().isNotEmpty) return book;

    final key = _competitionSolutionKey(book);
    final solutionUrl =
        explicitSolutions[key] ??
        (explicitlyManagedKeys.contains(key) ? null : bundledSolutions[key]);
    return solutionUrl == null ? book : book.copyWith(solutionUrl: solutionUrl);
  }).toList();
}

List<Book> filterManagedBooks({
  required Iterable<Book> books,
  required String section,
  String? grade,
  String? category,
}) {
  final normalizedSection = _normalizeText(section);
  final normalizedGrade = grade == null ? null : _normalizeText(grade);
  final normalizedCategory = category == null ? null : _normalizeText(category);

  final uniqueBooks = <String, Book>{};
  for (final book in books) {
    if (_normalizeText(book.section) != normalizedSection ||
        !book.isActive ||
        _isSeparateSolutionBook(book) ||
        (normalizedGrade != null &&
            _normalizeText(book.grade) != normalizedGrade) ||
        (normalizedCategory != null &&
            _normalizeText(book.category) != normalizedCategory)) {
      continue;
    }
    uniqueBooks.putIfAbsent(_bookContentKey(book), () => book);
  }

  final result = uniqueBooks.values.toList()
    ..sort((a, b) {
      final order = _bookSortOrder(a).compareTo(_bookSortOrder(b));
      if (order != 0) return order;
      final gradeOrder = _normalizeText(
        a.grade,
      ).compareTo(_normalizeText(b.grade));
      if (gradeOrder != 0) return gradeOrder;
      final categoryOrder = _normalizeText(
        a.category,
      ).compareTo(_normalizeText(b.category));
      if (categoryOrder != 0) return categoryOrder;
      return _normalizeText(a.title).compareTo(_normalizeText(b.title));
    });
  return result;
}

List<ManagedBookSection> groupManagedBooks(Iterable<Book> books) {
  final grouped = <String, ManagedBookSection>{};
  for (final book in books) {
    final key =
        '${_normalizeText(book.grade)}\u0000${_normalizeText(book.category)}';
    grouped.putIfAbsent(
      key,
      () => ManagedBookSection(grade: book.grade, category: book.category),
    );
    grouped[key]!.books.putIfAbsent(_bookContentKey(book), () => book);
  }

  final sections = grouped.values.toList()
    ..sort((a, b) {
      final leftOrder = a.books.values.isEmpty ? 0 : a.books.values.first.order;
      final rightOrder = b.books.values.isEmpty
          ? 0
          : b.books.values.first.order;
      final order = leftOrder.compareTo(rightOrder);
      if (order != 0) return order;
      final gradeOrder = _normalizeText(
        a.grade,
      ).compareTo(_normalizeText(b.grade));
      if (gradeOrder != 0) return gradeOrder;
      return _normalizeText(a.category).compareTo(_normalizeText(b.category));
    });
  return sections;
}

class ManagedBookSectionsScreen extends StatefulWidget {
  final String section;
  final String title;
  final String subtitle;
  final IconData icon;
  final String stageName;
  final String Function(String) formatGrade;

  const ManagedBookSectionsScreen({
    super.key,
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.stageName,
    required this.formatGrade,
  });

  @override
  State<ManagedBookSectionsScreen> createState() =>
      _ManagedBookSectionsScreenState();
}

class _ManagedBookSectionsScreenState extends State<ManagedBookSectionsScreen> {
  late Stream<List<Book>> _booksStream;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _booksStream = _watchBooks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<Book>> _watchBooks() {
    return FirebaseFirestore.instance
        .collection('books')
        .where('section', isEqualTo: widget.section)
        .snapshots()
        .map(
          (snapshot) {
            final books = snapshot.docs.map(
              (document) => Book.fromMap(document.data(), document.id),
            );
            return filterManagedBooks(
              books: widget.section == BooksData.sCompetitions
                  ? attachBundledCompetitionSolutions(books)
                  : books,
              section: widget.section,
            );
          },
        );
  }

  List<ManagedBookSection> _applySectionSearch(
    List<ManagedBookSection> sections,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return sections;

    return sections.where((section) {
      final haystack = [
        section.grade,
        section.category,
        widget.formatGrade(section.grade),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _retry() {
    setState(() => _booksStream = _watchBooks());
  }

  void _openDirectBook(
    BuildContext context,
    Book book, {
    String? overrideUrl,
    String? overrideTitle,
  }) {
    final url = (overrideUrl ?? book.url).trim();
    if (url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(
          pdfUrl: url,
          title: overrideTitle ?? book.title,
          stageName: widget.stageName,
          sectionName: widget.section,
          book: book,
          useLatestRemoteUrl: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Book>>(
        stream: _booksStream,
        initialData: widget.section == BooksData.sCompetitions
            ? attachBundledCompetitionSolutions(
                filterManagedBooks(
                  books: CompetitionsBooks.books,
                  section: widget.section,
                ),
              )
            : null,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildError(context);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sections = _applySectionSearch(
            groupManagedBooks(snapshot.data!),
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CurvedHeader(
                  title: widget.title,
                  gradient: AppTheme.brandGradient,
                  leadingIcon: widget.icon,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن المرحلة أو المادة أو التصنيف...',
                        hintStyle: GoogleFonts.tajawal(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildIntroCard(context),
                      const SizedBox(height: 18),
                      if (_isNationalCompetitionsView)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'اختر السنة لعرض امتحاناتها ثم افتح كل امتحان من القائمة.',
                            style: GoogleFonts.tajawal(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_isNationalCompetitionsView ||
                          widget.section == BooksData.sSwedd ||
                          widget.stageName == 'SWEDD')
                        ..._buildGradeAccordionSections(context, sections)
                      else
                        ...sections.map(
                          (section) => _SectionCard(
                            title: widget.formatGrade(section.grade),
                            subtitle: section.category,
                            count: section.books.length,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _ManagedBooksListScreen(
                                  firestoreSection: widget.section,
                                  grade: section.grade,
                                  category: section.category,
                                  title: widget.formatGrade(section.grade),
                                  stageName: widget.stageName,
                                  icon: widget.icon,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.tajawal(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasSearch = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 56, color: AppTheme.primaryColor),
            const SizedBox(height: 14),
            Text(
              hasSearch
                  ? 'لا توجد نتائج مطابقة للبحث.'
                  : 'لا توجد أقسام أو كتب مفعّلة حالياً',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasSearch) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('مسح البحث'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isNationalCompetitionsView =>
      widget.section == BooksData.sCompetitions ||
      widget.stageName == 'امتحانات وطنية';

  List<Widget> _buildGradeAccordionSections(
    BuildContext context,
    List<ManagedBookSection> sections,
  ) {
    final grouped = <String, List<Book>>{};
    for (final section in sections) {
      for (final book in section.books.values) {
        grouped.putIfAbsent(section.grade, () => []).add(book);
      }
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final leftOrder = competitionGroupSortOrder(a.key);
        final rightOrder = competitionGroupSortOrder(b.key);
        if (leftOrder != rightOrder) return leftOrder.compareTo(rightOrder);
        return competitionYearSort(a.key).compareTo(competitionYearSort(b.key));
      });

    return entries.asMap().entries.expand((indexedEntry) {
      final index = indexedEntry.key;
      final entry = indexedEntry.value;
      final grade = entry.key;
      final books = entry.value.toList()
        ..sort((a, b) {
          final typeOrder = competitionGroupSortOrder(
            a.grade,
          ).compareTo(competitionGroupSortOrder(b.grade));
          if (typeOrder != 0) return typeOrder;
          final subjectPriority = competitionSubjectSortOrder(
            a.subject,
          ).compareTo(competitionSubjectSortOrder(b.subject));
          if (subjectPriority != 0) return subjectPriority;
          final subjectOrder = _normalizeText(
            a.subject,
          ).compareTo(_normalizeText(b.subject));
          if (subjectOrder != 0) return subjectOrder;
          return _normalizeText(a.title).compareTo(_normalizeText(b.title));
        });

      final accordion = Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2E4E5B),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: Colors.white,
            textColor: Colors.white,
            collapsedIconColor: Colors.white,
            title: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.formatGrade(grade),
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 26),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.file_copy_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            children: [
              ...books.map((book) {
                final hasSolution = book.solutionUrl.trim().isNotEmpty;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEEEA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          book.subject.isNotEmpty ? book.subject : book.title,
                          style: GoogleFonts.tajawal(
                            color: const Color(0xFF0F4D4A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (book.url.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _openDirectBook(context, book),
                          icon: const Icon(Icons.visibility_rounded, size: 18),
                          label: Text(
                            _isNationalCompetitionsView
                                ? 'الامتحان'
                                : 'عرض الكتاب',
                            maxLines: 1,
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _isNationalCompetitionsView
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF0D5248),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      if (hasSolution) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _openDirectBook(
                            context,
                            book,
                            overrideUrl: book.solutionUrl,
                            overrideTitle: 'حل ${book.title}',
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          label: Text(
                            'الحل',
                            maxLines: 1,
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF0F766E),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            onExpansionChanged: (_) {},
          ),
        ),
      );
      final groupOrder = competitionGroupSortOrder(grade);
      final previousGroupOrder = index == 0
          ? null
          : competitionGroupSortOrder(entries[index - 1].key);
      if (previousGroupOrder != groupOrder && groupOrder < 3) {
        return [
          _CompetitionGroupDivider(
            label: switch (groupOrder) {
              0 => 'امتحانات Concours',
              1 => 'امتحانات Brevet',
              2 => 'امتحانات البكالوريا',
              _ => '',
            },
          ),
          if (_isNationalCompetitionsView)
            _CompetitionYearDivider(label: widget.formatGrade(grade)),
          accordion,
        ];
      }
      return [
        if (_isNationalCompetitionsView)
          _CompetitionYearDivider(label: widget.formatGrade(grade)),
        accordion,
      ];
    }).toList();
  }

  Widget _buildError(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: CurvedHeader(
            title: widget.title,
            gradient: AppTheme.brandGradient,
            leadingIcon: widget.icon,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'تعذّر تحميل المحتوى من الخادم.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(fontSize: 15),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompetitionGroupDivider extends StatelessWidget {
  const _CompetitionGroupDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 14),
      child: Row(
        children: [
          Expanded(child: Divider(color: accent.withValues(alpha: 0.45))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: accent.withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

class _CompetitionYearDivider extends StatelessWidget {
  const _CompetitionYearDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: color.withValues(alpha: 0.35))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: GoogleFonts.tajawal(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: color.withValues(alpha: 0.35))),
        ],
      ),
    );
  }
}

class _ManagedBooksListScreen extends StatefulWidget {
  final String firestoreSection;
  final String grade;
  final String category;
  final String title;
  final String stageName;
  final IconData icon;

  const _ManagedBooksListScreen({
    required this.firestoreSection,
    required this.grade,
    required this.category,
    required this.title,
    required this.stageName,
    required this.icon,
  });

  @override
  State<_ManagedBooksListScreen> createState() =>
      _ManagedBooksListScreenState();
}

class _ManagedBooksListScreenState extends State<_ManagedBooksListScreen> {
  late Stream<List<Book>> _booksStream;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _booksStream = _watchBooks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<Book>> _watchBooks() {
    return FirebaseFirestore.instance
        .collection('books')
        .where('section', isEqualTo: widget.firestoreSection)
        .snapshots()
        .map(
          (snapshot) => filterManagedBooks(
            books: snapshot.docs.map(
              (document) => Book.fromMap(document.data(), document.id),
            ),
            section: widget.firestoreSection,
            grade: widget.grade,
            category: widget.category,
          ),
        );
  }

  List<Book> _applySearch(List<Book> books) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return books;

    return books.where((book) {
      final haystack = [
        book.title,
        book.subject,
        book.category,
        book.grade,
        book.subtitle ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _retry() {
    setState(() => _booksStream = _watchBooks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Book>>(
        stream: _booksStream,
        builder: (context, snapshot) {
          final books = snapshot.hasData
              ? _applySearch(snapshot.data!)
              : <Book>[];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CurvedHeader(
                  title: widget.title,
                  gradient: AppTheme.brandGradient,
                  leadingIcon: widget.icon,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textDirection: TextDirection.rtl,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'ابحث عن كتاب أو مادة أو قسم...',
                        hintStyle: GoogleFonts.tajawal(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تعذّر تحميل الكتب من الخادم.',
                          style: GoogleFonts.tajawal(),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _retry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!snapshot.hasData)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (books.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'لا توجد كتب مفعّلة في هذا القسم.'
                          : 'لا توجد نتائج مطابقة للبحث.',
                      style: GoogleFonts.tajawal(fontSize: 15),
                    ),
                  ),
                )
              else if (widget.firestoreSection == BooksData.sCompetitions ||
                  widget.stageName == 'امتحانات وطنية')
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                  sliver: SliverToBoxAdapter(
                    child: _buildCompetitionTable(books),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      books
                          .map(
                            (book) => _BookTile(
                              book: book,
                              stageName: widget.stageName,
                              sectionName: widget.category,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompetitionTable(List<Book> books) {
    final sortedBooks = books.toList()
      ..sort((a, b) {
        final typeOrder = competitionGroupSortOrder(
          a.grade,
        ).compareTo(competitionGroupSortOrder(b.grade));
        if (typeOrder != 0) return typeOrder;
        final subjectPriority = competitionSubjectSortOrder(
          a.subject,
        ).compareTo(competitionSubjectSortOrder(b.subject));
        if (subjectPriority != 0) return subjectPriority;
        final subjectOrder = _normalizeText(
          a.subject,
        ).compareTo(_normalizeText(b.subject));
        if (subjectOrder != 0) return subjectOrder;
        return _normalizeText(a.title).compareTo(_normalizeText(b.title));
      });

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedBooks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = sortedBooks[index];
        final hasSolution = book.solutionUrl.trim().isNotEmpty;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFDDEEEA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Text(
                  book.subject.isNotEmpty ? book.subject : book.title,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F4D4A),
                    fontSize: 15,
                  ),
                ),
              ),
              if (book.url.trim().isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      _openBookFromList(context, book.url, book.title, book),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    'الامتحان',
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (hasSolution) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _openBookFromList(
                    context,
                    book.solutionUrl,
                    'حل ${book.title}',
                    book,
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'الحل',
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openBookFromList(
    BuildContext context,
    String url,
    String title,
    Book book,
  ) {
    if (url.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(
          pdfUrl: url,
          title: title,
          stageName: widget.stageName,
          sectionName: widget.firestoreSection,
          book: book,
          useLatestRemoteUrl: true,
        ),
      ),
    );
  }
}

class ManagedBookSection {
  final String grade;
  final String category;
  final Map<String, Book> books = {};

  ManagedBookSection({required this.grade, required this.category});
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A008B70),
          child: Icon(Icons.folder_open_rounded, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.tajawal(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count كتاب',
              style: GoogleFonts.tajawal(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  final String stageName;
  final String sectionName;

  const _BookTile({
    required this.book,
    required this.stageName,
    required this.sectionName,
  });

  void _openBook(BuildContext context, String url, String title) {
    if (url.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(
          pdfUrl: url,
          title: title,
          stageName: stageName,
          sectionName: sectionName,
          book: book,
          useLatestRemoteUrl: true,
        ),
      ),
    );
  }

  IconData _subjectIcon() {
    final haystack = '${book.subject} ${book.title}'.toLowerCase();
    if (haystack.contains('رياضيات') || haystack.contains('math')) {
      return Icons.calculate_rounded;
    }
    if (haystack.contains('عربي') || haystack.contains('arabic')) {
      return Icons.auto_stories_rounded;
    }
    if (haystack.contains('علوم') || haystack.contains('science')) {
      return Icons.science_rounded;
    }
    if (haystack.contains('تاريخ') || haystack.contains('جغرافيا')) {
      return Icons.history_edu_rounded;
    }
    if (haystack.contains('فرنسي') || haystack.contains('français')) {
      return Icons.translate_rounded;
    }
    if (haystack.contains('إسلام') || haystack.contains('تربية')) {
      return Icons.mosque_rounded;
    }
    return Icons.menu_book_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = (book.thumbnailUrl ?? '').trim().isNotEmpty;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: book.url.trim().isEmpty
            ? null
            : () => _openBook(context, book.url, book.title),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (book.subject.isNotEmpty)
                      Text(
                        book.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (book.category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: book.url.trim().isEmpty
                                ? null
                                : () =>
                                      _openBook(context, book.url, book.title),
                            icon: const Icon(
                              Icons.visibility_rounded,
                              size: 18,
                            ),
                            label: const Text('عرض الكتاب'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        if (book.solutionUrl.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openBook(
                                context,
                                book.solutionUrl,
                                'حل ${book.title}',
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('الحل'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasCover
                    ? Image.network(
                        book.thumbnailUrl!,
                        width: 84,
                        height: 104,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackCover(),
                      )
                    : _fallbackCover(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: 84,
      height: 104,
      color: AppTheme.primaryColor.withValues(alpha: 0.12),
      child: Center(
        child: Icon(_subjectIcon(), size: 32, color: AppTheme.primaryColor),
      ),
    );
  }
}
