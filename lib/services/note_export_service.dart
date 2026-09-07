import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class NoteExportService {
  static String plainTextFromQuill(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) return content;
      final buffer = StringBuffer();
      for (final operation in decoded) {
        if (operation is Map && operation['insert'] is String) {
          buffer.write(operation['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return content;
    }
  }

  static Uint8List textBytes({required String title, required String content}) {
    final value = '${title.trim()}\n\n${plainTextFromQuill(content)}'.trim();
    return Uint8List.fromList(utf8.encode(value));
  }

  static Future<Uint8List> pdfBytes({
    required String title,
    required String content,
  }) async {
    final document = PdfDocument();
    final page = document.pages.add();
    final primary = PdfSolidBrush(PdfColor(15, 23, 42));
    final secondary = PdfSolidBrush(PdfColor(100, 116, 139));
    final regularFontData = await rootBundle.load(
      'assets/fonts/Tajawal-Regular.ttf',
    );
    final boldFontData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
    final titleFont = PdfTrueTypeFont(boldFontData.buffer.asUint8List(), 22);
    final metaFont = PdfTrueTypeFont(regularFontData.buffer.asUint8List(), 10);
    final bodyFont = PdfTrueTypeFont(regularFontData.buffer.asUint8List(), 13);

    page.graphics.drawString(
      title.trim().isEmpty ? 'MERAJ3I Note' : title.trim(),
      titleFont,
      brush: primary,
      bounds: Rect.fromLTWH(0, 0, page.getClientSize().width, 34),
    );
    page.graphics.drawString(
      'MERAJ3I',
      metaFont,
      brush: secondary,
      bounds: Rect.fromLTWH(0, 38, page.getClientSize().width, 18),
    );
    final element = PdfTextElement(
      text: plainTextFromQuill(content).trim().isEmpty
          ? '(Empty note)'
          : plainTextFromQuill(content),
      font: bodyFont,
      brush: primary,
    );
    element.draw(
      page: page,
      bounds: Rect.fromLTWH(
        0,
        72,
        page.getClientSize().width,
        page.getClientSize().height - 72,
      ),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    );
    final bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }
}
