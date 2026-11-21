import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video_lesson_models.dart';
import '../../../services/video_download_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/curved_header.dart';
import 'video_player_screen.dart';

class VideoDownloadsScreen extends StatefulWidget {
  const VideoDownloadsScreen({super.key});

  @override
  State<VideoDownloadsScreen> createState() => _VideoDownloadsScreenState();
}

class _VideoDownloadsScreenState extends State<VideoDownloadsScreen> {
  final VideoDownloadService _downloadService = VideoDownloadService();
  List<VideoDownloadItem> _items = [];
  bool _isLoading = true;
  int _totalBytes = 0;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    final list = await _downloadService.getAllDownloads();
    final bytes = await _downloadService.getTotalStorageBytes();
    if (mounted) {
      setState(() {
        _items = list;
        _totalBytes = bytes;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(VideoDownloadItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفيديو من الجهاز'),
        content: Text('هل تريد بالتأكيد حذف فيديو "${item.title}" من التنزيلات؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.deleteDownload(item.lessonId);
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الفيديو من التنزيلات')),
        );
      }
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف جميع التنزيلات'),
        content: const Text('سيتم حذف كافة الفيديوهات المحفوظة في الجهاز لتوفير المساحة. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.deleteAllDownloads();
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفريغ مساحة التنزيلات بالكامل')),
        );
      }
    }
  }

  String _formatTotalSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // رأس الصفحة
          CurvedHeader(
            title: 'الدروس المنزلة (دون إنترنت)',
            subtitle: 'شاهد دروسك المصورة المحفوظة في أي وقت دون اتصال بالشبكة',
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            ),
          ),

          // شريط إجمالي المساحة والإجراءات
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storage_rounded, color: Color(0xFF3B82F6), size: 22),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المساحة المستخدمة',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        Text(
                          '${_items.length} دروس • ${_formatTotalSize(_totalBytes)}',
                          style: GoogleFonts.tajawal(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('حذف الكل'),
                      onPressed: _deleteAll,
                    ),
                  ],
                ),
              ),
            ),

          // قائمة الفيديوهات المنزلة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.download_done_rounded,
                                size: 72,
                                color: Colors.grey.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد فيديوهات منزلة حالياً',
                                style: GoogleFonts.tajawal(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'يمكنك تنزيل أي درس بالضغط على زر "تنزيل الفيديو" لمشاهدته دون إنترنت في أي مكان',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.tajawal(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final dateStr = DateFormat('yyyy/MM/dd').format(item.downloadedAt);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // الصورة المصغرة مع شارة دون إنترنت
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 90,
                                      height: 64,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
                                            CachedNetworkImage(
                                              imageUrl: item.thumbnailUrl!,
                                              fit: BoxFit.cover,
                                              errorWidget: (ctx, url, err) => Container(color: Colors.grey[800]),
                                            )
                                          else
                                            Container(color: Colors.grey[800]),
                                          Container(color: Colors.black38),
                                          const Center(
                                            child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 28),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // تفاصيل الدرس
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.levelCode} • ${item.subjectName}',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.title,
                                          style: GoogleFonts.tajawal(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.formattedSize} • $dateStr',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // أزرار التشغيل والحذف
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981), size: 28),
                                    tooltip: 'تشغيل أوفلاين',
                                    onPressed: () {
                                      // فتح الدرس مع تمرير مسار الملف المحلي
                                      final dummyLesson = VideoLesson(
                                        id: item.lessonId,
                                        levelId: '',
                                        subjectId: '',
                                        title: item.title,
                                        videoUrl: item.localFilePath,
                                        duration: item.duration,
                                        isPro: item.isPro,
                                        createdAt: item.downloadedAt,
                                        updatedAt: item.downloadedAt,
                                      );
                                      final dummySubject = VideoSubject(id: '', levelId: '', title: item.subjectName);
                                      final dummyLevel = VideoLevel(id: '', title: item.levelCode, code: item.levelCode, description: '');

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => VideoPlayerScreen(
                                            lesson: dummyLesson,
                                            subject: dummySubject,
                                            level: dummyLevel,
                                            playlist: [dummyLesson],
                                            localFilePath: item.localFilePath,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    tooltip: 'حذف من الجهاز',
                                    onPressed: () => _deleteItem(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
