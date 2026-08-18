import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reading_provider.dart';
import '../../models/reading_session.dart';
import '../../theme/app_theme.dart';
import '../pdf_viewer_screen.dart';

class ReadingHistoryScreen extends StatelessWidget {
  const ReadingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final readingProvider = context.watch<ReadingProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessions = readingProvider.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Text('سجل القراءة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد سجل قراءة بعد',
                    style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'افتح أي كتاب وستظهر هنا تلقائياً',
                    style: GoogleFonts.tajawal(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildHistoryCard(context, session, isDark);
              },
            ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ReadingSession session, bool isDark) {
    final timeFormatted = DateFormat('yyyy/MM/dd HH:mm').format(session.lastReadAt);
    final durationMinutes = session.readingTimeSeconds ~/ 60;
    final progress = session.totalPages > 0
        ? (session.lastPage / session.totalPages).clamp(0.0, 1.0)
        : 0.0;

    String statusLabel;
    Color statusColor;
    switch (session.status) {
      case ReadingStatus.completed:
        statusLabel = 'مكتمل ✅';
        statusColor = Colors.green;
        break;
      case ReadingStatus.reading:
        statusLabel = 'مستمر 📖';
        statusColor = AppTheme.primaryColor;
        break;
      default:
        statusLabel = 'لم يبدأ';
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        // فتح الكتاب مباشرة من آخر صفحة تمت قراءتها
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfUrl: session.book.url,
              title: session.book.title,
              stageName: session.book.section,
              sectionName: session.book.category,
              book: session.book,

            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          session.book.title,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'آخر قراءة: $timeFormatted',
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_rounded, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'الوقت المستغرق: $durationMinutes دقيقة',
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const Spacer(),
                      Text(
                        'صـ ${session.lastPage}${session.totalPages > 0 ? " / ${session.totalPages}" : ""}',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (session.totalPages > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0 ? Colors.green : AppTheme.primaryColor,
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // زر "استئناف القراءة"
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        pdfUrl: session.book.url,
                        title: session.book.title,
                        stageName: session.book.section,
                        sectionName: session.book.category,
                        book: session.book,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.primaryColor),
                label: Text(
                  session.lastPage > 0 ? 'استئناف من صـ ${session.lastPage}' : 'فتح الكتاب',
                  style: GoogleFonts.tajawal(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
