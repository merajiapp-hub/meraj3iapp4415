import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/book.dart';
import '../models/result_pdf_file.dart';

class DownloadedBook {
  final String uniqueKey;
  final String id;
  final String title;
  final String section;
  final String grade;
  final String category;
  final String subject;
  final String localPath;
  final double fileSizeMb;
  final DateTime downloadDate;

  DownloadedBook({
    required this.uniqueKey,
    required this.id,
    required this.title,
    required this.section,
    required this.grade,
    required this.category,
    required this.subject,
    required this.localPath,
    required this.fileSizeMb,
    required this.downloadDate,
  });

  Map<String, dynamic> toMap() => {
    'uniqueKey': uniqueKey,
    'id': id,
    'title': title,
    'section': section,
    'grade': grade,
    'category': category,
    'subject': subject,
    'localPath': localPath,
    'fileSizeMb': fileSizeMb,
    'downloadDate': downloadDate.toIso8601String(),
  };

  factory DownloadedBook.fromMap(Map<String, dynamic> map) => DownloadedBook(
    uniqueKey: map['uniqueKey'] ?? '',
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    section: map['section'] ?? '',
    grade: map['grade'] ?? '',
    category: map['category'] ?? '',
    subject: map['subject'] ?? '',
    localPath: map['localPath'] ?? '',
    fileSizeMb: (map['fileSizeMb'] as num?)?.toDouble() ?? 0.0,
    downloadDate:
        DateTime.tryParse(map['downloadDate'] ?? '') ?? DateTime.now(),
  );

  factory DownloadedBook.fromBook(
    Book book,
    String localPath,
    double fileSizeMb,
  ) => DownloadedBook(
    uniqueKey: book.uniqueKey,
    id: book.id,
    title: book.title,
    section: book.section,
    grade: book.grade,
    category: book.category,
    subject: book.subject,
    localPath: localPath,
    fileSizeMb: fileSizeMb,
    downloadDate: DateTime.now(),
  );
}

class DownloadsProvider extends ChangeNotifier {
  static const String _downloadsKey = 'downloads_metadata_v2';
  static const String _resultPdfsKey = 'result_pdfs_metadata_v1';

  final List<DownloadedBook> _downloads = [];
  final List<ResultPdfFile> _resultPdfs = [];

  List<DownloadedBook> get downloads => List.unmodifiable(_downloads);
  List<ResultPdfFile> get resultPdfs => List.unmodifiable(_resultPdfs);

  DownloadsProvider() {
    _loadDownloads();
    _loadResultPdfs();
  }

  // ─── كتب PDF ────────────────────────────────────────────────────────────

  Future<void> _loadDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_downloadsKey);
    if (json != null && json.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _downloads.clear();
        for (final item in list) {
          final db = DownloadedBook.fromMap(item as Map<String, dynamic>);
          _downloads.add(db);
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading downloads: $e');
      }
    }
  }

  Future<void> addDownload(DownloadedBook downloaded) async {
    _downloads.removeWhere((d) => d.uniqueKey == downloaded.uniqueKey);
    _downloads.insert(0, downloaded);
    notifyListeners();
    await _saveDownloads();
  }

  Future<void> removeDownload(String uniqueKey) async {
    _downloads.removeWhere((d) => d.uniqueKey == uniqueKey);
    notifyListeners();
    await _saveDownloads();
  }

  bool isDownloaded(String uniqueKey) {
    return _downloads.any((d) => d.uniqueKey == uniqueKey);
  }

  String? getLocalPath(String uniqueKey) {
    try {
      return _downloads.firstWhere((d) => d.uniqueKey == uniqueKey).localPath;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_downloads.map((d) => d.toMap()).toList());
    await prefs.setString(_downloadsKey, jsonStr);
  }

  void clearAll() {
    _downloads.clear();
    notifyListeners();
  }

  // ─── ملفات PDF النتائج ──────────────────────────────────────────────────

  Future<void> _loadResultPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? json = prefs.getString(_resultPdfsKey);
    if (json != null && json.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(json);
        _resultPdfs.clear();
        for (final item in list) {
          final rf = ResultPdfFile.fromMap(item as Map<String, dynamic>);
          // تحقق أن الملف لا يزال موجوداً فعلياً
          if (File(rf.localPath).existsSync()) {
            _resultPdfs.add(rf);
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading result PDFs: $e');
      }
    }
  }

  /// إضافة ملف نتيجة PDF جديد بعد التحقق من وجوده الفعلي
  Future<bool> addResultPdf(ResultPdfFile pdf) async {
    final file = File(pdf.localPath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      debugPrint('ResultPDF file not found or empty: ${pdf.localPath}');
      return false;
    }
    // منع التكرار
    _resultPdfs.removeWhere((f) => f.localPath == pdf.localPath || f.id == pdf.id);
    _resultPdfs.insert(0, pdf);
    notifyListeners();
    await _saveResultPdfs();
    return true;
  }

  Future<void> removeResultPdf(String id) async {
    final existing = _resultPdfs.where((f) => f.id == id).firstOrNull;
    if (existing != null && existing.localPath.isNotEmpty) {
      try {
        final file = File(existing.localPath);
        if (file.existsSync()) await file.delete();
      } catch (e) {
        debugPrint('Error deleting PDF file: $e');
      }
    }
    _resultPdfs.removeWhere((f) => f.id == id);
    notifyListeners();
    await _saveResultPdfs();
  }

  Future<void> _saveResultPdfs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_resultPdfs.map((f) => f.toMap()).toList());
    await prefs.setString(_resultPdfsKey, jsonStr);
  }

  /// حذف سجلات الملفات غير الموجودة على القرص
  Future<void> cleanupMissingFiles() async {
    bool changed = false;
    _resultPdfs.removeWhere((f) {
      final exists = File(f.localPath).existsSync();
      if (!exists) changed = true;
      return !exists;
    });
    if (changed) {
      notifyListeners();
      await _saveResultPdfs();
    }
  }
}
