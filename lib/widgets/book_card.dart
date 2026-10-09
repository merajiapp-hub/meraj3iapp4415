import 'dart:async';
import 'dart:io';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/reading_provider.dart';
import '../screens/pdf_viewer_screen.dart';
import 'app_notification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/book_download_service.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final Gradient gradient;
  final bool isDark;
  final bool showStage;

  const BookCard({
    super.key,
    required this.book,
    required this.gradient,
    required this.isDark,
    this.showStage = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isDownloading = false;
  double _downloadProgress = 0;
  final BookDownloadService _downloadService = BookDownloadService();
  StreamSubscription<BookDownloadProgress>? _progressSubscription;

  String? _cachedThumbnailUrl;
  IconData? _cachedSubjectIcon;

  @override
  void initState() {
    super.initState();
    _cachedThumbnailUrl = widget.book.thumbnailUrl;
    _cachedSubjectIcon = _computeSubjectIcon();
  }

  @override
  void didUpdateWidget(covariant BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book) {
      _cachedThumbnailUrl = widget.book.thumbnailUrl;
      _cachedSubjectIcon = _computeSubjectIcon();
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  IconData get _subjectIcon => _cachedSubjectIcon!;

  IconData _computeSubjectIcon() {
    final s = (widget.book.subject + widget.book.title).toLowerCase();
    if (s.contains('رياضيات') || s.contains('math')) return Icons.calculate_rounded;
    if (s.contains('فرنسية') || s.contains('français')) return Icons.translate_rounded;
    if (s.contains('علوم') || s.contains('science')) return Icons.science_rounded;
    if (s.contains('إسلامية') || s.contains('تربية إسلامية')) return Icons.mosque_rounded;
    if (s.contains('تاريخ')) return Icons.history_edu_rounded;
    if (s.contains('جغرافيا')) return Icons.public_rounded;
    if (s.contains('مدنية')) return Icons.balance_rounded;
    if (s.contains('إيقاظ') || s.contains('سلوك')) return Icons.lightbulb_rounded;
    if (s.contains('أناشيد')) return Icons.music_note_rounded;
    if (s.contains('فلسفة')) return Icons.psychology_rounded;
    if (s.contains('عربية') || s.contains('arabic')) return Icons.auto_stories_rounded;
    return Icons.menu_book_rounded;
  }

  Future<void> _downloadBook() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isGuest || auth.user == null) {
      AppNotification.show(context, 'يرجى تسجيل الدخول أولاً لتتمكن من تنزيل الكتب.', isError: true);
      return;
    }

    if (widget.book.url.isEmpty || widget.book.url.contains('/drive/folders/')) {
      AppNotification.show(context, 'الرابط غير متوفر', isError: true);
      return;
    }

    final downloads = Provider.of<DownloadsProvider>(context, listen: false);

    if (downloads.isDownloaded(widget.book.uniqueKey)) {
      AppNotification.show(
        context,
        '✅ تم تنزيل هذا الكتاب مسبقاً — يمكن فتحه من التنزيلات',
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    // Subscribe to progress updates
    _progressSubscription?.cancel();
    _progressSubscription = _downloadService
        .progressFor(widget.book.uniqueKey)
        .listen((p) {
          if (mounted) setState(() => _downloadProgress = p.value ?? 0);
        });

    try {
      final localPath = await _downloadService.getOrDownload(widget.book);

      if (mounted) {
        final file = File(localPath);
        final sizeBytes = await file.exists() ? await file.length() : 0;
        final downloadedBook = DownloadedBook.fromBook(
          widget.book,
          localPath,
          sizeBytes / (1024 * 1024),
        );
        await downloads.addDownload(downloadedBook);
        if (mounted) AppNotification.show(context, '✅ تم تنزيل الكتاب بنجاح');
      }
    } catch (e) {
      if (mounted) {
        if (e is SocketException) {
          AppNotification.show(context, 'تحقق من اتصالك بالإنترنت', isError: true);
        } else {
          AppNotification.show(context, 'خطأ: ${e.toString().split('\n').first}', isError: true);
        }
      }
      debugPrint('Download error: $e');
    } finally {
      _progressSubscription?.cancel();
      _progressSubscription = null;
      if (mounted) setState(() { _isDownloading = false; _downloadProgress = 0; });
    }
  }

  void _openBook() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => PdfViewerScreen(
          pdfUrl: widget.book.url,
          title: widget.book.title,
          stageName: widget.book.section,
          sectionName: widget.book.category,
          book: widget.book,
        ),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          ),
        ),
        transitionDuration: const Duration(milliseconds: 230),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = (widget.gradient as LinearGradient).colors.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: widget.isDark ? 0.12 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : accentColor.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withValues(alpha: 0.08),
          onTap: _openBook,
          child: Column(
            children: [
              // ── شريط لوني علوي ──
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
              ),
              // ── المحتوى الرئيسي ──
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── غلاف الكتاب ──
                    _BookCover(
                      thumbnailUrl: _cachedThumbnailUrl,
                      fallbackIcon: _subjectIcon,
                      accentColor: accentColor,
                      isDark: widget.isDark,
                    ),
                    const SizedBox(width: 10),
                    // ── معلومات الكتاب ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              widget.book.title,
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.book.subject.isNotEmpty &&
                              widget.book.subject != widget.book.title) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.book.subject,
                              style: GoogleFonts.tajawal(
                                fontSize: 10,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: [
                              _buildBadge(widget.book.grade, accentColor),
                              if (widget.showStage) _buildBadge(widget.book.section, accentColor),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ── أزرار الإجراءات ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Consumer<ReadingProvider>(
                                builder: (_, reading, _) {
                                  final isRead = reading.isRead(widget.book.uniqueKey);
                                  if (!isRead) return const SizedBox.shrink();
                                  return const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF16A34A), size: 16),
                                  );
                                },
                              ),
                              Consumer<DownloadsProvider>(
                                builder: (_, downloads, _) {
                                  final isDownloaded = downloads.isDownloaded(widget.book.uniqueKey);
                                  if (_isDownloading) {
                                    return SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: CircularProgressIndicator(
                                          value: _downloadProgress > 0 ? _downloadProgress : null,
                                          strokeWidth: 2,
                                          color: accentColor,
                                        ),
                                      ),
                                    );
                                  }
                                  return _ActionIconBtn(
                                    icon: isDownloaded
                                        ? Icons.download_done_rounded
                                        : Icons.download_rounded,
                                    color: isDownloaded
                                        ? const Color(0xFF16A34A)
                                        : (widget.isDark ? Colors.grey[500]! : Colors.grey[400]!),
                                    tooltip: isDownloaded ? 'تم التنزيل' : 'تنزيل',
                                    onTap: _downloadBook,
                                  );
                                },
                              ),
                              Consumer<FavoritesProvider>(
                                builder: (_, favorites, _) {
                                  final isFav = favorites.isFavorite(widget.book.uniqueKey);
                                  return _ActionIconBtn(
                                    icon: isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_outline_rounded,
                                    color: isFav
                                        ? Colors.red
                                        : (widget.isDark
                                            ? Colors.grey[500]!
                                            : Colors.grey[400]!),
                                    tooltip: isFav ? 'إزالة من المفضلة' : 'أضف للمفضلة',
                                    onTap: () => favorites.toggleFavorite(context, widget.book),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── شريط تقدم التنزيل ──
              if (_isDownloading)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    minHeight: 3,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color accent) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: widget.isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? accent.withValues(alpha: 0.9) : accent,
        ),
      ),
    );
  }
}

// ── غلاف الكتاب ──────────────────────────────────────────────────────────────

class _BookCover extends StatelessWidget {
  final String? thumbnailUrl;
  final IconData fallbackIcon;
  final Color accentColor;
  final bool isDark;

  const _BookCover({
    required this.thumbnailUrl,
    required this.fallbackIcon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 90,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => _FallbackCover(
                icon: fallbackIcon,
                color: accentColor,
                isDark: isDark,
              ),
            )
          : _FallbackCover(
              icon: fallbackIcon,
              color: accentColor,
              isDark: isDark,
            ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _FallbackCover({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        icon,
        color: isDark ? Colors.white.withValues(alpha: 0.7) : color,
        size: 32,
      ),
    );
  }
}

/// زر أيقونة مدمج أنيق
class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}
