// services/result_pdf_service.dart
// إنشاء ملف PDF احترافي لنتيجة الطالب — v5.1.0
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/results_service.dart';
import '../models/result_pdf_file.dart';
import '../services/school_pdf_service.dart';
class ResultPdfService {


  /// ينشئ PDF احترافي ويرجع النتيجة (للمعاينة والحفظ)
  static Future<PdfBuildResult> buildAndSave({
    required StudentResult student,
    required ExamType examType,
    required String competitionTitle,
    required String scoreLabel,
    required double maxScore,
    int? rankNational,
    int? rankWilaya,
    int? rankCenter,
    int? rankSchool,
  }) async {
    try {
      // بناء الملف في مكان مؤقت أولاً
      final tempFile = await _buildPdf(
        student: student,
        examType: examType,
        competitionTitle: competitionTitle,
        scoreLabel: scoreLabel,
        maxScore: maxScore,
        rankNational: rankNational,
        rankWilaya: rankWilaya,
        rankCenter: rankCenter,
        rankSchool: rankSchool,
      );

      // المجلد المخصص للحفظ الدائم
      Directory? saveDir;
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
            saveDir = d;
            break;
          } catch (_) {}
        }
      }
      if (saveDir == null) {
        final appDir = await getApplicationDocumentsDirectory();
        saveDir = Directory('${appDir.path}/Meraj3i_Results');
        if (!saveDir.existsSync()) saveDir.createSync(recursive: true);
      }

      final now = DateTime.now();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final safeName = _safeFileName(student.name);
      final fileName = 'meraj3i_card_${safeName}_$stamp.pdf';
      final filePath = '${saveDir.path}/$fileName';

      // نسخ الملف من المؤقت إلى الدائم
      final savedFile = await tempFile.copy(filePath);

      // التحقق
      if (!savedFile.existsSync() || savedFile.lengthSync() == 0) {
        if (savedFile.existsSync()) await savedFile.delete();
        return PdfBuildResult(success: false, errorMessage: 'فشل حفظ الملف على الجهاز');
      }

      final sizeMb = savedFile.lengthSync() / (1024 * 1024);
      
      return PdfBuildResult(
        success: true,
        filePath: filePath,
        pdfFile: ResultPdfFile(
          id: '${now.millisecondsSinceEpoch}',
          fileName: fileName,
          localPath: filePath,
          title: 'بطاقة الطالب: ${student.name.isNotEmpty ? student.name : student.id}',
          competition: competitionTitle,
          listType: 'student',
          fileSizeMb: sizeMb,
          savedAt: now,
          studentCount: 1,
        ),
      );
    } catch (e) {
      return PdfBuildResult(success: false, errorMessage: 'تعذر إنشاء PDF: $e');
    }
  }

  static Future<File> _buildPdf({
    required StudentResult student,
    required ExamType examType,
    required String competitionTitle,
    required String scoreLabel,
    required double maxScore,
    int? rankNational,
    int? rankWilaya,
    int? rankCenter,
    int? rankSchool,
  }) async {
    final document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 40;

    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;
    final pageHeight = page.getClientSize().height;

    // ── تحميل الخطوط العربية (Tajawal) ──
    final ByteData regularFontData =
        await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final ByteData boldFontData =
        await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
    final Uint8List regularBytes = regularFontData.buffer.asUint8List();
    final Uint8List boldBytes = boldFontData.buffer.asUint8List();

    // ── تحميل شعار التطبيق ──
    PdfBitmap? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = PdfBitmap(logoData.buffer.asUint8List());
    } catch (_) {
      // الشعار غير موجود، نكمل بدونه
    }

    // ── الألوان ──
    final primaryColor = PdfColor(13, 148, 136); // #0D9488
    final darkColor = PdfColor(15, 23, 42); // #0F172A
    final lightGray = PdfColor(241, 245, 249); // #F1F5F9
    final successColor = PdfColor(22, 163, 74); // #16A34A
    final failColor = PdfColor(239, 68, 68); // #EF4444
    final warnColor = PdfColor(59, 130, 246); // #3B82F6

    // ── الخطوط ──
    final boldFont = PdfTrueTypeFont(boldBytes, 14);

    final smallFont = PdfTrueTypeFont(regularBytes, 9);
    final titleFont = PdfTrueTypeFont(boldBytes, 16);
    final scoreFont = PdfTrueTypeFont(boldBytes, 28);

    // تنسيق RTL للعربية
    final rtlFormat = PdfStringFormat(
      alignment: PdfTextAlignment.right,
      textDirection: PdfTextDirection.rightToLeft,
    );
    final centerRtlFormat = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      textDirection: PdfTextDirection.rightToLeft,
      lineAlignment: PdfVerticalAlignment.middle,
    );

    double y = 0;

    // ══════════════════════════════════════════════════════════════
    // HEADER — رأس الصفحة الاحترافي مع الشعار
    // ══════════════════════════════════════════════════════════════
    const headerHeight = 90.0;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, headerHeight),
    );

    // شريط ملوّن في أسفل الهيدر
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(primaryColor),
      bounds: Rect.fromLTWH(0, y + headerHeight - 4, pageWidth, 4),
    );

    // الشعار (إذا وُجد)
    if (logoImage != null) {
      const logoSize = 56.0;
      page.graphics.drawImage(
        logoImage,
        Rect.fromLTWH(pageWidth - logoSize - 10, y + (headerHeight - logoSize) / 2, logoSize, logoSize),
      );
    }

    // اسم التطبيق
    page.graphics.drawString(
      'MERAJ3I — مراجعي',
      PdfTrueTypeFont(boldBytes, 22),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(0, y + 18, pageWidth - 80, 30),
      format: centerRtlFormat,
    );

    // الوصف
    page.graphics.drawString(
      'بطاقة نتيجة رسمية • ${DateTime.now().year}',
      PdfTrueTypeFont(regularBytes, 10),
      brush: PdfSolidBrush(PdfColor(180, 210, 210)),
      bounds: Rect.fromLTWH(0, y + 54, pageWidth - 80, 18),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        textDirection: PdfTextDirection.rightToLeft,
      ),
    );

    y += headerHeight + 16;

    // ══════════════════════════════════════════════════════════════
    // عنوان المسابقة
    // ══════════════════════════════════════════════════════════════
    page.graphics.drawString(
      competitionTitle,
      titleFont,
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, 28),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        textDirection: PdfTextDirection.rightToLeft,
      ),
    );
    y += 38;

    // ══════════════════════════════════════════════════════════════
    // بطاقة النتيجة الرئيسية
    // ══════════════════════════════════════════════════════════════
    final statusColor = student.isPassed
        ? successColor
        : student.isComplementary
            ? warnColor
            : failColor;

    // خلفية الكرت مع حدود
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(lightGray),
      bounds: Rect.fromLTWH(0, y, pageWidth, 110),
    );
    page.graphics.drawRectangle(
      pen: PdfPen(statusColor, width: 2),
      bounds: Rect.fromLTWH(0, y, pageWidth, 110),
    );

    // الشريط الملوّن على اليسار
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(statusColor),
      bounds: Rect.fromLTWH(0, y, 8, 110),
    );

    // الاسم
    page.graphics.drawString(
      student.name.isNotEmpty ? student.name : 'مترشح',
      boldFont,
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(20, y + 14, pageWidth - 160, 22),
      format: rtlFormat,
    );

    // رقم التسجيل
    page.graphics.drawString(
      'ر. تسجيل: ${student.id}',
      smallFont,
      brush: PdfSolidBrush(PdfColor(100, 116, 139)),
      bounds: Rect.fromLTWH(20, y + 40, pageWidth - 160, 18),
      format: rtlFormat,
    );

    // شارة الحالة
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(statusColor),
      bounds: Rect.fromLTWH(20, y + 66, 90, 24),
    );
    page.graphics.drawString(
      student.status,
      PdfTrueTypeFont(boldBytes, 10),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(20, y + 66, 90, 24),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
        textDirection: PdfTextDirection.rightToLeft,
      ),
    );

    // النقطة/المعدل
    if (student.score != null) {
      page.graphics.drawString(
        student.score!.toStringAsFixed(2),
        scoreFont,
        brush: PdfSolidBrush(statusColor),
        bounds: Rect.fromLTWH(pageWidth - 140, y + 14, 130, 55),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        ),
      );
      page.graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200), width: 0.8),
        Offset(pageWidth - 140, y + 72),
        Offset(pageWidth - 14, y + 72),
      );
      page.graphics.drawString(
        '/ ${maxScore.toStringAsFixed(0)}  ($scoreLabel)',
        smallFont,
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(pageWidth - 140, y + 75, 130, 18),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }

    y += 126;

    // ══════════════════════════════════════════════════════════════
    // بيانات المترشح
    // ══════════════════════════════════════════════════════════════
    page.graphics.drawString(
      'بيانات المترشح',
      boldFont,
      brush: PdfSolidBrush(primaryColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
      format: rtlFormat,
    );
    y += 24;

    page.graphics.drawLine(
      PdfPen(primaryColor, width: 1.5),
      Offset(0, y),
      Offset(pageWidth, y),
    );
    y += 8;

    final details = <String, String>{
      if (student.id.isNotEmpty) 'رقم التسجيل': student.id,
      if (student.school.isNotEmpty) 'المؤسسة': student.school,
      if (student.center.isNotEmpty) 'المقاطعة': student.center,
      if (student.wilaya.isNotEmpty) 'الولاية': student.wilaya,
      if (student.branch.isNotEmpty) 'الشعبة': student.branch,
      if (student.rank.isNotEmpty) 'الترتيب': student.rank,
      scoreLabel: student.score != null
          ? '${student.score!.toStringAsFixed(2)} / ${maxScore.toStringAsFixed(0)}'
          : '—',
      'الحالة': student.status,
    };

    int rowIdx = 0;
    for (final entry in details.entries) {
      final rowBg =
          rowIdx.isEven ? lightGray : PdfColor(255, 255, 255);
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(rowBg),
        bounds: Rect.fromLTWH(0, y, pageWidth, 26),
      );
      // المفتاح (يسار)
      page.graphics.drawString(
        entry.key,
        smallFont,
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(10, y + 5, pageWidth * 0.4, 18),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.left,
          textDirection: PdfTextDirection.rightToLeft,
        ),
      );
      // القيمة (يمين)
      page.graphics.drawString(
        entry.value,
        PdfTrueTypeFont(boldBytes, 10),
        brush: PdfSolidBrush(darkColor),
        bounds: Rect.fromLTWH(pageWidth * 0.4, y + 5, pageWidth * 0.56, 18),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.right,
          textDirection: PdfTextDirection.rightToLeft,
        ),
      );
      y += 26;
      rowIdx++;
    }

    y += 16;

    // ══════════════════════════════════════════════════════════════
    // الترتيبات
    // ══════════════════════════════════════════════════════════════
    final ranks = <String, int>{};
    if (rankNational != null) ranks['الترتيب الوطني'] = rankNational;
    if (rankWilaya != null) ranks['ترتيب الولاية'] = rankWilaya;
    if (rankCenter != null) ranks['ترتيب المقاطعة'] = rankCenter;
    if (rankSchool != null) ranks['ترتيب المؤسسة'] = rankSchool;

    if (ranks.isNotEmpty && student.isPassed) {
      page.graphics.drawString(
        'الترتيبات',
        boldFont,
        brush: PdfSolidBrush(primaryColor),
        bounds: Rect.fromLTWH(0, y, pageWidth, 20),
        format: rtlFormat,
      );
      y += 24;

      page.graphics.drawLine(
        PdfPen(primaryColor, width: 1.5),
        Offset(0, y),
        Offset(pageWidth, y),
      );
      y += 10;

      final cellW = pageWidth / ranks.length;
      int idx = 0;
      for (final r in ranks.entries) {
        final x = idx * cellW;
        page.graphics.drawRectangle(
          brush: PdfSolidBrush(lightGray),
          pen: PdfPen(primaryColor, width: 0.5),
          bounds: Rect.fromLTWH(x + 2, y, cellW - 4, 54),
        );
        page.graphics.drawString(
          '#${r.value}',
          PdfTrueTypeFont(boldBytes, 20),
          brush: PdfSolidBrush(primaryColor),
          bounds: Rect.fromLTWH(x + 2, y + 6, cellW - 4, 28),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        page.graphics.drawString(
          r.key,
          smallFont,
          brush: PdfSolidBrush(PdfColor(100, 116, 139)),
          bounds: Rect.fromLTWH(x + 2, y + 34, cellW - 4, 16),
          format: PdfStringFormat(
            alignment: PdfTextAlignment.center,
            textDirection: PdfTextDirection.rightToLeft,
          ),
        );
        idx++;
      }
      y += 68;
    }

    // ══════════════════════════════════════════════════════════════
    // FOOTER — التذييل مع الشعار والتاريخ
    // ══════════════════════════════════════════════════════════════
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    page.graphics.drawLine(
      PdfPen(PdfColor(203, 213, 225), width: 1),
      Offset(0, pageHeight - 38),
      Offset(pageWidth, pageHeight - 38),
    );

    // الشعار الصغير في التذييل
    if (logoImage != null) {
      page.graphics.drawImage(
        logoImage,
        Rect.fromLTWH(pageWidth - 30, pageHeight - 30, 22, 22),
      );
    }

    page.graphics.drawString(
      'تطبيق مراجعي MERAJ3I  •  v5.1.0  •  $dateStr',
      smallFont,
      brush: PdfSolidBrush(PdfColor(148, 163, 184)),
      bounds: Rect.fromLTWH(0, pageHeight - 26, pageWidth - 36, 20),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        textDirection: PdfTextDirection.rightToLeft,
      ),
    );

    // ── حفظ الملف في مجلد مؤقت ثم إرجاعه ──
    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/meraj3i_${_safeFileName(student.name)}_${now.millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    final bytes = await document.save();
    await file.writeAsBytes(bytes);
    document.dispose();

    return file;
  }

  static String _safeFileName(String name) {
    final safe = name.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '_');
    return safe.length > 30 ? safe.substring(0, 30) : safe;
  }
}
