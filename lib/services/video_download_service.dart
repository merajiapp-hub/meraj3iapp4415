import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_lesson_models.dart';
import 'drive_url_service.dart';

class VideoDownloadProgress {
  final int received;
  final int total;

  const VideoDownloadProgress(this.received, this.total);

  double? get progress => total > 0 ? received / total : null;
  int get percentage => total > 0 ? ((received / total) * 100).toInt() : 0;
}

class VideoDownloadService {
  static final VideoDownloadService _instance = VideoDownloadService._internal();
  factory VideoDownloadService() => _instance;
  VideoDownloadService._internal();

  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, StreamController<VideoDownloadProgress>> _progressControllers = {};

  static const String _prefKey = 'offline_video_downloads_v1';

  Stream<VideoDownloadProgress> progressStream(String lessonId) {
    return _progressControllers
        .putIfAbsent(lessonId, () => StreamController<VideoDownloadProgress>.broadcast())
        .stream;
  }

  bool isDownloading(String lessonId) {
    return _cancelTokens.containsKey(lessonId);
  }

  void cancelDownload(String lessonId) {
    final token = _cancelTokens.remove(lessonId);
    token?.cancel('Cancelled by user');
    final ctrl = _progressControllers.remove(lessonId);
    ctrl?.close();
  }

  /// فحص هل الدرس منزل ومحفوظ محلياً
  Future<bool> isLessonDownloaded(String lessonId) async {
    final item = await getDownloadedItem(lessonId);
    if (item == null) return false;
    final file = File(item.localFilePath);
    return file.existsSync();
  }

  Future<VideoDownloadItem?> getDownloadedItem(String lessonId) async {
    final list = await getAllDownloads();
    return list.where((d) => d.lessonId == lessonId).firstOrNull;
  }

  /// جلب جميع الفيديوهات المنزلة
  Future<List<VideoDownloadItem>> getAllDownloads() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_prefKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      final items = decoded.map((e) => VideoDownloadItem.fromJson(e)).toList();
      // التحقق من وجود الملف فعلياً في الجهاز
      final validItems = <VideoDownloadItem>[];
      for (final item in items) {
        if (File(item.localFilePath).existsSync()) {
          validItems.add(item);
        }
      }
      return validItems;
    } catch (_) {
      return [];
    }
  }

  /// حساب إجمالي المساحة المستهلكة للتنزيلات بالبايت
  Future<int> getTotalStorageBytes() async {
    final list = await getAllDownloads();
    int total = 0;
    for (final item in list) {
      total += item.fileSizeBytes;
    }
    return total;
  }

  /// بدء تنزيل الدرس
  Future<String?> downloadLesson({
    required VideoLesson lesson,
    required String subjectName,
    required String levelCode,
  }) async {
    final lessonId = lesson.id;
    if (_cancelTokens.containsKey(lessonId)) {
      return null; // قيد التنزيل بالفعل
    }

    final cancelToken = CancelToken();
    _cancelTokens[lessonId] = cancelToken;

    final streamCtrl = _progressControllers.putIfAbsent(
      lessonId,
      () => StreamController<VideoDownloadProgress>.broadcast(),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final videosDir = Directory('${dir.path}/meraj3i_offline_videos');
      if (!videosDir.existsSync()) {
        videosDir.createSync(recursive: true);
      }

      final targetPath = '${videosDir.path}/lesson_$lessonId.mp4';
      final targetFile = File(targetPath);

      // تحديد رابط التنزيل المباشر
      String downloadUrl = lesson.videoUrl;
      if (lesson.driveFileId != null && lesson.driveFileId!.isNotEmpty) {
        downloadUrl = DriveUrlService.buildDirectDownloadUrl(
          'https://drive.google.com/file/d/${lesson.driveFileId}/view',
        );
      }

      await _dio.download(
        downloadUrl,
        targetPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (!streamCtrl.isClosed) {
            streamCtrl.add(VideoDownloadProgress(received, total));
          }
        },
      );

      final fileSize = targetFile.existsSync() ? targetFile.lengthSync() : 0;

      final downloadItem = VideoDownloadItem(
        lessonId: lessonId,
        title: lesson.title,
        subjectName: subjectName,
        levelCode: levelCode,
        duration: lesson.duration,
        localFilePath: targetPath,
        fileSizeBytes: fileSize,
        downloadedAt: DateTime.now(),
        thumbnailUrl: lesson.effectiveThumbnailUrl,
        isPro: lesson.isPro,
      );

      await _saveDownloadRecord(downloadItem);
      return targetPath;
    } catch (e) {
      // حذف الملف غير المكتمل عند حدوث خطأ
      final dir = await getApplicationDocumentsDirectory();
      final targetFile = File('${dir.path}/meraj3i_offline_videos/lesson_$lessonId.mp4');
      if (targetFile.existsSync()) {
        try {
          targetFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    } finally {
      _cancelTokens.remove(lessonId);
      final ctrl = _progressControllers.remove(lessonId);
      await ctrl?.close();
    }
  }

  Future<void> _saveDownloadRecord(VideoDownloadItem item) async {
    final list = await getAllDownloads();
    list.removeWhere((d) => d.lessonId == item.lessonId);
    list.insert(0, item);

    final sp = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await sp.setString(_prefKey, jsonEncode(jsonList));
  }

  /// حذف درس من التنزيلات
  Future<void> deleteDownload(String lessonId) async {
    final item = await getDownloadedItem(lessonId);
    if (item != null) {
      final file = File(item.localFilePath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }

    final list = await getAllDownloads();
    list.removeWhere((d) => d.lessonId == lessonId);

    final sp = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await sp.setString(_prefKey, jsonEncode(jsonList));
  }

  /// حذف جميع التنزيلات
  Future<void> deleteAllDownloads() async {
    final list = await getAllDownloads();
    for (final item in list) {
      final file = File(item.localFilePath);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    }

    final sp = await SharedPreferences.getInstance();
    await sp.remove(_prefKey);
  }
}
