import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../models/book.dart';
import 'book_cache_service.dart';
import 'drive_url_service.dart';

class BookDownloadProgress {
  final int received;
  final int total;

  const BookDownloadProgress(this.received, this.total);

  double? get value => total > 0 ? received / total : null;
}

class _DownloadTask {
  final CancelToken cancelToken = CancelToken();
  final StreamController<BookDownloadProgress> progress =
      StreamController<BookDownloadProgress>.broadcast();
  late final Future<String> future;
}

class BookDownloadService {
  BookDownloadService({BookCacheService? cache}) : _cache = cache ?? BookCacheService();

  final BookCacheService _cache;
  final Dio _dio = Dio();
  static final Map<String, _DownloadTask> _active = {};

  Stream<BookDownloadProgress> progressFor(String bookKey) {
    return _active[bookKey]?.progress.stream ?? const Stream.empty();
  }

  Future<String> getOrDownload(Book book) async {
    final cached = await _cache.getValidFile(book.uniqueKey);
    if (cached != null) return cached.path;

    final current = _active[book.uniqueKey];
    if (current != null) return current.future;

    final task = _DownloadTask();
    _active[book.uniqueKey] = task;
    task.future = _download(book, task);
    try {
      return task.future;
    } finally {
      _active.remove(book.uniqueKey);
      await task.progress.close();
    }
  }

  Future<void> cancel(String bookKey) async {
    final task = _active[bookKey];
    if (task == null) return;
    task.cancelToken.cancel('تم إلغاء التحميل');
    final temporary = File(await _cache.temporaryPath(bookKey));
    if (await temporary.exists()) await temporary.delete();
  }

  Future<String> _download(Book book, _DownloadTask task) async {
    final url = _directUrl(book.url);
    if (url.isEmpty) throw const BookDownloadException('الرابط غير متوفر');

    final temporaryPath = await _cache.temporaryPath(book.uniqueKey);
    final finalPath = await _cache.finalPath(book.uniqueKey);
    final temporary = File(temporaryPath);
    final output = File(finalPath);
    if (await temporary.exists()) await temporary.delete();

    Object? lastError;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        await _dio.download(
          url,
          temporaryPath,
          cancelToken: task.cancelToken,
          deleteOnError: false,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 45),
            sendTimeout: const Duration(seconds: 20),
            validateStatus: (status) => status != null && status >= 200 && status < 400,
          ),
          onReceiveProgress: (received, total) {
            if (!task.progress.isClosed) {
              task.progress.add(BookDownloadProgress(received, total));
            }
          },
        );

        if (!await _isPdf(temporary)) {
          throw const BookDownloadException('الملف الذي أعاده الرابط ليس PDF صالحًا');
        }
        if (await output.exists()) await output.delete();
        await temporary.rename(finalPath);
        final size = await output.length();
        await _cache.save(
          bookKey: book.uniqueKey,
          localPath: finalPath,
          remoteUrl: url,
          fileSize: size,
        );
        return finalPath;
      } on DioException catch (error) {
        lastError = error;
        if (CancelToken.isCancel(error)) rethrow;
        if (attempt < 3) {
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      } on BookDownloadException catch (error) {
        lastError = error;
        break;
      }
    }

    if (await temporary.exists()) await temporary.delete();
    throw BookDownloadException(_friendlyMessage(lastError));
  }

  Future<bool> _isPdf(File file) async {
    if (!await file.exists() || await file.length() < 5) return false;
    final header = await file.openRead(0, 5).fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
    return String.fromCharCodes(header) == '%PDF-';
  }

  String _directUrl(String url) {
    final fileId = DriveUrlService.extractFileId(url);
    if (fileId == null) return url.trim();
    return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
  }

  String _friendlyMessage(Object? error) {
    if (error is BookDownloadException) return error.message;
    if (error is DioException && error.type == DioExceptionType.connectionTimeout) {
      return 'انتهت مهلة الاتصال. تحقق من الإنترنت وحاول مرة أخرى.';
    }
    return 'تعذر تحميل الكتاب. تحقق من اتصال الإنترنت وحاول مرة أخرى.';
  }
}

class BookDownloadException implements Exception {
  final String message;
  const BookDownloadException(this.message);

  @override
  String toString() => message;
}
