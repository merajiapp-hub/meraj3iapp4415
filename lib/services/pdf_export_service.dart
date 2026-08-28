import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:intl/intl.dart';
import '../data/note_models.dart';

class PdfExportService {
  /// يقوم باستخراج النص الخام من محتوى Quill (JSON)
  static String _extractPlainTextFromQuillJson(String jsonContent) {
    try {
      final List<dynamic> ops = jsonDecode(jsonContent);
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op['insert'] != null && op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      // في حال كان المحتوى نصاً عادياً وليس JSON
      return jsonContent;
    }
  }

  /// ينشئ ملف PDF ويفتحه
  static Future<void> exportNoteToPdf(Note note) async {
    try {
      // 1. استخراج النص
      final plainText = _extractPlainTextFromQuillJson(note.content);

      // 2. إنشاء مستند PDF
      final PdfDocument document = PdfDocument();
      
      // 3. إضافة صفحة
      final PdfPage page = document.pages.add();

      // 4. إعداد الخطوط والألوان
      // ملاحظة: لدعم اللغة العربية في Syncfusion يجب توفير ملف خط TTF (مثل Arial أو Tahoma).
      // للتبسيط ولضمان عمل الكود فوراً، سنستخدم الخط القياسي (سيدعم الإنجليزية بشكل ممتاز، 
      // وقد يواجه مشاكل مع العربية إذا لم يتم تضمين ملف خط خاص. سنستخدم Standard font مبدئياً).
      final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 24, style: PdfFontStyle.bold);
      final PdfFont dateFont = PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.italic);
      final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 14);

      final PdfBrush primaryBrush = PdfSolidBrush(PdfColor(15, 23, 42)); // Dark Blue
      final PdfBrush secondaryBrush = PdfSolidBrush(PdfColor(100, 116, 139)); // Slate
      
      double yOffset = 0;

      // 5. رسم العنوان
      page.graphics.drawString(
        note.title.isEmpty ? 'Untitled Note' : note.title,
        headerFont,
        brush: primaryBrush,
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 50),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.left,
        ),
      );
      yOffset += 40;

      // 6. رسم التاريخ
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(note.updatedAt);
      page.graphics.drawString(
        'Last updated: $dateStr',
        dateFont,
        brush: secondaryBrush,
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, 20),
      );
      yOffset += 30;

      // رسم خط فاصل
      page.graphics.drawLine(
        PdfPen(PdfColor(200, 200, 200), width: 1),
        Offset(0, yOffset),
        Offset(page.getClientSize().width, yOffset),
      );
      yOffset += 20;

      // 7. رسم المحتوى (يدعم التمرير للصفحات المتعددة تلقائياً عبر bounds)
      final PdfTextElement textElement = PdfTextElement(
        text: plainText.isEmpty ? '(Empty Note)' : plainText,
        font: contentFont,
        brush: primaryBrush,
      );
      
      final PdfLayoutFormat layoutFormat = PdfLayoutFormat(
        layoutType: PdfLayoutType.paginate,
      );

      textElement.draw(
        page: page,
        bounds: Rect.fromLTWH(0, yOffset, page.getClientSize().width, page.getClientSize().height - yOffset),
        format: layoutFormat,
      );

      // 8. حفظ الملف في الجهاز (مجلد التنزيلات الخارجي)
      final List<int> bytes = await document.save();
      document.dispose();

      // اسم الملف آمن (نزيل الأحرف غير الصالحة)
      final safeTitle = note.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final fileName = '${safeTitle.isEmpty ? "note" : safeTitle}_${DateFormat("yyyyMMdd_HHmm").format(DateTime.now())}.pdf';

      String path;
      if (Platform.isAndroid) {
        // مجلد التنزيلات العام — يظهر في تطبيق الملفات مباشرة
        const downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          path = '$downloadsPath/مراجعي_$fileName';
        } else {
          // fallback للتخزين الداخلي
          final dir = await getApplicationDocumentsDirectory();
          path = '${dir.path}/$fileName';
        }
      } else {
        // iOS: مجلد المستندات القابل للمشاركة
        final dir = await getApplicationDocumentsDirectory();
        path = '${dir.path}/$fileName';
      }

      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      // 9. فتح الملف
      await OpenFilex.open(path);

    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      throw Exception('فشل تصدير الملاحظة لملف PDF');
    }
  }
}
