import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/downloads_provider.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'pdf_viewer_screen.dart';
import '../widgets/curved_header.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          CurvedHeader(
            title: 'التنزيلات',
            gradient: isDark ? AppTheme.deepBlueGradient : AppTheme.primaryGradient,
            showBackButton: false,
          ),
          Expanded(child: Consumer<DownloadsProvider>(
        builder: (context, provider, child) {
          return _buildBooksList(provider, isDark);
        },
      )),
        ],
      ),
    );
  }

  Widget _buildBooksList(DownloadsProvider provider, bool isDark) {
    final books = provider.downloads;
    if (books.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_for_offline_outlined,
        title: 'لا توجد كتب محفوظة',
        subtitle: 'الكتب التي تحملها ستظهر هنا للقراءة دون إنترنت.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return _DownloadedBookCard(
          db: books[index],
          isDark: isDark,
          onDelete: () => _confirmDeleteBook(context, provider, books[index]),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Icon(icon, size: 90, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteBook(BuildContext context, DownloadsProvider provider, DownloadedBook db) async {
    final confirmed = await _showDeleteDialog(context, db.title);
    if (confirmed == true) {
      await provider.removeDownload(db.uniqueKey);
      if (context.mounted) _showSuccess(context);
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context, String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الحذف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف "$itemName" نهائياً من التنزيلات؟', style: GoogleFonts.tajawal(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم الحذف بنجاح', style: GoogleFonts.tajawal()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}

class _DownloadedBookCard extends StatelessWidget {
  final DownloadedBook db;
  final bool isDark;
  final VoidCallback onDelete;

  const _DownloadedBookCard({required this.db, required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: db.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: db.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.red.shade400,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.red.shade400,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        db.title,
                        style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${db.fileSizeMb.toStringAsFixed(2)} MB • ${db.section}',
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

