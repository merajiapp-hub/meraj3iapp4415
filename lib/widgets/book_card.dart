import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/book.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/reading_provider.dart';
import '../screens/pdf_viewer_screen.dart';
import 'app_notification.dart';

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

  /// نوع أيقونة المادة بناءً على اسم الكتاب/المادة
  IconData get _subjectIcon {
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

  String _getDirectLink(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final id = url.split('/d/')[1].split('/')[0].split('?')[0];
      return 'https://docs.google.com/uc?export=download&id=$id';
    }
    return url;
  }

  Future<void> _downloadBook() async {
    if (widget.book.url.isEmpty ||
        widget.book.url.contains('/drive/folders/')) {
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

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${widget.book.uniqueKey}.pdf';
      final savePath = '${directory.path}/$fileName';
      final processedUrl = _getDirectLink(widget.book.url);

      await Dio().download(
        processedUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1 && mounted) {
            setState(() => _downloadProgress = count / total);
          }
        },
      );

      final file = File(savePath);
      if (!await file.exists()) throw Exception('File not created');

      final fileSize = await file.length();
      final fileSizeMb = fileSize / (1024 * 1024);
      final db = DownloadedBook.fromBook(widget.book, savePath, fileSizeMb);

      if (mounted) {
        await downloads.addDownload(db);
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0;
          });
          AppNotification.show(
            context,
            '✅ تم تنزيل "${widget.book.title}" بنجاح',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
        AppNotification.show(
          context,
          'فشل التنزيل، تحقق من الاتصال بالإنترنت',
          isError: true,
        );
      }
      debugPrint('Download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = (widget.gradient as LinearGradient).colors.first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: widget.isDark ? 0.15 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
          borderRadius: BorderRadius.circular(18),
          splashColor: accentColor.withValues(alpha: 0.08),
          highlightColor: accentColor.withValues(alpha: 0.04),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, secondaryAnimation) =>
                    PdfViewerScreen(
                      pdfUrl: widget.book.url,
                      title: widget.book.title,
                      stageName: widget.book.section,
                      sectionName: widget.book.category,
                      book: widget.book,
                    ),
                transitionsBuilder: (_, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 230),
              ),
            );
          },
          child: Column(
            children: [
              // ── الشريط العلوي الملوّن ──
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
              ),

              // ── محتوى البطاقة ──
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 250;

                    final iconWidget = Container(
                      width: isNarrow ? 40 : 48,
                      height: isNarrow ? 40 : 48,
                      decoration: BoxDecoration(
                        gradient: widget.gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(_subjectIcon, color: Colors.white, size: isNarrow ? 20 : 22),
                    );

                    final textContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: isNarrow ? MainAxisAlignment.start : MainAxisAlignment.center,
                      children: [
                        // اسم الكتاب باتجاه RTL صحيح منعاً لتقطيع الحروف
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            widget.book.title,
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: isNarrow ? 12 : 13.5,
                              color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                        if (widget.book.subject.isNotEmpty && widget.book.subject != widget.book.title) ...[

                          const SizedBox(height: 3),
                          Text(
                            widget.book.subject,
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
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
                            _buildBadge(widget.book.category, accentColor),
                            if (widget.showStage) _buildBadge(widget.book.section, accentColor),
                          ],
                        ),
                      ],
                    );

                    final actionsWidget = Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isNarrow ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                      children: [
                        Consumer<ReadingProvider>(
                          builder: (context, reading, _) {
                            final isRead = reading.isRead(widget.book.uniqueKey);
                            if (!isRead) return const SizedBox.shrink();
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            );
                          },
                        ),
                        Consumer<DownloadsProvider>(
                          builder: (context, downloads, _) {
                            final isDownloaded = downloads.isDownloaded(widget.book.uniqueKey);
                            if (_isDownloading) {
                              return SizedBox(
                                width: 30,
                                height: 30,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    value: _downloadProgress > 0 ? _downloadProgress : null,
                                    strokeWidth: 2.5,
                                    color: accentColor,
                                  ),
                                ),
                              );
                            }
                            return _ActionIconBtn(
                              icon: isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                              color: isDownloaded ? const Color(0xFF16A34A) : (widget.isDark ? Colors.grey[500]! : Colors.grey[400]!),
                              tooltip: isDownloaded ? 'تم التنزيل' : 'تنزيل',
                              onTap: _downloadBook,
                            );
                          },
                        ),
                        Consumer<FavoritesProvider>(
                          builder: (context, favorites, _) {
                            final isFav = favorites.isFavorite(widget.book.uniqueKey);
                            return _ActionIconBtn(
                              icon: isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                              color: isFav ? Colors.red : (widget.isDark ? Colors.grey[500]! : Colors.grey[400]!),
                              tooltip: isFav ? 'إزالة من المفضلة' : 'أضف للمفضلة',
                              onTap: () => favorites.toggleFavorite(context, widget.book),
                            );
                          },
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            iconWidget,
                            const SizedBox(height: 8),
                            Expanded(child: textContent),
                            actionsWidget,
                          ],
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            iconWidget,
                            const SizedBox(width: 12),
                            Expanded(child: textContent),
                            actionsWidget,
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),

              // ── شريط تقدم التنزيل ──
              if (_isDownloading)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: widget.isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: widget.isDark ? accent.withValues(alpha: 0.9) : accent,
        ),
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
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}
