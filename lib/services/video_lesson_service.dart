import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_lesson_models.dart';

class VideoLessonService {
  final FirebaseFirestore _firestore;

  VideoLessonService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _levelsCol =>
      _firestore.collection('video_levels');
  CollectionReference<Map<String, dynamic>> get _subjectsCol =>
      _firestore.collection('video_subjects');
  CollectionReference<Map<String, dynamic>> get _unitsCol =>
      _firestore.collection('video_units');
  CollectionReference<Map<String, dynamic>> get _teachersCol =>
      _firestore.collection('video_teachers');
  CollectionReference<Map<String, dynamic>> get _lessonsCol =>
      _firestore.collection('video_lessons');
  CollectionReference<Map<String, dynamic>> get _progressCol =>
      _firestore.collection('video_progress');
  CollectionReference<Map<String, dynamic>> get _favoritesCol =>
      _firestore.collection('video_favorites');
  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _firestore.collection('video_notes');
  CollectionReference<Map<String, dynamic>> get _commentsCol =>
      _firestore.collection('video_comments');
  CollectionReference<Map<String, dynamic>> get _quizResultsCol =>
      _firestore.collection('video_quiz_results');
  CollectionReference<Map<String, dynamic>> get _statisticsCol =>
      _firestore.collection('video_statistics');

  /// المراحل والأقسام الستة المعتمدة حصراً
  static const List<VideoLevel> defaultLevels = [
    VideoLevel(
      id: 'concours',
      title: 'مسابقة دخول السنة الأولى الإعدادية (كونكور)',
      code: 'كونكور',
      description: 'دروس وتمارين وشروحات مصورة لمسابقة دخول الإعدادية',
      iconName: 'child_care',
      orderIndex: 1,
      colorHex: 0xFF14B8A6,
    ),
    VideoLevel(
      id: '3as',
      title: 'السنة الثالثة إعدادي (3AS)',
      code: '3AS',
      description: 'دروس وفيديوهات تعليمية شاملة لجميع مواد السنة الثالثة إعدادي',
      iconName: 'school',
      orderIndex: 2,
      colorHex: 0xFF3B82F6,
    ),
    VideoLevel(
      id: '4as',
      title: 'السنة الرابعة إعدادي (4AS)',
      code: '4AS',
      description: 'تحضير شهادة ختم الدروس الإعدادية بدروس وتمارين مصورة',
      iconName: 'menu_book',
      orderIndex: 3,
      colorHex: 0xFF8B5CF6,
    ),
    VideoLevel(
      id: 'bac_d',
      title: 'البكالوريا العلمية (BAC D)',
      code: 'BAC D',
      description: 'شروحات دقيقة لمواد العلوم والرياضيات والفيزياء لبكالوريا D',
      iconName: 'science',
      orderIndex: 4,
      colorHex: 0xFF10B981,
    ),
    VideoLevel(
      id: 'bac_c',
      title: 'البكالوريا الرياضية (BAC C)',
      code: 'BAC C',
      description: 'دروس متعمقة في الرياضيات والفيزياء والكيمياء لبكالوريا C',
      iconName: 'calculate',
      orderIndex: 5,
      colorHex: 0xFFF59E0B,
    ),
    VideoLevel(
      id: '6af',
      title: 'البكالوريا الأدبية (6AF)',
      code: '6AF',
      description: 'دروس مقسمة حسب الوحدات لمواد الفلسفة واللغة العربية والآداب',
      iconName: 'history_edu',
      orderIndex: 6,
      colorHex: 0xFFEC4899,
    ),
  ];

  /// بث المراحل الستة
  Stream<List<VideoLevel>> streamLevels() {
    return _levelsCol.snapshots().map((snap) {
      if (snap.docs.isEmpty) return defaultLevels;
      final list = snap.docs.map(VideoLevel.fromFirestore).toList();
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return list.where((lvl) => lvl.isActive).toList();
    });
  }

  /// بث المواد الخاصة بمرحلة محددة
  Stream<List<VideoSubject>> streamSubjects(String levelId) {
    return _subjectsCol
        .where('levelId', isEqualTo: levelId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoSubject.fromFirestore).toList();
          list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return list.where((s) => s.isActive).toList();
        });
  }

  /// بث الوحدات الخاصة بمادة محددة
  Stream<List<VideoUnit>> streamUnits(String subjectId) {
    return _unitsCol
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoUnit.fromFirestore).toList();
          list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return list.where((u) => u.isActive).toList();
        });
  }

  /// بث الأساتذة
  Stream<List<VideoTeacher>> streamTeachers() {
    return _teachersCol.snapshots().map((snap) {
      final list = snap.docs.map(VideoTeacher.fromFirestore).toList();
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return list.where((t) => t.isActive).toList();
    });
  }

  Future<VideoTeacher?> getTeacher(String teacherId) async {
    try {
      final doc = await _teachersCol.doc(teacherId).get();
      if (!doc.exists) return null;
      return VideoTeacher.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// بث دروس أستاذ معين
  Stream<List<VideoLesson>> streamLessonsByTeacher(String teacherId) {
    return _lessonsCol
        .where('teacherId', isEqualTo: teacherId)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoLesson.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// بث الدروس المنشورة حسب المادة والمرحلة والوحدة
  Stream<List<VideoLesson>> streamLessons({
    required String levelId,
    required String subjectId,
    String? unitId,
  }) {
    Query<Map<String, dynamic>> query = _lessonsCol
        .where('levelId', isEqualTo: levelId)
        .where('subjectId', isEqualTo: subjectId)
        .where('isPublished', isEqualTo: true);

    if (unitId != null && unitId.isNotEmpty) {
      query = query.where('unitId', isEqualTo: unitId);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map(VideoLesson.fromFirestore).toList();
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return list;
    });
  }

  /// بث أحدث الدروس المضافة في المنصة (قسم أحدث الدروس)
  Stream<List<VideoLesson>> streamLatestLessons({int limit = 6}) {
    return _lessonsCol
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoLesson.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(limit).toList();
        });
  }

  /// بث تقدم المستخدم في مادة محددة
  Stream<Map<String, bool>> streamSubjectProgress({
    required String userId,
    required String subjectId,
  }) {
    if (userId.isEmpty) return Stream.value({});
    return _progressCol
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snap) {
          final map = <String, bool>{};
          for (final doc in snap.docs) {
            final data = doc.data();
            final lessonId = data['lessonId']?.toString() ?? '';
            final completed = data['isCompleted'] == true;
            if (lessonId.isNotEmpty) {
              map[lessonId] = completed;
            }
          }
          return map;
        });
  }

  /// بث الدروس التي شاهدها المستخدم مؤخراً (أكمل المشاهدة مع موضع التوقف)
  Stream<List<VideoProgress>> streamRecentWatched(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _progressCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoProgress.fromFirestore).toList();
          list.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
          return list.take(8).toList();
        });
  }

  /// تسجيل تقدم المشاهدة وموضع التوقف الدقيق
  Future<void> recordProgress({
    required String userId,
    required VideoLesson lesson,
    required bool isCompleted,
    int lastPositionSeconds = 0,
    int totalDurationSeconds = 0,
  }) async {
    if (userId.isEmpty) return;
    final docId = '${userId}_${lesson.id}';
    await _progressCol.doc(docId).set({
      'userId': userId,
      'lessonId': lesson.id,
      'subjectId': lesson.subjectId,
      'levelId': lesson.levelId,
      'isCompleted': isCompleted,
      'lastWatchedAt': FieldValue.serverTimestamp(),
      'lastPositionSeconds': lastPositionSeconds,
      'totalDurationSeconds': totalDurationSeconds,
    }, SetOptions(merge: true));
  }

  /// جلب تقدم الدرس المخزن لمعرفة موضع الاستئناف
  Future<VideoProgress?> getLessonProgress(String userId, String lessonId) async {
    if (userId.isEmpty) return null;
    final docId = '${userId}_$lessonId';
    try {
      final doc = await _progressCol.doc(docId).get();
      if (!doc.exists) return null;
      return VideoProgress.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  /// تسجيل زيادة عدد المشاهدات
  Future<void> incrementLessonViews(VideoLesson lesson) async {
    try {
      await _lessonsCol.doc(lesson.id).update({
        'viewsCount': FieldValue.increment(1),
      });

      await _statisticsCol.add({
        'lessonId': lesson.id,
        'levelId': lesson.levelId,
        'subjectId': lesson.subjectId,
        'unitId': lesson.unitId,
        'title': lesson.title,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// المفضلة: فحص وحفظ وبث
  Stream<bool> isFavoriteStream({
    required String userId,
    required String lessonId,
  }) {
    if (userId.isEmpty) return Stream.value(false);
    final docId = '${userId}_$lessonId';
    return _favoritesCol.doc(docId).snapshots().map((doc) => doc.exists);
  }

  Future<bool> toggleFavorite({
    required String userId,
    required String lessonId,
  }) async {
    if (userId.isEmpty) return false;
    final docId = '${userId}_$lessonId';
    final docRef = _favoritesCol.doc(docId);
    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      return false;
    } else {
      await docRef.set({
        'userId': userId,
        'lessonId': lessonId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }

  /// بث الدروس المحفوظة في المفضلة (دروسي المحفوظة)
  Stream<List<String>> streamFavoriteLessonIds(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _favoritesCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((d) => d.data()['lessonId']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
        });
  }

  /// ملاحظات الطالب الشخصية
  Stream<String> streamLessonNote(String userId, String lessonId) {
    if (userId.isEmpty) return Stream.value('');
    final docId = '${userId}_$lessonId';
    return _notesCol.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return '';
      return doc.data()?['content']?.toString() ?? '';
    });
  }

  Future<void> saveLessonNote(String userId, String lessonId, String content) async {
    if (userId.isEmpty) return;
    final docId = '${userId}_$lessonId';
    if (content.trim().isEmpty) {
      await _notesCol.doc(docId).delete();
    } else {
      await _notesCol.doc(docId).set({
        'userId': userId,
        'lessonId': lessonId,
        'content': content.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// تقييم الدرس
  Future<void> rateLesson(String lessonId, double rating) async {
    try {
      final docRef = _lessonsCol.doc(lessonId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final currentAvg = (data['ratingAverage'] as num?)?.toDouble() ?? 5.0;
        final currentCount = (data['ratingsCount'] as num?)?.toInt() ?? 0;
        final newCount = currentCount + 1;
        final newAvg = ((currentAvg * currentCount) + rating) / newCount;
        tx.update(docRef, {
          'ratingAverage': newAvg,
          'ratingsCount': newCount,
        });
      });
    } catch (_) {}
  }

  /// بث الدروس الأكثر مشاهدة
  Stream<List<VideoLesson>> streamMostWatchedLessons({int limit = 6}) {
    return _lessonsCol
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoLesson.fromFirestore).toList();
          list.sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
          return list.take(limit).toList();
        });
  }

  /// بث جميع دروس مرحلة دراسية معينة
  Stream<List<VideoLesson>> streamLessonsByLevel(String levelId) {
    return _lessonsCol
        .where('levelId', isEqualTo: levelId)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoLesson.fromFirestore).toList();
          list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          return list;
        });
  }

  /// بث ملاحظات الطالب المرتبطة بالوقت
  Stream<List<VideoNote>> streamTimestampNotes(String userId, String lessonId) {
    if (userId.isEmpty) return Stream.value([]);
    return _notesCol
        .where('userId', isEqualTo: userId)
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoNote.fromFirestore).toList();
          list.sort((a, b) => a.timestampSeconds.compareTo(b.timestampSeconds));
          return list;
        });
  }

  /// إضافة ملاحظة مرتبطة بوقت محدد
  Future<void> addTimestampNote({
    required String userId,
    required String lessonId,
    required String content,
    required int timestampSeconds,
    String? tag,
  }) async {
    if (userId.isEmpty || content.trim().isEmpty) return;
    await _notesCol.add({
      'userId': userId,
      'lessonId': lessonId,
      'content': content.trim(),
      'timestampSeconds': timestampSeconds,
      'tag': tag,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// حذف ملاحظة
  Future<void> deleteTimestampNote(String noteId) async {
    try {
      await _notesCol.doc(noteId).delete();
    } catch (_) {}
  }

  /// بث التعليقات والنقاشات الخاصة بالدرس
  Stream<List<VideoComment>> streamComments(String lessonId) {
    return _commentsCol
        .where('lessonId', isEqualTo: lessonId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(VideoComment.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// إضافة تعليق أو سؤال موجه للأستاذ
  Future<void> addComment({
    required String lessonId,
    required String userId,
    required String userName,
    String userRole = 'طالب',
    String? userAvatarUrl,
    required String content,
    bool isQuestionToTeacher = false,
    String? replyToId,
    String? replyToName,
    String? attachmentUrl,
  }) async {
    if (content.trim().isEmpty) return;
    await _commentsCol.add({
      'lessonId': lessonId,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'userAvatarUrl': userAvatarUrl,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'likedUserIds': [],
      'isQuestionToTeacher': isQuestionToTeacher,
      'isAnswered': false,
      'replyToId': replyToId,
      'replyToName': replyToName,
      'attachmentUrl': attachmentUrl,
    });
  }

  /// الإعجاب بتعليق
  Future<void> toggleCommentLike({
    required String commentId,
    required String userId,
  }) async {
    if (userId.isEmpty) return;
    final docRef = _commentsCol.doc(commentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final likedList = List<String>.from(data['likedUserIds'] ?? []);
      final currentLikes = (data['likesCount'] as num?)?.toInt() ?? 0;
      if (likedList.contains(userId)) {
        likedList.remove(userId);
        tx.update(docRef, {
          'likesCount': (currentLikes - 1).clamp(0, 999999),
          'likedUserIds': likedList,
        });
      } else {
        likedList.add(userId);
        tx.update(docRef, {
          'likesCount': currentLikes + 1,
          'likedUserIds': likedList,
        });
      }
    });
  }

  /// حفظ نتيجة الاختبار القصير
  Future<void> saveQuizResult({
    required String userId,
    required String lessonId,
    required int score,
    required int total,
  }) async {
    if (userId.isEmpty) return;
    final docId = '${userId}_$lessonId';
    await _quizResultsCol.doc(docId).set({
      'userId': userId,
      'lessonId': lessonId,
      'score': score,
      'total': total,
      'percent': total > 0 ? (score / total) : 0.0,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// استرجاع نتيجة الاختبار إن وجدت
  Future<Map<String, dynamic>?> getQuizResult(String userId, String lessonId) async {
    if (userId.isEmpty) return null;
    final docId = '${userId}_$lessonId';
    try {
      final doc = await _quizResultsCol.doc(docId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }
}
