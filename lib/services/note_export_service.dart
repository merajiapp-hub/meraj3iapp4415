import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service to export notes as PDF or TXT with full Arabic RTL support.
class NoteExportService {
  static String _normalizePlainText(String value) {
    if (value.isEmpty) return '';
    final normalized = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trimRight();
    return normalized;
  }

  static List<dynamic> _extractDeltaOps(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (decoded['ops'] is List) return decoded['ops'] as List;
      if (decoded['delta'] is List) return decoded['delta'] as List;
      if (decoded['content'] is List) return decoded['content'] as List;
    }
    return const [];
  }

  // ─── Text extraction from Quill Delta JSON ─────────────────────────────
  static String plainTextFromQuill(String content) {
    if (content.trim().isEmpty) return '';

    final raw = content.trim();
    try {
      final decoded = jsonDecode(raw);
      final ops = _extractDeltaOps(decoded);
      if (ops.isEmpty) return _normalizePlainText(raw);

      final buffer = StringBuffer();
      for (final op in ops) {
        if (op is String) {
          buffer.write(op);
          continue;
        }

        if (op is Map) {
          final insert = op['insert'];
          if (insert is String) {
            buffer.write(insert);
          } else if (insert is Map) {
            final embedded = insert['image'] ?? insert['video'] ?? insert['formula'];
            if (embedded is String && embedded.isNotEmpty) {
              buffer.write(embedded);
            }
          }
        }
      }

      final text = buffer.toString();
      return _normalizePlainText(text);
    } catch (_) {
      return _normalizePlainText(raw);
    }
  }

  // ─── TXT Export (UTF-8 with BOM for Windows compatibility) ─────────────
  static Uint8List textBytes({required String title, required String content}) {
    final plainText = plainTextFromQuill(content);
    final safeTitle = _sanitizeTitle(title);
    final separator = '─' * 40;
    final now = DateTime.now();
    final dateStr =
        '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    final fullText = [
      safeTitle.trim().isEmpty ? 'ملاحظة' : safeTitle,
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
  static String _sanitizeTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return 'ملاحظة';
    final withoutBrand = trimmed
        .replaceAll(RegExp(r'MERAJ3I|مراجعي', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return withoutBrand.isEmpty ? 'ملاحظة' : withoutBrand;
  }

  static Future<Uint8List> pdfBytes({
    required String title,
    required String content,
    String pageStyle = 'blank',
    bool includeBackground = false,
  }) async {
    final document = PdfDocument();
    final safeTitle = _sanitizeTitle(title);

    final regularData =
        await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');

    final titleFont = PdfTrueTypeFont(boldData.buffer.asUint8List(), 22);
    final metaFont = PdfTrueTypeFont(regularData.buffer.asUint8List(), 10);
    final bodyFont = PdfTrueTypeFont(regularData.buffer.asUint8List(), 13);

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

    final rawBodyText = plainTextFromQuill(content);
    final bodyText = _normalizePlainText(rawBodyText);
    final bodyTextValue = bodyText.isEmpty ? '(ملاحظة فارغة)' : bodyText;

    final page = document.pages.add();
    final pageWidth = page.getClientSize().width;
    final pageHeight = page.getClientSize().height;
    const margin = 36.0;

    if (includeBackground && pageStyle != 'blank') {
      _drawPageBackground(page.graphics, pageWidth, pageHeight, pageStyle);
    }

    page.graphics.drawString(
      safeTitle,
      titleFont,
      brush: primaryBrush,
      bounds: Rect.fromLTWH(0, 0, pageWidth, 34),
      format: rtlFormat,
    );

    page.graphics.drawLine(
      PdfPen(PdfColor(200, 210, 220), width: 0.5),
      Offset(0, 40),
      Offset(pageWidth, 40),
    );

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    page.graphics.drawString(
      dateStr,
      metaFont,
      brush: metaBrush,
      bounds: Rect.fromLTWH(0, 44, pageWidth, 16),
      format: ltrFormat,
    );

    final bodyElement = PdfTextElement(
      text: bodyTextValue,
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


