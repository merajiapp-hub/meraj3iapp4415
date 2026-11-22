import 'package:cloud_firestore/cloud_firestore.dart';

/// 1. المرحلة أو القسم الدراسي
class VideoLevel {
  final String id;
  final String title;
  final String code;
  final String description;
  final String iconName;
  final int orderIndex;
  final bool isActive;
  final int colorHex;
  final int subjectsCount;
  final int lessonsCount;

  const VideoLevel({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    this.iconName = 'school',
    this.orderIndex = 0,
    this.isActive = true,
    this.colorHex = 0xFF14B8A6,
    this.subjectsCount = 0,
    this.lessonsCount = 0,
  });

  factory VideoLevel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VideoLevel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      code: data['code']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      iconName: data['iconName']?.toString() ?? 'school',
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
      colorHex: (data['colorHex'] as num?)?.toInt() ?? 0xFF14B8A6,
      subjectsCount: (data['subjectsCount'] as num?)?.toInt() ?? 0,
      lessonsCount: (data['lessonsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'code': code,
      'description': description,
      'iconName': iconName,
      'orderIndex': orderIndex,
      'isActive': isActive,
      'colorHex': colorHex,
      'subjectsCount': subjectsCount,
      'lessonsCount': lessonsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// 2. المادة الدراسية
class VideoSubject {
  final String id;
  final String levelId;
  final String title;
  final String iconName;
  final int colorHex;
  final int orderIndex;
  final bool hasUnits;
  final int unitsCount;
  final int lessonsCount;
  final bool isActive;

  const VideoSubject({
    required this.id,
    required this.levelId,
    required this.title,
    this.iconName = 'menu_book',
    this.colorHex = 0xFF14B8A6,
    this.orderIndex = 0,
    this.hasUnits = false,
    this.unitsCount = 0,
    this.lessonsCount = 0,
    this.isActive = true,
  });

  factory VideoSubject.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VideoSubject(
      id: doc.id,
      levelId: data['levelId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      iconName: data['iconName']?.toString() ?? 'menu_book',
      colorHex: (data['colorHex'] as num?)?.toInt() ?? 0xFF14B8A6,
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      hasUnits: data['hasUnits'] == true,
      unitsCount: (data['unitsCount'] as num?)?.toInt() ?? 0,
      lessonsCount: (data['lessonsCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'title': title,
      'iconName': iconName,
      'colorHex': colorHex,
      'orderIndex': orderIndex,
      'hasUnits': hasUnits,
      'unitsCount': unitsCount,
      'lessonsCount': lessonsCount,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// 3. الوحدة التعليمية
class VideoUnit {
  final String id;
  final String levelId;
  final String subjectId;
  final String title;
  final String description;
  final int orderIndex;
  final int lessonsCount;
  final bool isActive;

  const VideoUnit({
    required this.id,
    required this.levelId,
    required this.subjectId,
    required this.title,
    this.description = '',
    this.orderIndex = 0,
    this.lessonsCount = 0,
    this.isActive = true,
  });

  factory VideoUnit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VideoUnit(
      id: doc.id,
      levelId: data['levelId']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      lessonsCount: (data['lessonsCount'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'orderIndex': orderIndex,
      'lessonsCount': lessonsCount,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// 4. الأستاذ / المحاضر
class VideoTeacher {
  final String id;
  final String name;
  final String photoUrl;
  final String? drivePhotoId;
  final String specialty;
  final String bio;
  final int lessonsCount;
  final int orderIndex;
  final bool isActive;

  const VideoTeacher({
    required this.id,
    required this.name,
    this.photoUrl = '',
    this.drivePhotoId,
    this.specialty = '',
    this.bio = '',
    this.lessonsCount = 0,
    this.orderIndex = 0,
    this.isActive = true,
  });

  factory VideoTeacher.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VideoTeacher(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      drivePhotoId: data['drivePhotoId']?.toString(),
      specialty: data['specialty']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      lessonsCount: (data['lessonsCount'] as num?)?.toInt() ?? 0,
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'drivePhotoId': drivePhotoId,
      'specialty': specialty,
      'bio': bio,
      'lessonsCount': lessonsCount,
      'orderIndex': orderIndex,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get effectivePhotoUrl {
    if (photoUrl.isNotEmpty) {
      if (photoUrl.contains('drive.google.com')) {
        final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(photoUrl) ??
            RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(photoUrl);
        if (match != null) {
          return 'https://drive.google.com/thumbnail?id=${match.group(1)}&sz=w600';
        }
      }
      return photoUrl;
    }
    if (drivePhotoId != null && drivePhotoId!.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$drivePhotoId&sz=w600';
    }
    return '';
  }
}

/// 5. الملفات والمذكرات المرفقة بالدرس
class VideoAttachment {
  final String id;
  final String title;
  final String url;
  final String type; // 'summary', 'exercises', 'solution', 'document'
  final String fileSize;

  const VideoAttachment({
    required this.id,
    required this.title,
    required this.url,
    this.type = 'summary',
    this.fileSize = '',
  });

  factory VideoAttachment.fromMap(Map<String, dynamic> map) {
    return VideoAttachment(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      type: map['type']?.toString() ?? 'summary',
      fileSize: map['fileSize']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'type': type,
      'fileSize': fileSize,
    };
  }
}

/// 6. أسئلة الاختبار القصير المرتبط بالدرس
class VideoQuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const VideoQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  factory VideoQuizQuestion.fromMap(Map<String, dynamic> map) {
    return VideoQuizQuestion(
      id: map['id']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      options: (map['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

/// 7. الدرس / الفيديو التعليمي
class VideoLesson {
  final String id;
  final String levelId;
  final String subjectId;
  final String? unitId;
  final String? teacherId;
  final String? teacherName;
  final String? teacherPhotoUrl;
  final String title;
  final String description;
  final String videoUrl;
  final String? driveFileId;
  final String? thumbnailUrl;
  final String duration;
  final bool isPro;
  final bool isPublished;
  final bool allowDownload;
  final int orderIndex;
  final int viewsCount;
  final double ratingAverage;
  final int ratingsCount;
  final String? attachmentUrl;
  final String? attachmentName;
  final List<VideoAttachment> pdfFiles;
  final List<VideoQuizQuestion> quizQuestions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VideoLesson({
    required this.id,
    required this.levelId,
    required this.subjectId,
    this.unitId,
    this.teacherId,
    this.teacherName,
    this.teacherPhotoUrl,
    required this.title,
    this.description = '',
    required this.videoUrl,
    this.driveFileId,
    this.thumbnailUrl,
    this.duration = '',
    this.isPro = false,
    this.isPublished = true,
    this.allowDownload = true,
    this.orderIndex = 0,
    this.viewsCount = 0,
    this.ratingAverage = 5.0,
    this.ratingsCount = 0,
    this.attachmentUrl,
    this.attachmentName,
    this.pdfFiles = const [],
    this.quizQuestions = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory VideoLesson.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    final rawPdfs = data['pdfFiles'];
    final pdfList = <VideoAttachment>[];
    if (rawPdfs is List) {
      for (final item in rawPdfs) {
        if (item is Map<String, dynamic>) {
          pdfList.add(VideoAttachment.fromMap(item));
        }
      }
    }
    // دعم الحقل المفرد القديم
    final singleAttachUrl = data['attachmentUrl']?.toString();
    if (singleAttachUrl != null && singleAttachUrl.isNotEmpty && pdfList.isEmpty) {
      pdfList.add(VideoAttachment(
        id: 'legacy_pdf',
        title: data['attachmentName']?.toString() ?? 'ملخص الدرس PDF',
        url: singleAttachUrl,
        type: 'summary',
      ));
    }

    final rawQuiz = data['quizQuestions'];
    final quizList = <VideoQuizQuestion>[];
    if (rawQuiz is List) {
      for (final item in rawQuiz) {
        if (item is Map<String, dynamic>) {
          quizList.add(VideoQuizQuestion.fromMap(item));
        }
      }
    }

    return VideoLesson(
      id: doc.id,
      levelId: data['levelId']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
      unitId: data['unitId']?.toString(),
      teacherId: data['teacherId']?.toString(),
      teacherName: data['teacherName']?.toString(),
      teacherPhotoUrl: data['teacherPhotoUrl']?.toString(),
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? '',
      driveFileId: data['driveFileId']?.toString(),
      thumbnailUrl: data['thumbnailUrl']?.toString(),
      duration: data['duration']?.toString() ?? '',
      isPro: data['isPro'] == true,
      isPublished: data['isPublished'] != false,
      allowDownload: data['allowDownload'] != false,
      orderIndex: (data['orderIndex'] as num?)?.toInt() ?? 0,
      viewsCount: (data['viewsCount'] as num?)?.toInt() ?? 0,
      ratingAverage: (data['ratingAverage'] as num?)?.toDouble() ?? 5.0,
      ratingsCount: (data['ratingsCount'] as num?)?.toInt() ?? 0,
      attachmentUrl: singleAttachUrl,
      attachmentName: data['attachmentName']?.toString(),
      pdfFiles: pdfList,
      quizQuestions: quizList,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'subjectId': subjectId,
      'unitId': unitId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'teacherPhotoUrl': teacherPhotoUrl,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'driveFileId': driveFileId,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'isPro': isPro,
      'isPublished': isPublished,
      'allowDownload': allowDownload,
      'orderIndex': orderIndex,
      'viewsCount': viewsCount,
      'ratingAverage': ratingAverage,
      'ratingsCount': ratingsCount,
      'attachmentUrl': attachmentUrl,
      'attachmentName': attachmentName,
      'pdfFiles': pdfFiles.map((p) => p.toMap()).toList(),
      'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get previewUrl {
    if (driveFileId != null && driveFileId!.isNotEmpty) {
      return 'https://drive.google.com/file/d/$driveFileId/preview';
    }
    return videoUrl;
  }

  String get effectiveThumbnailUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      if (thumbnailUrl!.contains('drive.google.com')) {
        final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(thumbnailUrl!) ??
            RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(thumbnailUrl!);
        if (match != null) {
          return 'https://drive.google.com/thumbnail?id=${match.group(1)}&sz=w800';
        }
      }
      return thumbnailUrl!;
    }
    if (driveFileId != null && driveFileId!.isNotEmpty) {
      return 'https://drive.google.com/thumbnail?id=$driveFileId&sz=w800';
    }
    return '';
  }

  bool get isNew {
    final diff = DateTime.now().difference(createdAt).inDays;
    return diff <= 7;
  }
}

/// 8. تقدم المستخدم في الدروس مع حفظ موضع التوقف
class VideoProgress {
  final String id;
  final String userId;
  final String lessonId;
  final String subjectId;
  final String levelId;
  final bool isCompleted;
  final DateTime lastWatchedAt;
  final int lastPositionSeconds;
  final int totalDurationSeconds;

  const VideoProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.subjectId,
    required this.levelId,
    required this.isCompleted,
    required this.lastWatchedAt,
    this.lastPositionSeconds = 0,
    this.totalDurationSeconds = 0,
  });

  double get progressPercent {
    if (totalDurationSeconds <= 0) return 0.0;
    return (lastPositionSeconds / totalDurationSeconds).clamp(0.0, 1.0);
  }

  factory VideoProgress.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return VideoProgress(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      lessonId: data['lessonId']?.toString() ?? '',
      subjectId: data['subjectId']?.toString() ?? '',
      levelId: data['levelId']?.toString() ?? '',
      isCompleted: data['isCompleted'] == true,
      lastWatchedAt:
          (data['lastWatchedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPositionSeconds:
          (data['lastPositionSeconds'] as num?)?.toInt() ??
          (data['watchedDurationSeconds'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (data['totalDurationSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'subjectId': subjectId,
      'levelId': levelId,
      'isCompleted': isCompleted,
      'lastWatchedAt': FieldValue.serverTimestamp(),
      'lastPositionSeconds': lastPositionSeconds,
      'totalDurationSeconds': totalDurationSeconds,
    };
  }
}

/// 9. ملاحظات الطالب الشخصية على الدرس
class VideoNote {
  final String id;
  final String userId;
  final String lessonId;
  final String content;
  final int timestampSeconds;
  final String? tag;
  final DateTime updatedAt;

  const VideoNote({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.content,
    this.timestampSeconds = 0,
    this.tag,
    required this.updatedAt,
  });

  String get formattedTimestamp {
    final m = timestampSeconds ~/ 60;
    final s = timestampSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  factory VideoNote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VideoNote(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      lessonId: data['lessonId']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      timestampSeconds: (data['timestampSeconds'] as num?)?.toInt() ?? 0,
      tag: data['tag']?.toString(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'content': content,
      'timestampSeconds': timestampSeconds,
      'tag': tag,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// 10. عنصر التنزيل المحفوظ في الجهاز
class VideoDownloadItem {
  final String lessonId;
  final String title;
  final String subjectName;
  final String levelCode;
  final String duration;
  final String localFilePath;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final String? thumbnailUrl;
  final bool isPro;

  const VideoDownloadItem({
    required this.lessonId,
    required this.title,
    required this.subjectName,
    required this.levelCode,
    this.duration = '',
    required this.localFilePath,
    required this.fileSizeBytes,
    required this.downloadedAt,
    this.thumbnailUrl,
    this.isPro = false,
  });

  factory VideoDownloadItem.fromJson(Map<String, dynamic> json) {
    return VideoDownloadItem(
      lessonId: json['lessonId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      levelCode: json['levelCode']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      localFilePath: json['localFilePath']?.toString() ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      downloadedAt: DateTime.tryParse(json['downloadedAt']?.toString() ?? '') ?? DateTime.now(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isPro: json['isPro'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'title': title,
      'subjectName': subjectName,
      'levelCode': levelCode,
      'duration': duration,
      'localFilePath': localFilePath,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      'isPro': isPro,
    };
  }

  String get formattedSize {
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 11. التعليقات ونقاشات الدرس وسؤال الأستاذ
class VideoComment {
  final String id;
  final String lessonId;
  final String userId;
  final String userName;
  final String userRole; // 'طالب', 'أستاذ المادة', 'المعلم', 'إدارة المنصة'
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final List<String> likedUserIds;
  final bool isQuestionToTeacher;
  final bool isAnswered;
  final String? replyToId;
  final String? replyToName;
  final String? attachmentUrl;

  const VideoComment({
    required this.id,
    required this.lessonId,
    required this.userId,
    required this.userName,
    this.userRole = 'طالب',
    this.userAvatarUrl,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.likedUserIds = const [],
    this.isQuestionToTeacher = false,
    this.isAnswered = false,
    this.replyToId,
    this.replyToName,
    this.attachmentUrl,
  });

  factory VideoComment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return VideoComment(
      id: doc.id,
      lessonId: data['lessonId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'طالب مراجعي',
      userRole: data['userRole']?.toString() ?? 'طالب',
      userAvatarUrl: data['userAvatarUrl']?.toString(),
      content: data['content']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      likedUserIds:
          (data['likedUserIds'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isQuestionToTeacher: data['isQuestionToTeacher'] == true,
      isAnswered: data['isAnswered'] == true,
      replyToId: data['replyToId']?.toString(),
      replyToName: data['replyToName']?.toString(),
      attachmentUrl: data['attachmentUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userAvatarUrl': userAvatarUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': likesCount,
      'likedUserIds': likedUserIds,
      'isQuestionToTeacher': isQuestionToTeacher,
      'isAnswered': isAnswered,
      'replyToId': replyToId,
      'replyToName': replyToName,
      'attachmentUrl': attachmentUrl,
    };
  }
}
