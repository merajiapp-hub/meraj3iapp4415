import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/drive_url_service.dart';

class Book {
  final String id;
  final String title;
  final String? subtitle;
  final String section; // المرحلة الدراسية
  final String grade; // السنة الدراسية
  final String category; // التصنيف (كتب مدرسية، مراجع، امتحانات...)
  final String subject; // المادة (رياضيات، عربية...)
  final String url; // الرابط الأصلي — لا يُعدَّل أبداً
  final String solutionUrl;
  final String coverUrl;
  final String uploaderId;
  // حقول إضافية للدعم الذكي
  final String? originalDriveUrl;
  final String? extractedFileId;
  final String? linkStatus;
  final bool isActive;
  final DateTime? addedAt;
  
  // New fields for hierarchical categories
  final String? categoryId;
  final List<String>? categoryPath;
  final List<String> categoryIds;

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
    this.originalDriveUrl,
    this.extractedFileId,
    this.linkStatus,
    this.isActive = true,
    this.addedAt,
    this.categoryId,
    this.categoryPath,
    this.categoryIds = const [],
  });

  /// مفتاح فريد يجمع كل خصائص الكتاب لتجنب التكرار
  String get uniqueKey => '${section}_${grade}_${category}_${title}_$id';

  /// FILE_ID المستخرج من الرابط (الأصلي أو المستخرج مسبقاً)
  String? get resolvedFileId {
    if (extractedFileId != null && extractedFileId!.isNotEmpty) {
      return extractedFileId;
    }
    return DriveUrlService.extractFileId(url) ??
        DriveUrlService.extractFileId(originalDriveUrl);
  }

  /// رابط الصورة المصغرة (Thumbnail)
  String? get thumbnailUrl {
    // إذا كان هناك coverUrl صريح، استخدمه
    if (coverUrl.isNotEmpty && !coverUrl.contains('drive.google.com')) {
      return coverUrl;
    }
    final fileId = resolvedFileId;
    if (fileId != null) {
      return DriveUrlService.getThumbnailUrl(fileId);
    }
    // إذا كان coverUrl من Drive، استخدمه مباشرةً
    if (coverUrl.isNotEmpty) return coverUrl;
    return null;
  }

  /// الرابط المعياري للفتح
  String get normalizedUrl {
    final fileId = resolvedFileId;
    if (fileId != null) {
      return DriveUrlService.getNormalizedUrl(fileId);
    }
    return url;
  }

  /// حالة الرابط
  String get resolvedLinkStatus {
    if (linkStatus != null && linkStatus!.isNotEmpty) return linkStatus!;
    return DriveUrlService.getUrlStatus(url);
  }

  /// هل الرابط صالح من حيث الصيغة؟
  bool get hasValidLink {
    return resolvedFileId != null || url.isNotEmpty;
  }

  factory Book.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? addedAt;
    final rawDate = map['uploadDate'] ??
        map['createdAt'] ??
        map['created_at'] ??
        map['addedAt'] ??
        map['updatedAt'];
    if (rawDate is Timestamp) {
      addedAt = rawDate.toDate();
    } else if (rawDate is DateTime) {
      addedAt = rawDate;
    } else if (rawDate is Map && rawDate['_seconds'] is num) {
      addedAt = DateTime.fromMillisecondsSinceEpoch(
        (rawDate['_seconds'] as num).toInt() * 1000,
      );
    }

    String value(String key, [String fallback = '']) =>
        (map[key] ?? fallback).toString().trim();

    final rawSection = value('section', value('stage'));
    final rawGrade = value('grade', value('year'));
    final rawCategory = value('category', value('type', value('bookType')));
    final rawSubject = value('subject', value('material'));
    final rawUrl = value('url', value('drive_link', value('pdfUrl', value('fileUrl', value('downloadUrl')))));
    
    List<String>? parsedCategoryPath;
    if (map['categoryPath'] != null) {
      if (map['categoryPath'] is List) {
        parsedCategoryPath = List<String>.from(map['categoryPath']);
      } else if (map['categoryPath'] is String) {
        parsedCategoryPath = (map['categoryPath'] as String).split(',').map((e) => e.trim()).toList();
      }
    }

    return Book(
      id: documentId.isNotEmpty ? documentId : value('id'),
      title: value('title', value('name')),
      subtitle: value('subtitle').isEmpty ? null : value('subtitle'),
      section: rawSection,
      grade: rawGrade,
      category: rawCategory,
      subject: rawSubject,
      url: rawUrl,
      solutionUrl: value('solutionUrl'),
      coverUrl: value('coverUrl', value('imageUrl', value('thumbnailUrl'))),
      uploaderId: value('uploaderId', value('userId')),
      originalDriveUrl: value('originalDriveUrl', value('url', value('drive_link'))).isEmpty
          ? null
          : value('originalDriveUrl', value('url', value('drive_link'))),
      extractedFileId: value('extractedFileId').isEmpty
          ? null
          : value('extractedFileId'),
      linkStatus: value('linkStatus').isEmpty ? null : value('linkStatus'),
      isActive: map['is_active'] ?? map['isActive'] ?? true,
      addedAt: addedAt,
      categoryId: map['categoryId'] as String?,
      categoryPath: parsedCategoryPath,
      categoryIds: map['categoryIds'] != null
          ? List<String>.from(map['categoryIds'])
          : (map['categoryId'] != null ? [map['categoryId'].toString()] : []),
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
      'originalDriveUrl': originalDriveUrl ?? url,
      'extractedFileId': extractedFileId ?? resolvedFileId,
      'linkStatus': linkStatus,
      'is_active': isActive,
      'isActive': isActive,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryPath != null) 'categoryPath': categoryPath,
    };
  }

  /// نسخ الكتاب مع تحديث حقول معيّنة فقط (الكتاب نفسه — لا يُنشأ كتاب جديد)
  Book copyWith({
    String? title,
    String? url,
    String? coverUrl,
    String? linkStatus,
    String? extractedFileId,
    String? category,
    String? grade,
    String? categoryId,
    List<String>? categoryPath,
  }) {
    return Book(
      id: id, // ← id لا يتغير أبداً
      title: title ?? this.title,
      subtitle: subtitle,
      section: section,
      grade: grade ?? this.grade,
      category: category ?? this.category,
      subject: subject,
      url: url ?? this.url,
      solutionUrl: solutionUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      uploaderId: uploaderId,
      originalDriveUrl: originalDriveUrl ?? this.url,
      extractedFileId: extractedFileId ?? this.extractedFileId,
      linkStatus: linkStatus ?? this.linkStatus,
      isActive: isActive,
      addedAt: addedAt,
      categoryId: categoryId ?? this.categoryId,
      categoryPath: categoryPath ?? this.categoryPath,
    );
  }

  @override
  String toString() =>
      'Book(id: $id, title: $title, section: $section, grade: $grade, linkStatus: $resolvedLinkStatus)';
}
