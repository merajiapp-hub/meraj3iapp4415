// services/school_pdf_service.dart
// PDF النتائج الاحترافي — مطابق للتصميم المرجعي
// v6.0.0 — RTL + Arabic Shaping + Header مطابق للصورة

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;
import '../services/results_service.dart';
import '../models/result_pdf_file.dart';

class PdfBuildResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final ResultPdfFile? pdfFile;

  PdfBuildResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.pdfFile,
  });
}

class SchoolPdfService {
  // ── ألوان التصميم المرجعي ──────────────────────────────
  static final _darkGreen = PdfColor(15, 60, 30);      // #0F3C1E — رأس الجدول
  static final _lightGreen = PdfColor(210, 230, 210);  // #D2E6D2 — صفوف زوجية
  static final _white = PdfColor(255, 255, 255);
  static final _black = PdfColor(0, 0, 0);
  static final _separatorBlue = PdfColor(30, 80, 110); // الفاصل الأزرق
  static final _textGray = PdfColor(80, 80, 80);

  /// Helper to shape Arabic text and apply Bidi logical-to-visual
  static String _ar(String text) {
    if (text.isEmpty) return text;
    try {
      final reshaped = ArabicReshaper.instance.reshape(text);
      return String.fromCharCodes(bidi.logicalToVisual(reshaped));
    } catch (_) {
      return text; // fallback
    }
  }

  static Future<Directory> _getResultsDir() async {
    Directory? dir;
    if (Platform.isAndroid) {
      final candidates = [
        '/storage/emulated/0/Download/Meraj3i_Results',
        '/storage/emulated/0/Documents/Meraj3i_Results',
      ];
      for (final path in candidates) {
        try {
          final d = Directory(path);
          if (!d.existsSync()) d.createSync(recursive: true);
          final testFile = File('${d.path}/.write_test');
          testFile.writeAsBytesSync([0]);
          testFile.deleteSync();
          dir = d;
          break;
        } catch (_) {}
      }
    }
    if (dir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      dir = Directory('${appDir.path}/Meraj3i_Results');
      if (!dir.existsSync()) dir.createSync(recursive: true);
    }
    return dir;
  }

  static String _safeFileName(String input) {
    return input
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, input.length.clamp(0, 40));
  }

  static Future<PdfBuildResult> buildAndSave({
    required List<StudentResult> students,
    required String listTitle,
    required String listType,
    required String competitionTitle,
    required ExamType examType,
    required double maxScore,
    required double passScore,
    required int totalCount,
    required int passedCount,
    required int failedCount,
    int absentCount = 0,
    int expelledCount = 0,
    int complementaryCount = 0,
    String filterWilaya = '',
    String filterCenter = '',
    String filterSchool = '',
    String filterBranch = '',
  }) async {
    try {
      final saveDir = await _getResultsDir();
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final safeName = _safeFileName(listTitle);
      final safeComp = _safeFileName(competitionTitle);
      final fileName = 'meraj3i_${safeName}_${safeComp}_$stamp.pdf';
      final filePath = '${saveDir.path}/$fileName';

      final bytes = await _buildListPdf(
        students: students,
        competitionTitle: competitionTitle,
        examType: examType,
        totalCount: totalCount,
        passedCount: passedCount,
        failedCount: failedCount,
        filterWilaya: filterWilaya,
        filterCenter: filterCenter,
        filterSchool: filterSchool,
        filterBranch: filterBranch,
        listTitle: listTitle,
      );

      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!file.existsSync() || file.lengthSync() == 0) {
        if (file.existsSync()) await file.delete();
        return PdfBuildResult(success: false, errorMessage: 'فشل حفظ الملف.');
      }

      final sizeMb = file.lengthSync() / (1024 * 1024);
      return PdfBuildResult(
        success: true,
        filePath: filePath,
        pdfFile: ResultPdfFile(
          id: '${now.millisecondsSinceEpoch}',
          fileName: fileName,
          localPath: filePath,
          title: '$listTitle — $competitionTitle',
          competition: competitionTitle,
          listType: listType,
          fileSizeMb: sizeMb,
          savedAt: now,
          studentCount: students.length,
        ),
      );
    } catch (e) {
      return PdfBuildResult(success: false, errorMessage: 'تعذر إنشاء PDF: $e');
    }
  }

  /// بناء PDF مطابق للصورة المرجعية
  static Future<List<int>> _buildListPdf({
    required List<StudentResult> students,
    required String competitionTitle,
    required ExamType examType,
    required int totalCount,
    required int passedCount,
    required int failedCount,
    required String filterWilaya,
    required String filterCenter,
    required String filterSchool,
    required String filterBranch,
    required String listTitle,
  }) async {
    final document = PdfDocument();

    // ── إعداد الصفحة A4 عمودي ──────────────────────────────
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.left = 20;
    document.pageSettings.margins.right = 20;
    document.pageSettings.margins.top = 20;
    document.pageSettings.margins.bottom = 20;

    // ── تحميل الخطوط العربية (مضمّنة في PDF) ──────────────
    final regularData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
    final regularBytes = regularData.buffer.asUint8List();
    final boldBytes = boldData.buffer.asUint8List();

    // خطوط بأحجام مختلفة
    final fontTitle = PdfTrueTypeFont(boldBytes, 26);   // MERAJ3I
    final fontDate = PdfTrueTypeFont(boldBytes, 22);    // التاريخ
    final fontInfo = PdfTrueTypeFont(boldBytes, 10);    // معلومات الرأس
    final fontHeader = PdfTrueTypeFont(boldBytes, 10);  // رأس الجدول
    final fontRow = PdfTrueTypeFont(regularBytes, 9);   // صفوف البيانات
    final fontPage = PdfTrueTypeFont(regularBytes, 8);  // أرقام الصفحات

    // ── تحميل الشعار ──────────────────────────────────────
    PdfBitmap? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = PdfBitmap(logoData.buffer.asUint8List());
    } catch (_) {}

    // ── تنسيق RTL الأساسي ──────────────────────────────────
    final rtlRight = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      textDirection: PdfTextDirection.leftToRight,
      lineAlignment: PdfVerticalAlignment.middle,
    );
    final rtlCenter = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      textDirection: PdfTextDirection.leftToRight,
      lineAlignment: PdfVerticalAlignment.middle,
    );
    final ltrRight = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    // ── التاريخ ────────────────────────────────────────────
    final now = DateTime.now();
    final dateStr =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    // ── الصفحة الأولى ──────────────────────────────────────
    final firstPage = document.pages.add();
    final w = firstPage.getClientSize().width;

    double y = 0;

    // ══════════════════════════════════════════════════════
    // HEADER — رأس الصفحة المطابق للصورة
    // يسار: الشعار + MERAJ3I (عمودي)
    // يمين: MERAJ3I (اسم) + التاريخ (تحته)
    // ══════════════════════════════════════════════════════

    // الشعار في اليسار
    if (logoImage != null) {
      firstPage.graphics.drawImage(
        logoImage,
        Rect.fromLTWH(5, y, 65, 65),
      );
    }

    // "MERAJ3I" على اليمين — كبير وعريض
    firstPage.graphics.drawString(
      'MERAJ3I',
      fontTitle,
      brush: PdfSolidBrush(_black),
      bounds: Rect.fromLTWH(w - 220, y + 4, 215, 32),
      format: ltrRight,
    );

    // التاريخ تحت الاسم على اليمين
    firstPage.graphics.drawString(
      dateStr,
      fontDate,
      brush: PdfSolidBrush(_black),
      bounds: Rect.fromLTWH(w - 220, y + 38, 215, 28),
      format: ltrRight,
    );

    y += 75;

    // ── الفاصل الأزرق ─────────────────────────────────────
    firstPage.graphics.drawRectangle(
      brush: PdfSolidBrush(_separatorBlue),
      bounds: Rect.fromLTWH(0, y, w, 2),
    );
    y += 6;

    // ══════════════════════════════════════════════════════
    // سطر المعلومات: اسم المسابقة | الولاية | عدد المترشحين | الناجحون/الراسبون
    // مطابق للصورة: 4 أعمدة من اليمين لليسار
    // ══════════════════════════════════════════════════════
    const infoH = 16.0;
    double infoY = y;

    // العمود 1 (أقصى اليمين) — اسم المسابقة
    if (competitionTitle.isNotEmpty) {
      firstPage.graphics.drawString(
        _ar(competitionTitle),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w - 200, infoY, 195, infoH),
        format: rtlRight,
      );
    }

    // المركز أو المدرسة تحت اسم المسابقة
    if (filterCenter.isNotEmpty || filterSchool.isNotEmpty) {
      firstPage.graphics.drawString(
        _ar(filterCenter.isNotEmpty ? filterCenter : filterSchool),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w - 200, infoY + infoH, 195, infoH),
        format: rtlRight,
      );
    }

    // القسم/الشعبة
    if (filterBranch.isNotEmpty) {
      firstPage.graphics.drawString(
        _ar(filterBranch),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w - 200, infoY + infoH * 2, 195, infoH),
        format: rtlRight,
      );
    }

    // العمود 2 — الولاية
    if (filterWilaya.isNotEmpty) {
      firstPage.graphics.drawString(
        _ar(filterWilaya),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w / 2 + 10, infoY + infoH, 140, infoH),
        format: rtlRight,
      );
    }

    // العمود 3 — عدد المترشحين
    if (totalCount > 0) {
      firstPage.graphics.drawString(
        _ar('عدد المترشحين: $totalCount'),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(w / 4 + 10, infoY + infoH, 130, infoH),
        format: rtlRight,
      );
    }

    // العمود 4 (أقصى اليسار) — الناجحون والراسبون
    if (passedCount > 0 || failedCount > 0) {
      firstPage.graphics.drawString(
        _ar('الناجحون: $passedCount    الراسبون: $failedCount'),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(0, infoY + infoH, w / 4 + 40, infoH),
        format: rtlRight,
      );
    }

    // listTitle إذا كان مختلفاً
    if (listTitle.isNotEmpty && listTitle != competitionTitle) {
      firstPage.graphics.drawString(
        _ar(listTitle),
        fontInfo,
        brush: PdfSolidBrush(_textGray),
        bounds: Rect.fromLTWH(0, infoY + infoH * 2, w / 4 + 40, infoH),
        format: rtlRight,
      );
    }

    y += infoH * 3 + 6;

    // ══════════════════════════════════════════════════════
    // الجدول — مطابق للصورة
    // ══════════════════════════════════════════════════════

    // تحديد عمود "المجموع أو المعدل حسب المسابقة" حسب النوع
    final scoreColLabel = examType == ExamType.concours
        ? 'المجموع أو المعدل حسب\nالمسابقة'
        : 'المجموع أو المعدل حسب\nالمسابقة';

    _drawTableWithPagination(
      document: document,
      students: students,
      examType: examType,
      firstPage: firstPage,
      startY: y,
      regularFont: fontRow,
      boldFont: fontHeader,
      pageFont: fontPage,
      scoreColLabel: scoreColLabel,
      rtlCenter: rtlCenter,
    );

    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  /// رسم الجدول مع دعم الصفحات المتعددة وتكرار الرأس
  static void _drawTableWithPagination({
    required PdfDocument document,
    required List<StudentResult> students,
    required ExamType examType,
    required PdfPage firstPage,
    required double startY,
    required PdfFont regularFont,
    required PdfFont boldFont,
    required PdfFont pageFont,
    required String scoreColLabel,
    required PdfStringFormat rtlCenter,
  }) {
    final w = firstPage.getClientSize().width;
    
    // ── عرض الأعمدة المطابق للصورة (5 أعمدة RTL) ──────────
    // الترتيب من اليمين: الرقم | رقم الجلوس | الاسم | المجموع/المعدل | النتيجة
    const colWidths = <double>[35.0, 65.0, 0, 100.0, 55.0]; // 0 = يُحسب تلقائياً
    final nameColWidth = w - colWidths[0] - colWidths[1] - colWidths[3] - colWidths[4];

    final headers = <String>[
      'الرقم',
      'رقم الجلوس',
      'الاسم',
      scoreColLabel,
      'النتيجة',
    ];
    final widths = <double>[colWidths[0], colWidths[1], nameColWidth, colWidths[3], colWidths[4]];

    const rowH = 22.0;
    const headerH = 28.0; // رأس أعلى قليلاً للنص الطويل

    PdfPage currentPage = firstPage;
    double y = startY;
    int pageNum = 1;
    final totalPages = _estimatePageCount(students.length, firstPage.getClientSize().height, startY, headerH, rowH);

    // رسم رأس الجدول
    void drawHeader(PdfPage pg, double cy) {
      pg.graphics.drawRectangle(
        brush: PdfSolidBrush(_darkGreen),
        bounds: Rect.fromLTWH(0, cy, w, headerH),
      );

      // رسم الأعمدة من اليمين لليسار (RTL)
      double cx = w;
      for (int i = 0; i < headers.length; i++) {
        cx -= widths[i];
        // فاصل بين الأعمدة
        if (i < headers.length - 1) {
          pg.graphics.drawLine(
            PdfPen(_white, width: 0.5),
            Offset(cx, cy),
            Offset(cx, cy + headerH),
          );
        }
        pg.graphics.drawString(
          _ar(headers[i]),
          boldFont,
          brush: PdfSolidBrush(_white),
          bounds: Rect.fromLTWH(cx + 2, cy, widths[i] - 4, headerH),
          format: rtlCenter,
        );
      }
    }

    drawHeader(currentPage, y);
    y += headerH;

    // رسم الصفوف
    for (int i = 0; i < students.length; i++) {
      final s = students[i];

      // التحقق من الحاجة لصفحة جديدة
      if (y + rowH > currentPage.getClientSize().height - 24) {
        // رقم الصفحة في نهاية الصفحة الحالية
        _drawPageNumber(currentPage, pageFont, pageNum, totalPages);
        pageNum++;

        currentPage = document.pages.add();
        y = 20;
        drawHeader(currentPage, y);
        y += headerH;
      }

      // لون صف متبادل (أبيض / أخضر فاتح)
      final rowBg = i.isEven ? _lightGreen : _white;
      currentPage.graphics.drawRectangle(
        brush: PdfSolidBrush(rowBg),
        bounds: Rect.fromLTWH(0, y, w, rowH),
      );

      // بيانات الصف: [الرقم, رقم الجلوس, الاسم, المجموع/المعدل, النتيجة]
      final rowData = <String>[
        '${i + 1}',
        s.id,
        s.name.trim(), // الاسم كما هو بالضبط من المصدر
        s.score != null ? s.score!.toStringAsFixed(2) : '—',
        s.status.trim(),
      ];

      double cx = w;
      for (int j = 0; j < rowData.length; j++) {
        cx -= widths[j];

        // فاصل بين الأعمدة
        if (j < rowData.length - 1) {
          currentPage.graphics.drawLine(
            PdfPen(_white, width: 1),
            Offset(cx, y),
            Offset(cx, y + rowH),
          );
        }

        // الاسم (عمود 2) يحتاج RTL مع Arabic Shaping
        // باقي الأعمدة بالوسط
        final fmt = j == 2 // عمود الاسم
            ? PdfStringFormat(
                alignment: PdfTextAlignment.right,
                textDirection: PdfTextDirection.leftToRight,
                lineAlignment: PdfVerticalAlignment.middle,
              )
            : rtlCenter;

        currentPage.graphics.drawString(
          _ar(rowData[j]),
          regularFont,
          brush: PdfSolidBrush(_black),
          bounds: Rect.fromLTWH(cx + 3, y, widths[j] - 6, rowH),
          format: fmt,
        );
      }

      y += rowH;
    }

    // رقم الصفحة الأخيرة
    _drawPageNumber(currentPage, pageFont, pageNum, totalPages);
  }

  static int _estimatePageCount(int studentCount, double pageH, double startY, double headerH, double rowH) {
    final rowsFirstPage = ((pageH - startY - headerH - 24) / rowH).floor();
    if (studentCount <= rowsFirstPage) return 1;
    final rowsPerPage = ((pageH - 20 - headerH - 24) / rowH).floor();
    return 1 + ((studentCount - rowsFirstPage) / rowsPerPage).ceil();
  }

  static void _drawPageNumber(PdfPage page, PdfFont font, int pageNum, int totalPages) {
    final w = page.getClientSize().width;
    final h = page.getClientSize().height;
    page.graphics.drawString(
      _ar('صـ $pageNum / $totalPages'),
      font,
      brush: PdfSolidBrush(_textGray),
      bounds: Rect.fromLTWH(0, h - 18, w, 16),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        textDirection: PdfTextDirection.leftToRight,
      ),
    );
  }
}


