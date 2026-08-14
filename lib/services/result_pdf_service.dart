// services/result_pdf_service.dart
// إنشاء ملف PDF احترافي لنتيجة الطالب
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/results_service.dart';

class ResultPdfService {
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
        // حفظ في مجلد Downloads
        Directory? downloadsDir;
        try {
          if (Platform.isAndroid) {
            downloadsDir = Directory('/storage/emulated/0/Download');
            if (!downloadsDir.existsSync()) {
              downloadsDir = await getExternalStorageDirectory();
            }
          } else {
            downloadsDir = await getApplicationDocumentsDirectory();
          }
        } catch (_) {
          downloadsDir = await getTemporaryDirectory();
        }

        final savePath =
            '${downloadsDir!.path}/meraj3i_${_safeFileName(student.name)}.pdf';
        await file.copy(savePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('تم حفظ PDF في مجلد التنزيلات')),
              ]),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // مشاركة مباشرة
        await SharePlus.instance.share(ShareParams(
          text: '📊 نتيجة ${student.name} — $competitionTitle\n\nمن تطبيق مراجعي',
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

    // ─── الألوان ─────────────────────────────────────────────────────────
    final primaryColor = PdfColor(13, 148, 136); // #0D9488
    final darkColor = PdfColor(15, 23, 42); // #0F172A
    final lightGray = PdfColor(241, 245, 249); // #F1F5F9
    final successColor = PdfColor(22, 163, 74); // #16A34A
    final failColor = PdfColor(239, 68, 68); // #EF4444
    final warnColor = PdfColor(59, 130, 246); // #3B82F6

    // ─── الخطوط ──────────────────────────────────────────────────────────
    final boldFont = PdfStandardFont(PdfFontFamily.helvetica, 14,
        style: PdfFontStyle.bold);
    final regularFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
    final smallFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
    final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 18,
        style: PdfFontStyle.bold);
    final scoreFont = PdfStandardFont(PdfFontFamily.helvetica, 32,
        style: PdfFontStyle.bold);

    double y = 0;

    // ─── رأس الصفحة (Header) ─────────────────────────────────────────────
    // خلفية الرأس
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, 80),
    );

    // عنوان التطبيق
    page.graphics.drawString(
      'MERAJ3I — مراجعي',
      PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(0, y + 15, pageWidth, 30),
      format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle),
    );

    // وصف
    page.graphics.drawString(
      'بطاقة نتيجة رسمية',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      brush: PdfSolidBrush(PdfColor(200, 230, 230)),
      bounds: Rect.fromLTWH(0, y + 50, pageWidth, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    y += 90;

    // ─── عنوان المسابقة ───────────────────────────────────────────────────
    page.graphics.drawString(
      competitionTitle,
      titleFont,
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    y += 40;

    // ─── كرت النتيجة ──────────────────────────────────────────────────────
    final statusColor = student.isPassed
        ? successColor
        : student.isComplementary
            ? warnColor
            : failColor;

    final statusLabel = student.status;

    // خلفية الكرت
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(lightGray),
      bounds: Rect.fromLTWH(0, y, pageWidth, 120),
    );
    page.graphics.drawRectangle(
      pen: PdfPen(statusColor, width: 3),
      bounds: Rect.fromLTWH(0, y, pageWidth, 120),
    );

    // الحالة
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(statusColor),
      bounds: Rect.fromLTWH(0, y, 8, 120),
    );

    // الاسم
    page.graphics.drawString(
      student.name.isNotEmpty ? student.name : 'مترشح',
      boldFont,
      brush: PdfSolidBrush(darkColor),
      bounds: Rect.fromLTWH(20, y + 15, pageWidth - 40, 25),
    );

    // الحالة شارة
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(statusColor),
      bounds: Rect.fromLTWH(20, y + 45, 80, 24),
    );
    page.graphics.drawString(
      statusLabel,
      PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
      brush: PdfSolidBrush(PdfColor(255, 255, 255)),
      bounds: Rect.fromLTWH(20, y + 45, 80, 24),
      format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle),
    );

    // النقطة/المعدل
    if (student.score != null) {
      page.graphics.drawString(
        student.score!.toStringAsFixed(2),
        scoreFont,
        brush: PdfSolidBrush(statusColor),
        bounds: Rect.fromLTWH(pageWidth - 140, y + 25, 130, 60),
        format: PdfStringFormat(
            alignment: PdfTextAlignment.right,
            lineAlignment: PdfVerticalAlignment.middle),
      );
      page.graphics.drawString(
        '/ ${maxScore.toStringAsFixed(0)}',
        regularFont,
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(pageWidth - 140, y + 70, 130, 20),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
    }

    y += 135;

    // ─── تفاصيل المترشح ───────────────────────────────────────────────────
    y += 10;
    page.graphics.drawString(
      'بيانات المترشح',
      boldFont,
      brush: PdfSolidBrush(primaryColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
    );
    y += 25;

    // خط فاصل
    page.graphics.drawLine(
      PdfPen(primaryColor, width: 1),
      Offset(0, y),
      Offset(pageWidth, y),
    );
    y += 10;

    // حقول التفاصيل
    final details = <String, String>{
      'رقم التسجيل': student.id,
      scoreLabel: student.score != null
          ? '${student.score!.toStringAsFixed(2)} / ${maxScore.toStringAsFixed(0)}'
          : '—',
      if (student.school.isNotEmpty) 'المؤسسة': student.school,
      if (student.center.isNotEmpty) 'المقاطعة': student.center,
      if (student.wilaya.isNotEmpty) 'الولاية': student.wilaya,
      if (student.branch.isNotEmpty) 'الشعبة': student.branch,
      'الحالة': statusLabel,
    };

    for (final entry in details.entries) {
      // خلفية الصف
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(
            details.keys.toList().indexOf(entry.key).isEven ? lightGray : PdfColor(255, 255, 255)),
        bounds: Rect.fromLTWH(0, y, pageWidth, 26),
      );
      page.graphics.drawString(
        entry.key,
        smallFont,
        brush: PdfSolidBrush(PdfColor(100, 116, 139)),
        bounds: Rect.fromLTWH(8, y + 5, pageWidth / 2, 18),
      );
      page.graphics.drawString(
        entry.value,
        PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.bold),
        brush: PdfSolidBrush(darkColor),
        bounds: Rect.fromLTWH(pageWidth / 2, y + 5, pageWidth / 2 - 8, 18),
        format: PdfStringFormat(alignment: PdfTextAlignment.right),
      );
      y += 26;
    }

    y += 15;

    // ─── الترتيبات ───────────────────────────────────────────────────────
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
      y += 25;
      page.graphics.drawLine(
        PdfPen(primaryColor, width: 1),
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
          pen: PdfPen(primaryColor.hashCode == 0 ? PdfColor(200, 200, 200) : primaryColor, width: 0.5),
          bounds: Rect.fromLTWH(x + 2, y, cellW - 4, 50),
        );
        page.graphics.drawString(
          '#${r.value}',
          PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold),
          brush: PdfSolidBrush(primaryColor),
          bounds: Rect.fromLTWH(x + 2, y + 5, cellW - 4, 25),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        page.graphics.drawString(
          r.key,
          smallFont,
          brush: PdfSolidBrush(PdfColor(100, 116, 139)),
          bounds: Rect.fromLTWH(x + 2, y + 30, cellW - 4, 16),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
        idx++;
      }
      y += 65;
    }

    // ─── التذييل ─────────────────────────────────────────────────────────
    final now = DateTime.now();
    final dateStr =
        '${now.day}/${now.month}/${now.year}   ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    final pageHeight = page.getClientSize().height;
    page.graphics.drawLine(
      PdfPen(PdfColor(203, 213, 225), width: 1),
      Offset(0, pageHeight - 40),
      Offset(pageWidth, pageHeight - 40),
    );
    page.graphics.drawString(
      'تم إنشاء هذه الوثيقة بتاريخ $dateStr  •  تطبيق مراجعي MERAJ3I',
      smallFont,
      brush: PdfSolidBrush(PdfColor(148, 163, 184)),
      bounds: Rect.fromLTWH(0, pageHeight - 30, pageWidth, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    // ─── حفظ الملف ───────────────────────────────────────────────────────
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
    return name
        .replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]'), '_')
        .substring(0, name.length.clamp(0, 30));
  }
}
