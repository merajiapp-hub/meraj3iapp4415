import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../models/book.dart';
import '../providers/downloads_provider.dart';
import '../providers/reading_provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../data/ad_manager.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;
  final String? localPath;
  final String? stageName;
  final String? sectionName;
  final Book? book;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
    this.localPath,
    this.stageName,
    this.sectionName,
    this.book,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen>
    with SingleTickerProviderStateMixin {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool _isNightMode = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _remainingTime = "";
  DateTime? _lastTime;
  int _lastBytes = 0;
  String? _localPath;
  late String _processedUrl;

  // Page persistence
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoaded = false;

  // Bookmarks
  List<int> _bookmarks = [];
  bool _showBookmarks = false;

  // Page jump controller
  final TextEditingController _pageJumpController = TextEditingController();

  // Animation
  late AnimationController _toolbarAnimController;
  late Animation<double> _toolbarAnim;
  bool _toolbarVisible = true;

  String get _prefsKey =>
      'last_page_${widget.book?.uniqueKey ?? widget.localPath?.hashCode ?? widget.title.hashCode}';
  String get _bookmarksKey =>
      'bookmarks_${widget.book?.uniqueKey ?? widget.localPath?.hashCode ?? widget.title.hashCode}';

  @override
  void initState() {
    super.initState();
    _localPath = widget.localPath;
    _processedUrl = _getDirectLink(widget.pdfUrl);

    _toolbarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _toolbarAnim = CurvedAnimation(
      parent: _toolbarAnimController,
      curve: Curves.easeOut,
    );
    _toolbarAnimController.value = 1.0;

    // فحص الملف المحلي فوراً بمجرد فتح الشاشة — تحسين السرعة
    if (_localPath == null && widget.pdfUrl.isNotEmpty) {
      Future.microtask(() => _checkLocalFile());
    }

    if (widget.pdfUrl.contains('/drive/folders/')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _launchUrl(widget.pdfUrl);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.book != null) {
        final stats = Provider.of<StatisticsProvider>(context, listen: false);
        final isUploaded = widget.book!.section == 'uploaded';
        stats.incrementBookStat(
          widget.book!.uniqueKey,
          'openCount',
          isUploaded: isUploaded,
          docId: isUploaded ? widget.book!.id : null,
        );
        stats.incrementUserStat('readBooks');
      }
    });

    _loadSavedData();
  }

  @override
  void dispose() {
    _toolbarAnimController.dispose();
    _pageJumpController.dispose();
    AdManager.showInterstitialAd(chance: 0.3);
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt(_prefsKey) ?? 1;
    final savedBookmarks =
        prefs.getStringList(_bookmarksKey)?.map(int.parse).toList() ?? [];
    setState(() {
      _currentPage = savedPage;
      _bookmarks = savedBookmarks;
    });
  }

  Future<void> _saveCurrentPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, page);
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _bookmarksKey,
      _bookmarks.map((e) => e.toString()).toList(),
    );
  }

  void _toggleBookmark(int page) {
    setState(() {
      if (_bookmarks.contains(page)) {
        _bookmarks.remove(page);
        AppNotification.show(context, 'تم حذف العلامة المرجعية');
      } else {
        _bookmarks.add(page);
        _bookmarks.sort();
        AppNotification.show(context, 'تمت إضافة علامة مرجعية للصفحة $page 🔖');
      }
    });
    _saveBookmarks();
  }

  void _toggleToolbar() {
    setState(() => _toolbarVisible = !_toolbarVisible);
    if (_toolbarVisible) {
      _toolbarAnimController.forward();
    } else {
      _toolbarAnimController.reverse();
    }
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfViewerController.jumpToPage(page);
      Navigator.pop(context);
    } else {
      AppNotification.show(context, 'رقم الصفحة غير صحيح', isError: true);
    }
  }

  String _getDirectLink(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      final id = url.split('/d/')[1].split('/')[0].split('?')[0];
      // استخدام export=download لتحميل مباشر بدون تحويل
      return 'https://drive.google.com/uc?export=download&id=$id&confirm=t';
    }
    return url;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _checkLocalFile() async {
    if (widget.book != null) {
      final downloads = Provider.of<DownloadsProvider>(context, listen: false);
      final path = downloads.getLocalPath(widget.book!.uniqueKey);
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          setState(() {
            _localPath = file.path;
          });
          return;
        } else {
          downloads.removeDownload(widget.book!.uniqueKey);
        }
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = _generateFileName();
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) {
      setState(() {
        _localPath = file.path;
      });
    }
  }

  String _generateFileName() {
    if (widget.book != null) return "${widget.book!.uniqueKey}.pdf";
    String name = widget.title;
    if (widget.stageName != null && widget.stageName!.isNotEmpty) {
      name = "${widget.stageName} - $name";
    }
    if (widget.sectionName != null && widget.sectionName!.isNotEmpty) {
      name = "${widget.sectionName} - $name";
    }
    name = name.replaceAll(' ', '_').replaceAll('/', '_').replaceAll('\\', '_');
    return "$name.pdf";
  }

  Future<void> _downloadPdf() async {
    if (widget.pdfUrl.contains('/drive/folders/')) {
      _launchUrl(widget.pdfUrl);
      return;
    }
    if (widget.pdfUrl.isEmpty) {
      AppNotification.show(context, 'الرابط غير متوفر', isError: true);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'MERAJ3I',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          content: Text(
            'هل تريد تحميل "${widget.title}" للمطالعة لاحقاً بدون إنترنت؟',
            style: GoogleFonts.tajawal(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'تحميل',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _remainingTime = "";
      _lastTime = DateTime.now();
      _lastBytes = 0;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = _generateFileName();
      final savePath = '${directory.path}/$fileName';

      await Dio().download(
        _processedUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            final now = DateTime.now();
            final elapsedMs = now.difference(_lastTime!).inMilliseconds;
            if (elapsedMs > 500) {
              final bytesSinceLast = count - _lastBytes;
              final speedBps = bytesSinceLast / (elapsedMs / 1000);
              final remainingBytes = total - count;
              final seconds = remainingBytes / speedBps;
              setState(() {
                _downloadProgress = count / total;
                if (seconds.isFinite && seconds > 0) {
                  _remainingTime = '${seconds.toStringAsFixed(0)} ث';
                }
                _lastTime = now;
                _lastBytes = count;
              });
            } else {
              setState(() {
                _downloadProgress = count / total;
              });
            }
          }
        },
      );

      if (widget.book != null) {
        final file = File(savePath);
        final fileSize = await file.length();
        final fileSizeMb = fileSize / (1024 * 1024);
        final db = DownloadedBook.fromBook(widget.book!, savePath, fileSizeMb);
        if (mounted) {
          final dbProvider = Provider.of<DownloadsProvider>(
            context,
            listen: false,
          );
          final statsProvider = Provider.of<StatisticsProvider>(
            context,
            listen: false,
          );

          await dbProvider.addDownload(db);

          // Update Stats
          final isUploaded = widget.book!.section == 'uploaded';
          statsProvider.incrementBookStat(
            widget.book!.uniqueKey,
            'downloadCount',
            isUploaded: isUploaded,
            docId: isUploaded ? widget.book!.id : null,
          );
          statsProvider.incrementUserStat('downloadedBooks');
        }
      }

      setState(() {
        _localPath = savePath;
        _isDownloading = false;
      });

      if (mounted) {
        AppNotification.show(context, 'تم تحميل الكتاب للقراءة بدون إنترنت ✅');
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        AppNotification.show(
          context,
          'فشل التحميل، جرب فتح الرابط في المتصفح',
          isError: true,
        );
      }
    }
  }

  void _showPageJumpDialog() {
    _pageJumpController.text = _currentPage.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'الانتقال إلى صفحة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إجمالي الصفحات: $_totalPages',
              style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pageJumpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'رقم الصفحة',
                hintStyle: GoogleFonts.tajawal(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (v) {
                final page = int.tryParse(v);
                if (page != null) _jumpToPage(page);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(_pageJumpController.text);
              if (page != null) _jumpToPage(page);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'انتقال',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarksPanel() {
    setState(() => _showBookmarks = !_showBookmarks);
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = widget.pdfUrl.contains('/drive/folders/');
    final isLocalOnly = widget.localPath != null && widget.pdfUrl.isEmpty;
    final isBookmarked = _bookmarks.contains(_currentPage);

    return Scaffold(
      backgroundColor: _isNightMode
          ? Colors.black
          : Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: _isNightMode
            ? const Color(0xFF1A1A2E).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        foregroundColor: _isNightMode ? Colors.white : Colors.black87,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: GestureDetector(
          onTap: _isLoaded ? _showPageJumpDialog : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (_isLoaded && _totalPages > 0)
                Text(
                  'الصفحة $_currentPage من $_totalPages  •  اضغط للانتقال',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          // Mark as read
          if (widget.book != null)
            Consumer<ReadingProvider>(
              builder: (context, reading, _) {
                final isRead = reading.isRead(widget.book!.uniqueKey);
                return IconButton(
                  icon: Icon(
                    isRead
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isRead
                        ? Colors.green
                        : (_isNightMode ? Colors.white70 : Colors.black54),
                  ),
                  tooltip: isRead ? 'مقروء' : 'تعيين كمقروء',
                  onPressed: () {
                    reading.markAsRead(widget.book!.uniqueKey);
                    if (!isRead) {
                      AppNotification.show(
                        context,
                        'تم حفظ الكتاب في المقروءات ✅',
                      );
                    }
                  },
                );
              },
            ),
          // Bookmark current page
          if (_isLoaded)
            IconButton(
              icon: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_add_outlined,
                color: isBookmarked
                    ? AppTheme.secondaryColor
                    : (_isNightMode ? Colors.white70 : Colors.black54),
              ),
              tooltip: isBookmarked ? 'إزالة العلامة' : 'إضافة علامة مرجعية',
              onPressed: () => _toggleBookmark(_currentPage),
            ),
          // Show bookmarks list
          if (_bookmarks.isNotEmpty)
            IconButton(
              icon: Stack(
                alignment: Alignment.topRight,
                children: [
                  const Icon(Icons.bookmarks_rounded),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_bookmarks.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ],
              ),
              tooltip: 'العلامات المرجعية',
              onPressed: _showBookmarksPanel,
            ),
          // Night mode
          IconButton(
            icon: Icon(
              _isNightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: _isNightMode ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: () => setState(() => _isNightMode = !_isNightMode),
          ),
          // Download
          if (_localPath == null && !isFolder && !isLocalOnly)
            IconButton(
              icon: _isDownloading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _remainingTime,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isNightMode
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: _downloadProgress,
                            strokeWidth: 2,
                            color: _isNightMode
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.download_rounded),
              tooltip: 'تحميل للقراءة بدون إنترنت',
              onPressed: _isDownloading ? null : _downloadPdf,
            ),
          if (isFolder || (!isLocalOnly && widget.pdfUrl.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'فتح في المتصفح',
              onPressed: () => _launchUrl(widget.pdfUrl),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isFolder
                ? _buildFolderView()
                : Stack(
                    children: [
                      GestureDetector(onTap: _toggleToolbar, child: _buildPdfView()),
                      // Download progress bar
                      if (_isDownloading)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.transparent,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      // Bottom navigation bar
                      if (_isLoaded && _totalPages > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: FadeTransition(
                            opacity: _toolbarAnim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(_toolbarAnim),
                              child: _buildBottomBar(),
                            ),
                          ),
                        ),
                      // Bookmarks panel
                      if (_showBookmarks)
                        Positioned(
                          top: 80,
                          right: 0,
                          bottom: 0,
                          width: 200,
                          child: _buildBookmarksPanel(),
                        ),
                    ],
                  ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _isNightMode
                ? const Color(0xFF1A1A2E).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: _isNightMode ? Colors.white12 : Colors.black12,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Prev page
                IconButton(
                  onPressed: _currentPage > 1
                      ? () => _pdfViewerController.previousPage()
                      : null,
                  icon: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _isNightMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                // Slider
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: _isNightMode
                          ? Colors.white24
                          : Colors.black12,
                      thumbColor: AppTheme.primaryColor,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _currentPage.toDouble().clamp(
                        1,
                        _totalPages.toDouble(),
                      ),
                      min: 1,
                      max: _totalPages.toDouble(),
                      divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                      onChanged: (val) {
                        _pdfViewerController.jumpToPage(val.round());
                      },
                    ),
                  ),
                ),
                // Next page
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () => _pdfViewerController.nextPage()
                      : null,
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: _isNightMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                // Page counter
                GestureDetector(
                  onTap: _showPageJumpDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_currentPage/$_totalPages',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarksPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: _isNightMode
                ? const Color(0xFF1A1A2E).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            border: Border(
              left: BorderSide(
                color: _isNightMode ? Colors.white12 : Colors.black12,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bookmarks_rounded,
                      color: AppTheme.secondaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'علاماتي',
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showBookmarks = false),
                      child: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: _bookmarks
                      .map(
                        (page) => ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$page',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          ),
                          title: Text(
                            'صفحة $page',
                            style: GoogleFonts.tajawal(fontSize: 13),
                          ),
                          trailing: GestureDetector(
                            onTap: () => _toggleBookmark(page),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                          onTap: () {
                            _pdfViewerController.jumpToPage(page);
                            setState(() => _showBookmarks = false);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open_rounded, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'هذا الرابط يحتوي على مجلد ملفات',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم فتحه في المتصفح الخارجي',
            style: GoogleFonts.tajawal(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _launchUrl(widget.pdfUrl),
            icon: const Icon(Icons.open_in_new),
            label: Text(
              'فتح المجلد',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    Widget pdfWidget;

    if (_localPath != null) {
      pdfWidget = SfPdfViewer.file(
        File(_localPath!),
        controller: _pdfViewerController,
        key: _pdfViewerKey,
        canShowScrollHead: false,
        initialPageNumber: _currentPage,
        onPageChanged: (details) {
          setState(() => _currentPage = details.newPageNumber);
          _saveCurrentPage(details.newPageNumber);
        },
        onDocumentLoaded: (details) {
          setState(() {
            _totalPages = details.document.pages.count;
            _isLoaded = true;
          });
          // Jump to last saved page after load
          if (_currentPage > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pdfViewerController.jumpToPage(_currentPage);
            });
          }
        },
      );
    } else if (widget.pdfUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'الملف غير متاح',
              style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      pdfWidget = SfPdfViewer.network(
        _processedUrl,
        controller: _pdfViewerController,
        key: _pdfViewerKey,
        canShowScrollHead: false,
        initialPageNumber: _currentPage,
        onPageChanged: (details) {
          setState(() => _currentPage = details.newPageNumber);
          _saveCurrentPage(details.newPageNumber);
        },
        onDocumentLoaded: (details) {
          setState(() {
            _totalPages = details.document.pages.count;
            _isLoaded = true;
          });
          if (_currentPage > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pdfViewerController.jumpToPage(_currentPage);
            });
          }
        },
        onDocumentLoadFailed: (details) {
          if (mounted) {
            AppNotification.show(
              context,
              'فشل فتح الملف، جرب فتحه في المتصفح',
              isError: true,
            );
          }
        },
      );
    }

    if (_isNightMode) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: pdfWidget,
      );
    }

    return pdfWidget;
  }
}
