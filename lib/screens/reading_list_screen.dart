import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/reading_provider.dart';
import '../models/reading_session.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class ReadingListScreen extends StatelessWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        appBar: AppBar(
          title: Text('قائمة القراءة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'أريد قراءته'),
              Tab(text: 'قيد القراءة'),
              Tab(text: 'مكتمل'),
            ],
          ),
        ),
        body: Consumer<ReadingProvider>(
          builder: (context, provider, child) {
            return TabBarView(
              children: [
                _buildList(context, provider.toReadList, isDark),
                _buildList(context, provider.readingList, isDark),
                _buildList(context, provider.completedList, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ReadingSession> list, bool isDark) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'لا توجد كتب هنا',
          style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final session = list[index];
        final book = session.book;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: book.coverUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(book.coverUrl, width: 50, height: 70, fit: BoxFit.cover),
                  )
                : Container(
                    width: 50,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book, color: AppTheme.primaryColor),
                  ),
            title: Text(
              book.title,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${book.section} - ${book.subject}',
                  style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: session.progress,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        color: AppTheme.primaryColor,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(session.progress * 100).toInt()}%',
                      style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
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
          ),
        );
      },
    );
  }
}
