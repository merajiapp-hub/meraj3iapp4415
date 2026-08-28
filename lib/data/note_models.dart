import 'package:cloud_firestore/cloud_firestore.dart';

class NoteFolder {
  final String id;
  final String name;
  final int? color;
  final String? parentId;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteFolder({
    required this.id,
    required this.name,
    this.color,
    this.parentId,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteFolder.fromMap(String id, Map<String, dynamic> map) {
    return NoteFolder(
      id: id,
      name: map['name'] ?? '',
      color: map['color'],
      parentId: map['parentId'],
      order: map['order'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'parentId': parentId,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class NoteTag {
  final String id;
  final String name;
  final int? color;

  NoteTag({
    required this.id,
    required this.name,
    this.color,
  });

  factory NoteTag.fromMap(String id, Map<String, dynamic> map) {
    return NoteTag(
      id: id,
      name: map['name'] ?? '',
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
    };
  }
}

class NotePageSettings {
  final String paperType; // 'blank', 'horizontal', 'vertical', 'grid', 'dots', 'school'
  final int? paperColor;
  final bool isDark;
  final double lineSpacing;
  final int? lineColor;
  final double lineOpacity;

  NotePageSettings({
    this.paperType = 'blank',
    this.paperColor,
    this.isDark = false,
    this.lineSpacing = 30.0,
    this.lineColor,
    this.lineOpacity = 0.2,
  });

  factory NotePageSettings.fromMap(Map<String, dynamic> map) {
    return NotePageSettings(
      paperType: map['paperType'] ?? 'blank',
      paperColor: map['paperColor'],
      isDark: map['isDark'] ?? false,
      lineSpacing: (map['lineSpacing'] ?? 30.0).toDouble(),
      lineColor: map['lineColor'],
      lineOpacity: (map['lineOpacity'] ?? 0.2).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paperType': paperType,
      'paperColor': paperColor,
      'isDark': isDark,
      'lineSpacing': lineSpacing,
      'lineColor': lineColor,
      'lineOpacity': lineOpacity,
    };
  }
}

class NoteAttachment {
  final String id;
  final String type; // 'image', 'pdf', 'audio', 'file'
  final String url;
  final String name;
  final int size; // bytes
  final DateTime createdAt;

  NoteAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    required this.size,
    required this.createdAt,
  });

  factory NoteAttachment.fromMap(String id, Map<String, dynamic> map) {
    return NoteAttachment(
      id: id,
      type: map['type'] ?? 'file',
      url: map['url'] ?? '',
      name: map['name'] ?? '',
      size: map['size'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'url': url,
      'name': name,
      'size': size,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Note {
  final String id;
  final String title;
  final String content; // JSON string from Quill
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Organization
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? folderId;
  final List<String> tags;
  
  // Meta
  final int? color;
  final DateTime? reminderTime;
  final int wordCount;
  final int pageCount;
  
  // Advanced Settings & Content
  final NotePageSettings? pageSettings;
  final List<NoteAttachment> attachments;
  final List<Map<String, dynamic>> drawings; // Signature/Drawing data

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
    this.folderId,
    this.tags = const [],
    this.color,
    this.reminderTime,
    this.wordCount = 0,
    this.pageCount = 1,
    this.pageSettings,
    this.attachments = const [],
    this.drawings = const [],
  });

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: map['isPinned'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      isArchived: map['isArchived'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      folderId: map['folderId'],
      tags: List<String>.from(map['tags'] ?? []),
      color: map['color'],
      reminderTime: (map['reminderTime'] as Timestamp?)?.toDate(),
      wordCount: map['wordCount'] ?? 0,
      pageCount: map['pageCount'] ?? 1,
      pageSettings: map['pageSettings'] != null ? NotePageSettings.fromMap(map['pageSettings']) : null,
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((e) => NoteAttachment.fromMap(e['id'] ?? '', e as Map<String, dynamic>))
              .toList() ??
          [],
      drawings: (map['drawings'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'folderId': folderId,
      'tags': tags,
      'color': color,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'wordCount': wordCount,
      'pageCount': pageCount,
      'pageSettings': pageSettings?.toMap(),
      'attachments': attachments.map((e) {
        final m = e.toMap();
        m['id'] = e.id;
        return m;
      }).toList(),
      'drawings': drawings,
    };
  }
}
