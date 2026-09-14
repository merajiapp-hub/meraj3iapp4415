import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service to export notes as PDF or TXT with full Arabic RTL support.
class NoteExportService {
  // ─── Text extraction from Quill Delta JSON ─────────────────────────────
  static String plainTextFromQuill(String content) {
    if (content.isEmpty) return '';
    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) return content;
      final buffer = StringBuffer();
      for (final op in decoded) {
        if (op is Map) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          }
        }
      }
      return buffer.toString().trimRight();
    } catch (_) {
      return content;
    }
  }

  // ─── TXT Export (UTF-8 with BOM for Windows compatibility) ─────────────
  static Uint8List textBytes({required String title, required String content}) {
    final plainText = plainTextFromQuill(content);
    final separator = '─' * 40;
    final now = DateTime.now();
    final dateStr =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    final fullText = [
      title.trim().isEmpty ? 'ملاحظة MERAJ3I' : title.trim(),
      separator,
      'التاريخ: $dateStr',
      '',
      plainText.trim().isEmpty ? '(ملاحظة فارغة)' : plainText,
    ].join('\n');

    // UTF-8 BOM ensures Arabic renders correctly on Windows Notepad etc.
    const bom = [0xEF, 0xBB, 0xBF];
    return Uint8List.fromList([...bom, ...utf8.encode(fullText)]);
  }

  // ─── PDF Export (RTL, Arabic font, paginated) ───────────────────────────
  static Future<Uint8List> pdfBytes({
    required String title,
    required String content,
    String pageStyle = 'blank',
    bool includeBackground = false,
  }) async {
    final document = PdfDocument();

    // Load Arabic-supporting fonts from assets
    final regularData =
        await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');

    final titleFont = PdfTrueTypeFont(boldData.buffer.asUint8List(), 22);
    final metaFont = PdfTrueTypeFont(regularData.buffer.asUint8List(), 10);
    final bodyFont = PdfTrueTypeFont(regularData.buffer.asUint8List(), 13);

    // RTL string format for Arabic text
    final rtlFormat = PdfStringFormat(
      textDirection: PdfTextDirection.rightToLeft,
      alignment: PdfTextAlignment.right,
      lineAlignment: PdfVerticalAlignment.top,
      wordSpacing: 0,
    );

    final ltrFormat = PdfStringFormat(
      alignment: PdfTextAlignment.left,
      lineAlignment: PdfVerticalAlignment.top,
    );

    final primaryBrush = PdfSolidBrush(PdfColor(15, 23, 42));
    final metaBrush = PdfSolidBrush(PdfColor(100, 116, 139));

    // First page
    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;
    final pageHeight = page.getClientSize().height;
    const margin = 36.0;

    // Optional page background
    if (includeBackground && pageStyle != 'blank') {
      _drawPageBackground(page.graphics, pageWidth, pageHeight, pageStyle);
    }

    // Title (RTL, bold)
    final titleStr =
        title.trim().isEmpty ? 'ملاحظة MERAJ3I' : title.trim();
    page.graphics.drawString(
      titleStr,
      titleFont,
      brush: primaryBrush,
      bounds: Rect.fromLTWH(0, 0, pageWidth, 34),
      format: rtlFormat,
    );

    // Divider line
    page.graphics.drawLine(
      PdfPen(PdfColor(200, 210, 220), width: 0.5),
      Offset(0, 40),
      Offset(pageWidth, 40),
    );

    // Meta: app name + date (LTR)
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    page.graphics.drawString(
      'MERAJ3I  ·  $dateStr',
      metaFont,
      brush: metaBrush,
      bounds: Rect.fromLTWH(0, 44, pageWidth, 16),
      format: ltrFormat,
    );

    // Body text with RTL Arabic and automatic pagination
    final plainText = plainTextFromQuill(content);
    final bodyStr =
        plainText.trim().isEmpty ? '(ملاحظة فارغة)' : plainText.trim();

    final bodyElement = PdfTextElement(
      text: bodyStr,
      font: bodyFont,
      brush: primaryBrush,
      format: rtlFormat,
    );

    bodyElement.draw(
      page: page,
      bounds: Rect.fromLTWH(0, 68, pageWidth, pageHeight - 68 - margin),
      format: PdfLayoutFormat(
        layoutType: PdfLayoutType.paginate,
        breakType: PdfLayoutBreakType.fitPage,
      ),
    );

    // Page numbers on all pages
    _addPageNumbers(document, metaFont, metaBrush);

    final bytes = await document.save();
    document.dispose();
    return Uint8List.fromList(bytes);
  }

  // ─── Draw lined/dotted background ──────────────────────────────────────
  static void _drawPageBackground(
    PdfGraphics graphics,
    double width,
    double height,
    String style,
  ) {
    final linePen = PdfPen(PdfColor(180, 200, 230), width: 0.4);

    if (style == 'lined') {
      const spacing = 28.0;
      for (double y = spacing * 3; y < height; y += spacing) {
        graphics.drawLine(linePen, Offset(0, y), Offset(width, y));
      }
    } else if (style == 'dotted') {
      final dotBrush = PdfSolidBrush(PdfColor(180, 200, 230));
      const spacing = 22.0;
      for (double y = spacing * 3; y < height; y += spacing) {
        for (double x = spacing; x < width; x += spacing) {
          graphics.drawEllipse(
            Rect.fromCircle(center: Offset(x, y), radius: 1.0),
            pen: null,
            brush: dotBrush,
          );
        }
      }
    }
  }

  // ─── Page numbers ──────────────────────────────────────────────────────
  static void _addPageNumbers(
    PdfDocument document,
    PdfFont font,
    PdfBrush brush,
  ) {
    final centerFormat = PdfStringFormat(
      alignment: PdfTextAlignment.center,
      lineAlignment: PdfVerticalAlignment.bottom,
    );
    for (int i = 0; i < document.pages.count; i++) {
      final pg = document.pages[i];
      final w = pg.getClientSize().width;
      final h = pg.getClientSize().height;
      pg.graphics.drawString(
        '${i + 1} / ${document.pages.count}',
        font,
        brush: brush,
        bounds: Rect.fromLTWH(0, h - 18, w, 18),
        format: centerFormat,
      );
    }
  }
}


