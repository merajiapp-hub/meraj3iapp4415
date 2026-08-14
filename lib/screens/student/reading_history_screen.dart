import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/reading_provider.dart';
import '../../models/reading_session.dart';
import '../../theme/app_theme.dart';

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
                  Icon(Icons.history_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'لا يوجد سجل قراءة بعد',
                    style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _buildHistoryCard(session, isDark);
              },
            ),
    );
  }

  Widget _buildHistoryCard(ReadingSession session, bool isDark) {
    final timeFormatted = DateFormat('yyyy/MM/dd HH:mm').format(session.lastReadAt);
    final durationMinutes = session.readingTimeSeconds ~/ 60;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
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
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.status == ReadingStatus.completed 
                        ? 'مكتمل' 
                        : (session.status == ReadingStatus.reading ? 'مستمر' : 'لم يبدأ'),
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'آخر قراءة: $timeFormatted',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer_rounded, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'الوقت المستغرق: $durationMinutes دقيقة',
                  style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  'توقف عند صـ ${session.lastPage}',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
