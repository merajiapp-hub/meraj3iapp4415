// ignore_for_file: avoid_print
import 'package:meraj3i/data/books_data.dart';
import 'package:meraj3i/services/drive_url_service.dart';

void main() {
  final Map<String, List<String>> urlMap = {};
  final Map<String, List<String>> fileIdMap = {};

  for (var book in BooksData.allBooks) {
    urlMap.putIfAbsent(book.url, () => []).add('${book.title} (${book.section} - ${book.grade})');
    
    final fileId = DriveUrlService.extractFileId(book.url);
    if (fileId != null) {
      fileIdMap.putIfAbsent(fileId, () => []).add('${book.title} (${book.section} - ${book.grade})');
    }
  }

  int urlDuplicates = 0;
  print('--- Duplicate URLs ---');
  urlMap.forEach((url, titles) {
    if (titles.length > 1) {
      urlDuplicates++;
      print('URL: $url -> $titles');
    }
  });

  int fileIdDuplicates = 0;
  print('--- Duplicate Drive File IDs ---');
  fileIdMap.forEach((fileId, titles) {
    if (titles.length > 1) {
      fileIdDuplicates++;
      print('FileID: $fileId -> $titles');
    }
  });
  
  print('Total URL duplicates: $urlDuplicates');
  print('Total FileID duplicates: $fileIdDuplicates');
}
