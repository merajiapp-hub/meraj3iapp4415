// lib/screens/results/pdf_preview_screen.dart
// شاشة معاينة ملف PDF قبل التنزيل النهائي — v1.0
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/result_pdf_file.dart';
import '../../providers/downloads_provider.dart';
import '../../services/results_service.dart';
import '../../services/school_pdf_service.dart';
import '../../services/result_pdf_service.dart';
import '../../theme/app_theme.dart';

class PdfPreviewScreen extends StatefulWidget {
  /// بيانات القائمة لإنشاء PDF
  final List<StudentResult> students;
  final String listTitle;
  final String listType;
  final String competitionTitle;
  final ExamType examType;
  final double maxScore;
  final double passScore;
  
  // خاص بالقوائم
  final int totalCount;
  final int passedCount;
  final int failedCount;
  final int absentCount;
  final int expelledCount;
  final int complementaryCount;
  final String filterWilaya;
  final String filterCenter;
  final String filterSchool;
  final String filterBranch;

  // خاص ببطاقة الطالب الفردية
  final StudentResult? singleStudent;
  final String? scoreLabel;
  final int? rankNational;
  final int? rankWilaya;
  final int? rankCenter;
  final int? rankSchool;

  const PdfPreviewScreen({
    super.key,
    required this.students,
    required this.listTitle,
    required this.listType,
    required this.competitionTitle,
    required this.examType,
    required this.maxScore,
    required this.passScore,
    this.totalCount = 0,
    this.passedCount = 0,
    this.failedCount = 0,
    this.absentCount = 0,
    this.expelledCount = 0,
    this.complementaryCount = 0,
    this.filterWilaya = '',
    this.filterCenter = '',
    this.filterSchool = '',
    this.filterBranch = '',
    this.singleStudent,
    this.scoreLabel,
    this.rankNational,
    this.rankWilaya,
    this.rankCenter,
    this.rankSchool,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  // مراحل المعاينة
  _PreviewState _state = _PreviewState.generating;
  String? _previewPath;   // مسار ملف مؤقت للمعاينة
  String? _errorMessage;
  double _progress = 0;
  ResultPdfFile? _savedFile;

  // حالة التنزيل
  bool _isSaving = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  @override
  void dispose() {
    // حذف ملف المعاينة المؤقت إذا لم يُحفظ
    if (_previewPath != null && !_isSaved) {
      final f = File(_previewPath!);
      if (f.existsSync()) f.deleteSync();
    }
    super.dispose();
  }

  Future<void> _generatePreview() async {
    setState(() {
      _state = _PreviewState.generating;
      _progress = 0.1;
    });

    try {
      setState(() => _progress = 0.35);

      dynamic result;

      if (widget.listType == 'student' && widget.singleStudent != null) {
        result = await ResultPdfService.buildAndSave(
          student: widget.singleStudent!,
          examType: widget.examType,
          competitionTitle: widget.competitionTitle,
          scoreLabel: widget.scoreLabel ?? 'المعدل',
          maxScore: widget.maxScore,
          rankNational: widget.rankNational,
          rankWilaya: widget.rankWilaya,
          rankCenter: widget.rankCenter,
          rankSchool: widget.rankSchool,
        );
      } else {
        result = await SchoolPdfService.buildAndSave(
          students: widget.students,
          listTitle: widget.listTitle,
          listType: widget.listType,
          competitionTitle: widget.competitionTitle,
          examType: widget.examType,
          maxScore: widget.maxScore,
          passScore: widget.passScore,
          totalCount: widget.totalCount,
          passedCount: widget.passedCount,
          failedCount: widget.failedCount,
          absentCount: widget.absentCount,
          expelledCount: widget.expelledCount,
          complementaryCount: widget.complementaryCount,
          filterWilaya: widget.filterWilaya,
          filterCenter: widget.filterCenter,
          filterSchool: widget.filterSchool,
          filterBranch: widget.filterBranch,
        );
      }

      setState(() => _progress = 0.85);

      if (!result.success) {
        setState(() {
          _state = _PreviewState.error;
          _errorMessage = result.errorMessage ?? 'تعذر إنشاء ملف المعاينة';
        });
        return;
      }

      setState(() {
        _previewPath = result.filePath;
        _savedFile = result.pdfFile;
        _progress = 1.0;
        _state = _PreviewState.ready;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _PreviewState.error;
          _errorMessage = 'خطأ غير متوقع: $e';
        });
      }
    }
  }

  Future<void> _confirmAndSave() async {
    if (_savedFile == null || _previewPath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text('تنزيل الملف؟', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(
          'سيتم حفظ ملف PDF على جهازك وإضافته إلى تنزيلات MERAJ3I.',
          style: GoogleFonts.tajawal(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: Text('تنزيل', style: GoogleFonts.tajawal()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    // الملف مبني مسبقاً، فقط نضيفه للـ Provider
    final provider = Provider.of<DownloadsProvider>(context, listen: false);
    final added = await provider.addResultPdf(_savedFile!);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (added) {
      setState(() => _isSaved = true);
      _showSuccessDialog();
    } else {
      _showErrorSnackbar('تعذر حفظ الملف — حاول مجدداً');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم الحفظ بنجاح ✅',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.listTitle} — ${widget.competitionTitle}',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'الملف محفوظ ويمكنك العثور عليه في صفحة التنزيلات.',
              style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_savedFile != null) {
                await SharePlus.instance.share(ShareParams(
                  text: '📊 ${widget.listTitle} — ${widget.competitionTitle}\n\nمن تطبيق مراجعي',
                  files: [XFile(_savedFile!.localPath, mimeType: 'application/pdf')],
                  subject: widget.listTitle,
                ));
              }
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text('مشاركة', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_savedFile != null) {
                await OpenFilex.open(_savedFile!.localPath);
              }
            },
            icon: const Icon(Icons.folder_open_rounded, size: 18),
            label: Text('فتح الملف', style: GoogleFonts.tajawal()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: GoogleFonts.tajawal())),
        ]),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          'معاينة — ${widget.listTitle}',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        elevation: 0,
        actions: [
          if (_state == _PreviewState.ready && !_isSaved)
            TextButton.icon(
              onPressed: _isSaving ? null : _confirmAndSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    )
                  : const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
              label: Text(
                _isSaving ? 'يُحفظ...' : 'تنزيل',
                style: GoogleFonts.tajawal(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (_isSaved)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600),
            ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: _state == _PreviewState.ready
          ? _buildBottomBar(isDark)
          : null,
    );
  }

  Widget _buildBody(bool isDark) {
    switch (_state) {
      case _PreviewState.generating:
        return _buildGeneratingState(isDark);
      case _PreviewState.error:
        return _buildErrorState(isDark);
      case _PreviewState.ready:
        return _buildPdfViewer();
    }
  }

  Widget _buildGeneratingState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 32),
            Text(
              _progress < 0.5 ? 'جارٍ إنشاء ملف النتائج...' : 'جارٍ تجهيز المعاينة...',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 10,
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(_progress * 100).toInt()}%',
              style: GoogleFonts.outfit(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'عدد النتائج: ${widget.students.length}',
              style: GoogleFonts.tajawal(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 72, color: Colors.red.shade400),
            const SizedBox(height: 20),
            Text(
              'تعذر إنشاء المعاينة',
              style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'خطأ غير معروف',
              style: GoogleFonts.tajawal(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _generatePreview,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (_previewPath == null) return const SizedBox.shrink();
    return SfPdfViewer.file(
      File(_previewPath!),
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!_isSaved) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_previewPath != null) {
                    await SharePlus.instance.share(ShareParams(
                      text: '📊 ${widget.listTitle} — ${widget.competitionTitle}',
                      files: [XFile(_previewPath!, mimeType: 'application/pdf')],
                    ));
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text('مشاركة', style: GoogleFonts.tajawal()),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _confirmAndSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.download_rounded, size: 20),
                label: Text(
                  _isSaving ? 'جارٍ الحفظ...' : '⬇️  تنزيل PDF',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (_savedFile != null) {
                    await OpenFilex.open(_savedFile!.localPath);
                  }
                },
                icon: const Icon(Icons.folder_open_rounded, size: 20),
                label: Text('فتح الملف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (_savedFile != null) {
                    await SharePlus.instance.share(ShareParams(
                      text: '📊 ${widget.listTitle} — ${widget.competitionTitle}',
                      files: [XFile(_savedFile!.localPath, mimeType: 'application/pdf')],
                    ));
                  }
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: Text('مشاركة', style: GoogleFonts.tajawal()),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.green.shade600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _PreviewState { generating, ready, error }
