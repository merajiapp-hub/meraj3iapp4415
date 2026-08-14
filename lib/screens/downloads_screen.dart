import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/downloads_provider.dart';
import '../widgets/geometric_sliver_app_bar.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const GeometricSliverAppBar(
            title: 'التنزيلات',
            icon: Icons.download_done_rounded,
            gradient: AppTheme.greenGradient,
          ),
          Consumer<DownloadsProvider>(
            builder: (context, downloadsProvider, child) {
              final downloads = downloadsProvider.downloads;

              if (downloads.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final db = downloads[index];
                    return _DownloadedBookCard(
                      db: db,
                      isDark: isDark,
                      onDelete: () =>
                          _confirmDelete(context, downloadsProvider, db),
                    );
                  }, childCount: downloads.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.green.shade100,
            highlightColor: Colors.green.shade50,
            child: Icon(
              Icons.download_for_offline_outlined,
              size: 100,
              color: Colors.green.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد تنزيلات حالياً',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الكتب التي تحملها ستظهر هنا للقراءة دون إنترنت',
            style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DownloadsProvider provider,
    DownloadedBook db,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف التنزيل',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل تريد حذف "${db.title}" من التنزيلات؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.removeDownload(db.uniqueKey);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الملف بنجاح', style: GoogleFonts.tajawal()),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

class _DownloadedBookCard extends StatelessWidget {
  final DownloadedBook db;
  final bool isDark;
  final VoidCallback onDelete;

  const _DownloadedBookCard({
    required this.db,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    pdfUrl: '',
                    title: db.title,
                    localPath: db.localPath,
                    stageName: db.section,
                    sectionName: db.category,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // PDF Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.greenGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.file_download_done_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          db.title,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                db.grade,
                                style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${db.fileSizeMb.toStringAsFixed(1)} MB',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          db.category,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'حذف التنزيل',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // شريط علوي صغير
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppTheme.greenGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
