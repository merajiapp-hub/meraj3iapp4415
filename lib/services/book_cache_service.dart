import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_cache_entry.dart';

class BookCacheService {
  static const _metadataKey = 'book_pdf_cache_v1';

  Future<Directory> _cacheDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/meraj3i_books');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  String _fileStem(String bookKey) {
    var hash = 2166136261;
    for (final byte in utf8.encode(bookKey)) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<File?> getValidFile(String bookKey) async {
    final metadata = await _readMetadata();
    final entry = metadata[bookKey];
    if (entry == null) return null;

    final file = File(entry.localPath);
    if (!await isValidPdf(file)) {
      await remove(bookKey);
      return null;
    }

    metadata[bookKey] = BookCacheEntry(
      bookKey: entry.bookKey,
      localPath: entry.localPath,
      fileSize: await file.length(),
      downloadedAt: entry.downloadedAt,
      lastOpenedAt: DateTime.now(),
      remoteUrl: entry.remoteUrl,
    );
    await _writeMetadata(metadata);
    return file;
  }

  Future<String> finalPath(String bookKey) async {
    final directory = await _cacheDirectory();
    return '${directory.path}/${_fileStem(bookKey)}.pdf';
  }

  Future<String> temporaryPath(String bookKey) async {
    final directory = await _cacheDirectory();
    return '${directory.path}/${_fileStem(bookKey)}.pdf.download';
  }

  Future<void> save({
    required String bookKey,
    required String localPath,
    required String remoteUrl,
    required int fileSize,
  }) async {
    final metadata = await _readMetadata();
    final now = DateTime.now();
    metadata[bookKey] = BookCacheEntry(
      bookKey: bookKey,
      localPath: localPath,
      fileSize: fileSize,
      downloadedAt: now,
      lastOpenedAt: now,
      remoteUrl: remoteUrl,
    );
    await _writeMetadata(metadata);
  }

  Future<bool> isValidPdf(File file) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (length < 5) return false;
    final header = await file.openRead(0, 5).fold<List<int>>(
          <int>[],
          (bytes, chunk) => bytes..addAll(chunk),
        );
    return String.fromCharCodes(header) == '%PDF-';
  }

  Future<void> remove(String bookKey) async {
    final metadata = await _readMetadata();
    final entry = metadata.remove(bookKey);
    if (entry != null) {
      final file = File(entry.localPath);
      if (await file.exists()) await file.delete();
    }
    final temporary = File(await temporaryPath(bookKey));
    if (await temporary.exists()) await temporary.delete();
    await _writeMetadata(metadata);
  }

  Future<int> cacheSizeBytes() async {
    final metadata = await _readMetadata();
    var total = 0;
    for (final entry in metadata.values) {
      final file = File(entry.localPath);
      if (await file.exists()) total += await file.length();
    }
    return total;
  }

  Future<void> clear() async {
    final metadata = await _readMetadata();
    for (final entry in metadata.values) {
      final file = File(entry.localPath);
      if (await file.exists()) await file.delete();
    }
    final directory = await _cacheDirectory();
    if (await directory.exists()) await directory.delete(recursive: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_metadataKey);
  }

  Future<Map<String, BookCacheEntry>> _readMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metadataKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          BookCacheEntry.fromMap(Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeMetadata(Map<String, BookCacheEntry> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _metadataKey,
      jsonEncode(metadata.map((key, value) => MapEntry(key, value.toMap()))),
    );
  }
}
