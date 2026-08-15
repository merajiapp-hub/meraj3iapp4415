// services/school_pdf_service.dart — v3.0.0
// إنشاء PDF احترافي لقوائم النتائج مع حفظ دائم وتحقق كامل
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/results_service.dart';
import '../models/result_pdf_file.dart';

/// نتيجة عملية إنشاء PDF
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
  // ─── المجلد الرئيسي للحفظ ──────────────────────────────────────────────
  static Future<Directory> _getResultsDir() async {
    Directory? dir;

    if (Platform.isAndroid) {
      // أولوية: مجلد Downloads/Meraj3i_Results (مرئي للمستخدم)
      final candidates = [
        '/storage/emulated/0/Download/Meraj3i_Results',
        '/storage/emulated/0/Documents/Meraj3i_Results',
      ];
      for (final path in candidates) {
        try {
          final d = Directory(path);
          if (!d.existsSync()) d.createSync(recursive: true);
          // اختبار الكتابة
          final testFile = File('${d.path}/.write_test');
          testFile.writeAsBytesSync([0]);
          testFile.deleteSync();
          dir = d;
          break;
        } catch (_) {}
      }
    }

    // Fallback: مجلد التطبيق الداخلي (ثابت لا يُحذف)
    if (dir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      dir = Directory('${appDir.path}/Meraj3i_Results');
      if (!dir.existsSync()) dir.createSync(recursive: true);
    }

    return dir;
  }

  /// إنشاء اسم ملف آمن (بدون مسافات أو حروف خاصة)
  static String _safeFileName(String input) {
    return input
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .substring(0, input.length.clamp(0, 40));
  }

  // ─── الدالة الرئيسية: إنشاء وحفظ PDF وإرجاع النتيجة ──────────────────

  /// يبني ملف PDF ويحفظه ويرجع نتيجة مفصلة
  static Future<PdfBuildResult> buildAndSave({
    required List<StudentResult> students,
    required String listTitle,         // 'قائمة الناجحين' / 'قائمة الراسبين'
    required String listType,          // 'passed' / 'failed' / 'all'
    required String competitionTitle,  // اسم المسابقة
    required ExamType examType,
    required double maxScore,
    required double passScore,
    // إحصائيات المسابقة لعرضها في الرأس
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
      // إنشاء مجلد الحفظ
      final saveDir = await _getResultsDir();

      // اسم الملف
      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final safeName = _safeFileName(listTitle);
      final safeComp = _safeFileName(competitionTitle);
      final fileName = 'meraj3i_${safeName}_${safeComp}_$stamp.pdf';
      final filePath = '${saveDir.path}/$fileName';

      // إنشاء مستند PDF
      final bytes = await _buildListPdf(
        students: students,
        listTitle: listTitle,
        competitionTitle: competitionTitle,
        examType: examType,
        maxScore: maxScore,
        passScore: passScore,
        totalCount: totalCount,
        passedCount: passedCount,
        failedCount: failedCount,
        absentCount: absentCount,
        expelledCount: expelledCount,
        complementaryCount: complementaryCount,
        filterWilaya: filterWilaya,
        filterCenter: filterCenter,
        filterSchool: filterSchool,
        filterBranch: filterBranch,
      );

      // كتابة الملف
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // ── التحقق الإلزامي من نجاح الحفظ ──
      if (!file.existsSync()) {
        return PdfBuildResult(success: false, errorMessage: 'فشل إنشاء الملف على الجهاز');
      }
      final fileSize = file.lengthSync();
      if (fileSize == 0) {
        await file.delete();
        return PdfBuildResult(success: false, errorMessage: 'الملف المُنشأ فارغ — حاول مجدداً');
      }

      final sizeMb = fileSize / (1024 * 1024);
      final pdfFile = ResultPdfFile(
        id: '${now.millisecondsSinceEpoch}',
        fileName: fileName,
        localPath: filePath,
        title: '$listTitle — $competitionTitle',
        competition: competitionTitle,
        listType: listType,
        fileSizeMb: sizeMb,
        savedAt: now,
        studentCount: students.length,
      );

      return PdfBuildResult(
        success: true,
        filePath: filePath,
        pdfFile: pdfFile,
      );
    } catch (e) {
      return PdfBuildResult(success: false, errorMessage: 'تعذر إنشاء PDF: $e');
    }
  }

  // ─── بناء محتوى PDF ────────────────────────────────────────────────────

  static Future<List<int>> _buildListPdf({
    required List<StudentResult> students,
    required String listTitle,
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
    final document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 32;
    document.pageSettings.orientation = PdfPageOrientation.portrait;

    // ─── تحميل الخطوط العربية ───────────────────────────────────────────
    final ByteData regularData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final ByteData boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
    final Uint8List regularBytes = regularData.buffer.asUint8List();
    final Uint8List boldBytes = boldData.buffer.asUint8List();

    final regularFont = PdfTrueTypeFont(regularBytes, 10);
    final boldFont = PdfTrueTypeFont(boldBytes, 11);
    final titleFont = PdfTrueTypeFont(boldBytes, 16);
    final subtitleFont = PdfTrueTypeFont(boldBytes, 12);
    final smallFont = PdfTrueTypeFont(regularBytes, 9);

    // ─── ألوان ───────────────────────────────────────────────────────────
    final primaryColor = PdfColor(13, 148, 136);     // #0D9488
    final darkColor = PdfColor(15, 23, 42);           // #0F172A
    final passedColor = PdfColor(22, 163, 74);        // #16A34A
    final failedColor = PdfColor(239, 68, 68);        // #EF4444
    final lightGray = PdfColor(241, 245, 249);        // #F1F5F9
    final headerBg = listTitle.contains('الناجح') ? passedColor : failedColor;

    // ─── صياغة RTL ───────────────────────────────────────────────────────
    final centerRtl = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      textDirection: PdfTextDirection.rightToLeft,
      lineAlignment: PdfVerticalAlignment.middle,
    );
    // ─── الصفحة الأولى ───────────────────────────────────────────────────
    final page = document.pages.add();
    final w = page.getClientSize().width;
    double y = 0;

    // HEADER: رأس الصفحة
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(0, y, w, 72),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(headerBg),
      bounds: Rect.fromLTWH(0, y + 68, w, 4),
    );
    page.graphics.drawString(
      'MERAJ3I — مراجعي',
      PdfTrueTypeFont(boldBytes, 20),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(0, y + 12, w, 30),
      format: centerRtl,
    );
    page.graphics.drawString(
      'تطبيق MERAJ3I — المنصة الطلابية',
      PdfTrueTypeFont(regularBytes, 9),
      brush: PdfSolidBrush(PdfColor(180, 210, 210)),
      bounds: Rect.fromLTWH(0, y + 44, w, 18),
      format: centerRtl,
    );
    y += 80;

    // عنوان القائمة
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(headerBg),
      bounds: Rect.fromLTWH(0, y, w, 36),
    );
    page.graphics.drawString(
      listTitle,
      titleFont,
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(0, y, w, 36),
      format: centerRtl,
    );
    y += 44;

    // اسم المسابقة
    page.graphics.drawString(
      competitionTitle,
      subtitleFont,
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(0, y, w, 22),
      format: centerRtl,
    );
    y += 28;

    // معلومات الفلترة إن وجدت
    final filterParts = <String>[];
    if (filterBranch.isNotEmpty) filterParts.add('الشعبة: $filterBranch');
    if (filterWilaya.isNotEmpty) filterParts.add('الولاية: $filterWilaya');
    if (filterCenter.isNotEmpty) filterParts.add('المركز: $filterCenter');
    if (filterSchool.isNotEmpty) filterParts.add('المدرسة: $filterSchool');
    if (filterParts.isNotEmpty) {
      page.graphics.drawString(
        filterParts.join('  |  '),
        smallFont,
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(0, y, w, 18),
        format: centerRtl,
      );
      y += 22;
    }

    // خط فاصل
    page.graphics.drawLine(
      PdfPen(primaryColor, width: 1),
      Offset(0, y),
      Offset(w, y),
    );
    y += 12;

    // ─── إحصائيات المسابقة في صناديق ────────────────────────────────────
    final passRate = totalCount > 0 ? (passedCount / totalCount * 100) : 0.0;
    final statsData = <_StatBox>[
      _StatBox('المترشحون', '$totalCount', PdfColor(59, 130, 246)),
      _StatBox('الناجحون', '$passedCount', passedColor),
      _StatBox('الراسبون', '$failedCount', failedColor),
      _StatBox('نسبة النجاح', '${passRate.toStringAsFixed(1)}%', primaryColor),
    ];
    if (absentCount > 0) {
      statsData.add(_StatBox('الغائبون', '$absentCount', PdfColor(107, 114, 128)));
    }
    if (expelledCount > 0) {
      statsData.add(_StatBox('المطرودون', '$expelledCount', PdfColor(139, 92, 246)));
    }
    if (examType == ExamType.bac && complementaryCount > 0) {
      statsData.add(_StatBox('التكميلي', '$complementaryCount', PdfColor(234, 179, 8)));
    }

    // رسم صناديق الإحصائيات
    final boxW = (w - (statsData.length - 1) * 6) / statsData.length;
    for (int i = 0; i < statsData.length; i++) {
      final stat = statsData[i];
      final bx = i * (boxW + 6);
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(lightGray),
        pen: PdfPen(stat.color, width: 1.5),
        bounds: Rect.fromLTWH(bx, y, boxW, 48),
      );
      page.graphics.drawString(
        stat.value,
        PdfTrueTypeFont(boldBytes, 14),
        brush: PdfSolidBrush(stat.color),
        bounds: Rect.fromLTWH(bx, y + 6, boxW, 22),
        format: centerRtl,
      );
      page.graphics.drawString(
        stat.label,
        PdfTrueTypeFont(regularBytes, 8),
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(bx, y + 28, boxW, 16),
        format: centerRtl,
      );
    }
    y += 58;

    // تاريخ التصدير
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  —  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    page.graphics.drawString(
      'تاريخ التصدير: $dateStr    |    عدد النتائج: ${students.length}',
      smallFont,
      brush: PdfSolidBrush(PdfColor(148, 163, 184)),
      bounds: Rect.fromLTWH(0, y, w, 16),
      format: centerRtl,
    );
    y += 22;

    // ─── بناء جدول النتائج ───────────────────────────────────────────────
    _drawResultsTable(
      document: document,
      students: students,
      examType: examType,
      maxScore: maxScore,
      regularFont: regularFont,
      boldFont: boldFont,
      smallFont: smallFont,
      primaryColor: primaryColor,
      darkColor: darkColor,
      lightGray: lightGray,
      passedColor: passedColor,
      failedColor: failedColor,
      regularBytes: regularBytes,
      boldBytes: boldBytes,
      firstPage: page,
      startY: y,
    );

    // ─── تذييل كل الصفحات ────────────────────────────────────────────────
    _addFooter(document, regularFont, primaryColor, lightGray);

    final List<int> bytes = await document.save();
    document.dispose();
    return bytes;
  }

  // ─── رسم الجدول المتعدد الصفحات ─────────────────────────────────────────

  static void _drawResultsTable({
    required PdfDocument document,
    required List<StudentResult> students,
    required ExamType examType,
    required double maxScore,
    required PdfFont regularFont,
    required PdfFont boldFont,
    required PdfFont smallFont,
    required PdfColor primaryColor,
    required PdfColor darkColor,
    required PdfColor lightGray,
    required PdfColor passedColor,
    required PdfColor failedColor,
    required Uint8List regularBytes,
    required Uint8List boldBytes,
    required PdfPage firstPage,
    required double startY,
  }) {
    final bool hasBranch = students.any((s) => s.branch.isNotEmpty);
    final bool hasCenter = students.any((s) => s.center.isNotEmpty);
    final bool hasSchool = students.any((s) => s.school.isNotEmpty);
    final bool hasScore = students.any((s) => s.score != null);
    final scoreLabel = examType == ExamType.concours ? 'المجموع' : 'المعدل';
    final scoreMax = maxScore == 200.0 ? '200' : '20';

    // تحديد الأعمدة بشكل ديناميكي
    final columns = <_TableColumn>[];
    columns.add(_TableColumn('#', 30));
    columns.add(_TableColumn('الاسم الكامل', 130));
    columns.add(_TableColumn('الرقم', 65));
    if (hasBranch) columns.add(_TableColumn('الشعبة', 60));
    if (hasCenter || hasSchool) columns.add(_TableColumn(hasSchool ? 'المدرسة' : 'المركز', 90));
    columns.add(_TableColumn('الولاية', 55));
    if (hasScore) columns.add(_TableColumn('$scoreLabel/$scoreMax', 55));
    columns.add(_TableColumn('الحالة', 55));

    final w = firstPage.getClientSize().width;
    // إعادة حساب عرض الأعمدة لتملأ العرض
    final totalFixed = columns.fold<double>(0, (sum, c) => sum + c.width);
    final scale = totalFixed > 0 ? w / totalFixed : 1.0;

    final headerH = 28.0;
    final rowH = 24.0;
    const bottomMargin = 60.0; // مكان للتذييل

    final rowRtl = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      textDirection: PdfTextDirection.rightToLeft,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    PdfPage currentPage = firstPage;
    double y = startY;

    // دالة رسم رأس الجدول
    void drawHeader(PdfPage pg, double headerY) {
      double cx = 0;
      final pw = pg.getClientSize().width;
      pg.graphics.drawRectangle(
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, headerY, pw, headerH),
      );
      for (final col in columns) {
        final colW = col.width * scale;
        pg.graphics.drawString(
          col.label,
          PdfTrueTypeFont(boldBytes, 9),
          brush: PdfSolidBrush(PdfColor(255, 255, 255)),
          bounds: Rect.fromLTWH(cx, headerY, colW, headerH),
          format: rowRtl,
        );
        cx += colW;
      }
    }

    drawHeader(currentPage, y);
    y += headerH;

    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final pageH = currentPage.getClientSize().height;

      // هل نحتاج صفحة جديدة؟
      if (y + rowH > pageH - bottomMargin) {
        currentPage = document.pages.add();
        y = 20;
        drawHeader(currentPage, y);
        y += headerH;
      }

      // لون صف متناوب
      final rowBg = i.isEven
          ? PdfColor(248, 250, 252)
          : PdfColor(255, 255, 255);
      final pw = currentPage.getClientSize().width;

      currentPage.graphics.drawRectangle(
        brush: PdfSolidBrush(rowBg),
        bounds: Rect.fromLTWH(0, y, pw, rowH),
      );
      // خط رفيع في الأسفل
      currentPage.graphics.drawLine(
        PdfPen(PdfColor(226, 232, 240), width: 0.5),
        Offset(0, y + rowH),
        Offset(pw, y + rowH),
      );

      // لون الحالة
      final statusColor = s.isPassed
          ? passedColor
          : s.isAbsent
              ? PdfColor(107, 114, 128)
              : s.isComplementary
                  ? PdfColor(234, 179, 8)
                  : failedColor;

      double cx = 0;
      for (final col in columns) {
        final colW = col.width * scale;
        String cellValue = '';
        PdfBrush textBrush = PdfSolidBrush(darkColor);

        switch (col.label) {
          case '#':
            cellValue = '${i + 1}';
            break;
          case 'الاسم الكامل':
            cellValue = s.name.isNotEmpty ? s.name : '—';
            break;
          case 'الرقم':
            cellValue = s.id.isNotEmpty ? s.id : '—';
            break;
          case 'الشعبة':
            cellValue = s.branch.isNotEmpty ? s.branch : '—';
            break;
          case 'المدرسة':
          case 'المركز':
            cellValue = (s.school.isNotEmpty ? s.school : s.center).isNotEmpty
                ? (s.school.isNotEmpty ? s.school : s.center)
                : '—';
            break;
          case 'الولاية':
            cellValue = s.wilaya.isNotEmpty ? s.wilaya : '—';
            break;
          default:
            if (col.label.contains(scoreLabel)) {
              cellValue = s.score != null ? s.score!.toStringAsFixed(2) : '—';
              textBrush = PdfSolidBrush(statusColor);
            } else if (col.label == 'الحالة') {
              cellValue = s.status.isNotEmpty ? s.status : '—';
              textBrush = PdfSolidBrush(statusColor);
            }
        }

        currentPage.graphics.drawString(
          cellValue,
          PdfTrueTypeFont(
            col.label == 'الاسم الكامل' ? regularBytes : regularBytes,
            col.label == 'الاسم الكامل' ? 8 : 8,
          ),
          brush: textBrush,
          bounds: Rect.fromLTWH(cx + 2, y, colW - 4, rowH),
          format: rowRtl,
        );
        cx += colW;
      }

      y += rowH;
    }
  }

  // ─── تذييل كل الصفحات ────────────────────────────────────────────────────

  static void _addFooter(
    PdfDocument document,
    PdfFont font,
    PdfColor primaryColor,
    PdfColor lightGray,
  ) {
    final total = document.pages.count;
    for (int i = 0; i < total; i++) {
      final pg = document.pages[i];
      final ph = pg.getClientSize().height;
      final pw = pg.getClientSize().width;

      pg.graphics.drawLine(
        PdfPen(PdfColor(203, 213, 225), width: 0.8),
        Offset(0, ph - 28),
        Offset(pw, ph - 28),
      );
      pg.graphics.drawString(
        'تطبيق مراجعي — MERAJ3I',
        font,
        brush: PdfSolidBrush(PdfColor(148, 163, 184)),
        bounds: Rect.fromLTWH(0, ph - 24, pw / 2, 20),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.right,
          textDirection: PdfTextDirection.rightToLeft,
        ),
      );
      pg.graphics.drawString(
        'صفحة ${i + 1} من $total',
        font,
        brush: PdfSolidBrush(PdfColor(148, 163, 184)),
        bounds: Rect.fromLTWH(pw / 2, ph - 24, pw / 2, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.left),
      );
    }
  }
}

class _StatBox {
  final String label;
  final String value;
  final PdfColor color;
  _StatBox(this.label, this.value, this.color);
}

class _TableColumn {
  final String label;
  final double width;
  _TableColumn(this.label, this.width);
}
