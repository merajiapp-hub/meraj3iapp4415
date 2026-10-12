import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import 'pdf_viewer_screen.dart';

String _bookContentKey(Book book) => [
      book.section.trim().toLowerCase(),
      book.grade.trim().toLowerCase(),
      book.category.trim().toLowerCase(),
      book.title.trim().toLowerCase(),
      book.subject.trim().toLowerCase(),
      book.url.trim(),
      book.solutionUrl.trim(),
    ].join('\u0000');

List<Book> filterManagedBooks({
  required Iterable<Book> books,
  required String section,
  String? grade,
  String? category,
}) {
  final uniqueBooks = <String, Book>{};
  for (final book in books) {
    if (book.section != section ||
        !book.isActive ||
        (grade != null && book.grade != grade) ||
        (category != null && book.category != category)) {
      continue;
    }
    uniqueBooks.putIfAbsent(_bookContentKey(book), () => book);
  }
  final result = uniqueBooks.values.toList()
    ..sort((a, b) {
      final gradeOrder = a.grade.compareTo(b.grade);
      if (gradeOrder != 0) return gradeOrder;
      final categoryOrder = a.category.compareTo(b.category);
      if (categoryOrder != 0) return categoryOrder;
      return a.title.compareTo(b.title);
    });
  return result;
}

List<ManagedBookSection> groupManagedBooks(Iterable<Book> books) {
  final grouped = <String, ManagedBookSection>{};
  for (final book in books) {
    final key = '${book.grade}\u0000${book.category}';
    grouped.putIfAbsent(
      key,
      () => ManagedBookSection(grade: book.grade, category: book.category),
    );
    grouped[key]!.books.putIfAbsent(_bookContentKey(book), () => book);
  }
  final sections = grouped.values.toList()
    ..sort((a, b) {
      final gradeOrder = a.grade.compareTo(b.grade);
      if (gradeOrder != 0) return gradeOrder;
      return a.category.compareTo(b.category);
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

  @override
  void initState() {
    super.initState();
    _booksStream = _watchBooks();
  }

  Stream<List<Book>> _watchBooks() {
    return FirebaseFirestore.instance
        .collection('books')
        .where('section', isEqualTo: widget.section)
        .snapshots()
        .map(
          (snapshot) => filterManagedBooks(
            books: snapshot.docs.map(
              (document) => Book.fromMap(document.data(), document.id),
            ),
            section: widget.section,
          ),
        );
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
          if (snapshot.hasError) {
            return _buildError(context);
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sections = groupManagedBooks(snapshot.data!);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CurvedHeader(
                  title: widget.title,
                  gradient: AppTheme.brandGradient,
                  leadingIcon: widget.icon,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 56, color: AppTheme.primaryColor),
            const SizedBox(height: 14),
            Text(
              'لا توجد أقسام أو كتب مفعّلة حالياً',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  void initState() {
    super.initState();
    _booksStream = _watchBooks();
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

  void _retry() {
    setState(() => _booksStream = _watchBooks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Book>>(
        stream: _booksStream,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CurvedHeader(
                  title: widget.title,
                  gradient: AppTheme.brandGradient,
                  leadingIcon: widget.icon,
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
              else if (snapshot.data!.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'لا توجد كتب مفعّلة في هذا القسم.',
                      style: GoogleFonts.tajawal(fontSize: 15),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      snapshot.data!
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: Icon(
          Icons.menu_book_rounded,
          color: AppTheme.primaryColor,
          size: 28,
        ),
        title: Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        subtitle: book.subject.isEmpty
            ? null
            : Text(book.subject, style: GoogleFonts.tajawal(fontSize: 12)),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'عرض الكتاب',
              onPressed: book.url.trim().isEmpty
                  ? null
                  : () => _openBook(context, book.url, book.title),
              icon: const Icon(Icons.visibility_rounded),
              color: AppTheme.primaryColor,
            ),
            if (book.solutionUrl.trim().isNotEmpty)
              IconButton(
                tooltip: 'عرض الحل',
                onPressed: () =>
                    _openBook(context, book.solutionUrl, 'حل ${book.title}'),
                icon: const Icon(Icons.check_circle_outline_rounded),
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }
}
