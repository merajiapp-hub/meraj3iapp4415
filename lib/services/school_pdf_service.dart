import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../services/results_service.dart';

class SchoolPdfService {
  static Future<void> generateAndShareList({
    required BuildContext context,
    required List<StudentResult> students,
    required String listTitle,
    required String schoolName,
    required String competitionTitle,
    bool saveToDownloads = false,
  }) async {
    try {
      final file = await _buildListPdf(
        students: students,
        listTitle: listTitle,
        schoolName: schoolName,
        competitionTitle: competitionTitle,
      );

      if (!context.mounted) return;

      if (saveToDownloads) {
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
            '${downloadsDir!.path}/meraj3i_${listTitle.replaceAll(' ', '_')}_$schoolName.pdf';
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
        await SharePlus.instance.share(ShareParams(
          text: '📊 $listTitle — $schoolName\n\nمن تطبيق مراجعي',
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'نتيجة $schoolName',
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

  static Future<File> _buildListPdf({
    required List<StudentResult> students,
    required String listTitle,
    required String schoolName,
    required String competitionTitle,
  }) async {
    final document = PdfDocument();
    document.pageSettings.margins.all = 30;
    
    // Load Arabic Font
    final ByteData fontData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final Uint8List fontBytes = fontData.buffer.asUint8List();
    final PdfFont arabicFont = PdfTrueTypeFont(fontBytes, 12);
    final PdfFont arabicBoldFont = PdfTrueTypeFont(fontBytes, 16, style: PdfFontStyle.bold);
    
    final page = document.pages.add();
    final double pageWidth = page.getClientSize().width;
    
    double y = 0;
    
    final PdfColor primaryColor = PdfColor(11, 107, 88);

    // Header
    page.graphics.drawString(
      'MERAJ3I — مراجعي',
      arabicBoldFont,
      brush: PdfSolidBrush(primaryColor),
      bounds: Rect.fromLTWH(0, y, pageWidth, 30),
      format: PdfStringFormat(alignment: PdfTextAlignment.center, textDirection: PdfTextDirection.rightToLeft),
    );
    y += 30;

    page.graphics.drawString(
      '$competitionTitle - $schoolName',
      arabicBoldFont,
      brush: PdfSolidBrush(PdfColor(30, 41, 59)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 25),
      format: PdfStringFormat(alignment: PdfTextAlignment.center, textDirection: PdfTextDirection.rightToLeft),
    );
    y += 25;

    page.graphics.drawString(
      listTitle,
      arabicFont,
      brush: PdfSolidBrush(PdfColor(100, 116, 139)),
      bounds: Rect.fromLTWH(0, y, pageWidth, 20),
      format: PdfStringFormat(alignment: PdfTextAlignment.center, textDirection: PdfTextDirection.rightToLeft),
    );
    y += 30;

    // Table
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: 4);
    
    final PdfGridRow headerRow = grid.headers.add(1)[0];
    headerRow.cells[0].value = 'الرقم';
    headerRow.cells[1].value = 'الاسم الكامل';
    headerRow.cells[2].value = 'الرقم الوطني / رقم التسجيل';
    headerRow.cells[3].value = 'المعدل/المجموع';
    
    final PdfGridCellStyle headerStyle = PdfGridCellStyle(
      font: arabicBoldFont,
      backgroundBrush: PdfSolidBrush(primaryColor),
      textBrush: PdfSolidBrush(PdfColor(255, 255, 255)),
      format: PdfStringFormat(alignment: PdfTextAlignment.center, textDirection: PdfTextDirection.rightToLeft),
    );
    for (int i = 0; i < headerRow.cells.count; i++) {
      headerRow.cells[i].style = headerStyle;
    }

    final PdfGridCellStyle cellStyle = PdfGridCellStyle(
      font: arabicFont,
      format: PdfStringFormat(alignment: PdfTextAlignment.center, textDirection: PdfTextDirection.rightToLeft),
    );

    int idx = 1;
    for (var s in students) {
      final row = grid.rows.add();
      row.cells[0].value = idx.toString();
      row.cells[1].value = s.name;
      row.cells[2].value = s.id;
      row.cells[3].value = s.score?.toString() ?? '-';
      
      for (int i = 0; i < row.cells.count; i++) {
        row.cells[i].style = cellStyle;
      }
      idx++;
    }

    grid.draw(page: page, bounds: Rect.fromLTWH(0, y, pageWidth, 0));

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/meraj3i_list_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    final bytes = await document.save();
    await file.writeAsBytes(bytes);
    document.dispose();

    return file;
  }
}
