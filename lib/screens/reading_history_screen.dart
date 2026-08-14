import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reading_provider.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class ReadingHistoryScreen extends StatelessWidget {
  const ReadingHistoryScreen({super.key});

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds ثانية';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes دقيقة';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours ساعة و $remainingMinutes دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('سجل القراءة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ReadingProvider>(
        builder: (context, provider, child) {
          final sessions = provider.sessions;
          
          if (sessions.isEmpty) {
            return Center(
              child: Text(
                'لم تقم بفتح أي كتاب بعد',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final book = session.book;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                elevation: 2,
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        book.coverUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(book.coverUrl, width: 60, height: 80, fit: BoxFit.cover),
                              )
                            : Container(
                                width: 60,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.book, color: AppTheme.primaryColor),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.menu_book, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'الصفحة ${session.lastPage} / ${session.totalPages}',
                                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.timer, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(session.readingTimeSeconds),
                                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm').format(session.lastReadAt),
                                    style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
