class Book {
  final String id;
  final String title;
  final String? subtitle;
  final String section; // المرحلة الدراسية
  final String grade; // السنة الدراسية
  final String category; // التصنيف (كتب مدرسية، مراجع، امتحانات...)
  final String subject; // المادة (رياضيات، عربية...)
  final String url;
  final String solutionUrl;
  final String coverUrl;
  final String uploaderId;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    required this.section,
    required this.grade,
    required this.category,
    this.subject = '',
    required this.url,
    this.solutionUrl = '',
    this.coverUrl = '',
    this.uploaderId = '',
  });

  /// مفتاح فريد يجمع كل خصائص الكتاب لتجنب التكرار
  String get uniqueKey => '${section}_${grade}_${category}_${title}_$id';

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    return Book(
      id: documentId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      section: map['section'] ?? '',
      grade: map['grade'] ?? '',
      category: map['category'] ?? '',
      subject: map['subject'] ?? '',
      url: map['url'] ?? '',
      solutionUrl: map['solutionUrl'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'section': section,
      'grade': grade,
      'category': category,
      'subject': subject,
      'url': url,
      'solutionUrl': solutionUrl,
      'coverUrl': coverUrl,
      'uploaderId': uploaderId,
    };
  }

  @override
  String toString() =>
      'Book(id: $id, title: $title, section: $section, grade: $grade)';
}
