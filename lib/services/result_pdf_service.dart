// services/result_pdf_service.dart
// إنشاء ملف PDF احترافي لنتيجة الطالب — v5.1.0
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/results_service.dart';

class ResultPdfService {
  /// المجلد المخصص لحفظ النتائج في مراجعي
  static Future<Directory> _getResultsDir() async {
    Directory base;
    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      base = extDir ?? await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final resultsDir = Directory('${base.path}/Meraj3i_Results');
    if (!resultsDir.existsSync()) {
      await resultsDir.create(recursive: true);
    }
    return resultsDir;
  }

  /// ينشئ PDF احترافي ويشاركه أو يحفظه
  static Future<void> generateAndShare({
    required BuildContext context,
    required StudentResult student,
    required ExamType examType,
    required String competitionTitle,
    required String scoreLabel,
    required double maxScore,
    int? rankNational,
    int? rankWilaya,
    int? rankCenter,
    int? rankSchool,
    bool saveToDownloads = false,
  }) async {
    try {
      final file = await _buildPdf(
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

      if (!context.mounted) return;

      if (saveToDownloads) {
        // ── حفظ في مجلد Meraj3i_Results ──
        final resultsDir = await _getResultsDir();
        final now = DateTime.now();
        final stamp =
            '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
        final saveName = 'meraj3i_${_safeFileName(student.name)}_$stamp.pdf';
        final savedFile = await file.copy('${resultsDir.path}/$saveName');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم حفظ PDF في: ${savedFile.path}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ]),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // ── مشاركة مباشرة ──
        await SharePlus.instance.share(ShareParams(
          text:
              '📊 نتيجة ${student.name} — $competitionTitle\n\nمن تطبيق مراجعي',
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'نتيجة $competitionTitle',
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إنشاء PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
