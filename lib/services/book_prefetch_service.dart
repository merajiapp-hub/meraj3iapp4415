import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/book.dart';
import 'book_cache_service.dart';
import 'book_download_service.dart';

class BookPrefetchService {
  BookPrefetchService({
    BookDownloadService? downloads,
    BookCacheService? cache,
  })  : _downloads = downloads ?? BookDownloadService(),
        _cache = cache ?? BookCacheService();

  final BookDownloadService _downloads;
  final BookCacheService _cache;

  /// يحمّل عددًا صغيرًا من الكتب الأكثر احتمالًا للاستخدام، وعلى Wi-Fi فقط.
  Future<void> prefetch(List<Book> books, {int limit = 2}) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi)) return;

    var downloaded = 0;
    for (final book in books) {
      if (downloaded >= limit) break;
      if (book.url.isEmpty || book.url.contains('/drive/folders/')) continue;
      if (await _cache.getValidFile(book.uniqueKey) != null) continue;

      try {
        await _downloads.getOrDownload(book);
        downloaded++;
      } catch (_) {
        // التحميل المسبق اختياري ولا يجب أن يعطل شاشة الكتب.
      }
    }
  }
}
