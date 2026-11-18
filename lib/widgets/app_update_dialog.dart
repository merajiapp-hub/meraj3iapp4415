import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_update_info.dart';
import '../services/app_update_service.dart';
import '../theme/app_theme.dart';

class AppUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final String currentVersion;
  final AppUpdateService service;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.currentVersion,
    required this.service,
  });

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _isDownloading = false;
  bool _isSuccess = false;
  String _stepMessage = 'جارٍ تجهيز التحديث...';
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;

  void _startUpdate() {
    setState(() {
      _isDownloading = true;
      _isSuccess = false;
      _progress = 0.0;
      _errorMessage = null;
      _stepMessage = 'جارٍ فحص وتنزيل التحديثات (Shorebird)...';
    });

    widget.service.performUpdate(
      apkUrl: widget.updateInfo.apkUrl,
      onProgress: (stepMsg, progress, received, total) {
        if (!mounted) return;
        setState(() {
          _stepMessage = stepMsg;
          _progress = progress;
          _receivedBytes = received;
          _totalBytes = total;
        });
      },
      onError: (error, {bool canOpenBrowser = true}) {
        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _errorMessage = error;
        });
      },
      onCompleted: ({bool requiresRestart = false}) {
        if (!mounted) return;
        setState(() {
          _isDownloading = false;
          _isSuccess = true;
          _progress = 1.0;
        });
      },
    );
  }

  void _cancelDownload() {
    widget.service.cancelDownload();
    setState(() {
      _isDownloading = false;
      _progress = 0.0;
    });
  }

  Future<void> _openBrowserDownload() async {
    final urlStr = widget.updateInfo.githubReleaseUrl ??
        (widget.updateInfo.apkUrl.isNotEmpty
            ? widget.updateInfo.apkUrl
            : 'https://github.com/merajiapp-hub/meraj3iapp4415/releases');

    try {
      final uri = Uri.parse(urlStr);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppUpdateDialog] Launch browser error: $e');
    }
  }

  void _restartApp() {
    SystemNavigator.pop();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderDivider = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE2E8F0);

    return PopScope(
      canPop: !widget.updateInfo.forceUpdate && !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surfaceColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            maxWidth: 430,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. رأس البطاقة (ثابت ومميز بالأعلى) ─────────────────
                _buildHeader(isDark),

                // ── 2. محتوى النافذة (مرن وقابل للتمرير لمنع أي تجاوز) ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: _isSuccess
                        ? _buildSuccessView(isDark)
                        : (_isDownloading
                            ? _buildDownloadingView(isDark)
                            : _buildNotesView(isDark)),
                  ),
                ),

                // ── 3. شريط الأزرار المثبت بالأسفل (دائماً ظاهر وواضح) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(top: BorderSide(color: borderDivider)),
                  ),
                  child: _buildActionButtons(isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'تحديث جديد متوفر!',
            style: GoogleFonts.cairo(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'الإصدار الجديد: v${widget.updateInfo.latestVersion}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.updateInfo.apkSize.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'الحجم: ${widget.updateInfo.apkSize}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// واجهة الميزات والتحديثات
  Widget _buildNotesView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              color: AppTheme.secondaryColor,
              size: 19,
            ),
            const SizedBox(width: 8),
            Text(
              'ما الجديد في هذا التحديث؟',
              style: GoogleFonts.cairo(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.updateInfo.releaseNotes.isEmpty
              ? [
                  Text(
                    '• تحسينات شاملة في الأداء والسرعة واستقرار التطبيق.',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ]
              : widget.updateInfo.releaseNotes
                  .map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note,
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                height: 1.35,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),

        // بطاقة الخطأ الأنيقة والواضحة (في حال حدوث أي خطأ)
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// واجهة عرض شريط التنزيل والتقدم
  Widget _buildDownloadingView(bool isDark) {
    final pct = (_progress * 100).clamp(0, 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_download_rounded,
              color: AppTheme.primaryColor,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _stepMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress >= 0 ? _progress : null,
              minHeight: 8,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _totalBytes > 0
                    ? '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}'
                    : 'جارٍ الاتصال بالخادم...',
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              Text(
                _progress >= 0 ? '$pct%' : '...',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// واجهة نجاح التحديث
  Widget _buildSuccessView(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'تم تثبيت التحديث بنجاح! 🎉',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تم تطبيق أحدث الميزات والإصلاحات بنجاح. أعد تشغيل التطبيق للاستمتاع بها فوراً.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// شريط أزرار الإجراءات (دائماً ظاهر وغير قابل للقص)
  Widget _buildActionButtons(bool isDark) {
    if (_isSuccess) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _restartApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.restart_alt_rounded, color: Colors.white, size: 20),
          label: Text(
            'إعادة تشغيل التطبيق لتطبيق التحديث',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (_isDownloading) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _cancelDownload,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            'إلغاء العملية',
            style: GoogleFonts.cairo(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الزر الأساسي: تحديث وتثبيت الآن
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            label: Text(
              'تحديث وتثبيت الآن',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // صف أزرار الخيارات الإضافية
        Row(
          children: [
            if (!widget.updateInfo.forceUpdate) ...[
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  child: Text(
                    'لاحقاً',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // زر التنزيل عبر المتصفح (متاح دائماً كخيار بديل)
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: _openBrowserDownload,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                ),
                icon: Icon(
                  Icons.open_in_browser_rounded,
                  size: 17,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
                label: Text(
                  'تنزيل عبر المتصفح',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
