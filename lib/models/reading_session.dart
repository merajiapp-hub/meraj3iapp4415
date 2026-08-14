import 'dart:convert';
import 'book.dart';

enum ReadingStatus { toRead, reading, completed }

class ReadingSession {
  final String bookKey;
  final Book book;
  ReadingStatus status;
  int lastPage;
  int totalPages;
  int readingTimeSeconds;
  DateTime lastReadAt;

  ReadingSession({
    required this.bookKey,
    required this.book,
    this.status = ReadingStatus.toRead,
    this.lastPage = 1,
    this.totalPages = 1,
    this.readingTimeSeconds = 0,
    DateTime? lastReadAt,
  }) : lastReadAt = lastReadAt ?? DateTime.now();

  double get progress => totalPages > 0 ? (lastPage / totalPages).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'bookKey': bookKey,
      'book': book.toMap(),
      'status': status.name,
      'lastPage': lastPage,
      'totalPages': totalPages,
      'readingTimeSeconds': readingTimeSeconds,
      'lastReadAt': lastReadAt.toIso8601String(),
    };
  }

  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    return ReadingSession(
      bookKey: map['bookKey'] ?? '',
      book: Book.fromMap(map['book'] ?? {}, map['book']?['id'] ?? ''),
      status: ReadingStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReadingStatus.toRead,
      ),
      lastPage: map['lastPage'] ?? 1,
      totalPages: map['totalPages'] ?? 1,
      readingTimeSeconds: map['readingTimeSeconds'] ?? 0,
      lastReadAt: map['lastReadAt'] != null 
          ? DateTime.parse(map['lastReadAt']) 
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReadingSession.fromJson(String source) => 
      ReadingSession.fromMap(json.decode(source));
}
