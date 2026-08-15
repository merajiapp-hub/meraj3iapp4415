// lib/models/result_pdf_file.dart
// نموذج بيانات لملفات PDF النتائج المحفوظة

class ResultPdfFile {
  final String id;           // معرف فريد (timestamp)
  final String fileName;     // اسم الملف
  final String localPath;    // المسار المحلي الكامل
  final String title;        // عنوان القائمة (الناجحون/الراسبون)
  final String competition;  // اسم المسابقة
  final String listType;     // 'passed' | 'failed' | 'student' | 'all'
  final double fileSizeMb;
  final DateTime savedAt;
  final int studentCount;

  ResultPdfFile({
    required this.id,
    required this.fileName,
    required this.localPath,
    required this.title,
    required this.competition,
    required this.listType,
    required this.fileSizeMb,
    required this.savedAt,
    required this.studentCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'localPath': localPath,
        'title': title,
        'competition': competition,
        'listType': listType,
        'fileSizeMb': fileSizeMb,
        'savedAt': savedAt.toIso8601String(),
        'studentCount': studentCount,
      };

  factory ResultPdfFile.fromMap(Map<String, dynamic> map) => ResultPdfFile(
        id: map['id'] ?? '',
        fileName: map['fileName'] ?? '',
        localPath: map['localPath'] ?? '',
        title: map['title'] ?? '',
        competition: map['competition'] ?? '',
        listType: map['listType'] ?? 'all',
        fileSizeMb: (map['fileSizeMb'] as num?)?.toDouble() ?? 0.0,
        savedAt: DateTime.tryParse(map['savedAt'] ?? '') ?? DateTime.now(),
        studentCount: (map['studentCount'] as num?)?.toInt() ?? 0,
      );

  String get listTypeLabel {
    switch (listType) {
      case 'passed':
        return '✅ قائمة الناجحين';
      case 'failed':
        return '❌ قائمة الراسبين';
      case 'student':
        return '🎓 بطاقة طالب';
      default:
        return '📄 قائمة النتائج';
    }
  }

  String get formattedSize {
    if (fileSizeMb < 0.1) return '< 0.1 MB';
    return '${fileSizeMb.toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final d = savedAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
