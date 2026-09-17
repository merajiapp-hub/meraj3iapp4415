class BookCacheEntry {
  final String bookKey;
  final String localPath;
  final int fileSize;
  final DateTime downloadedAt;
  final DateTime lastOpenedAt;
  final String remoteUrl;

  const BookCacheEntry({
    required this.bookKey,
    required this.localPath,
    required this.fileSize,
    required this.downloadedAt,
    required this.lastOpenedAt,
    required this.remoteUrl,
  });

  factory BookCacheEntry.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(String key) =>
        DateTime.tryParse(map[key]?.toString() ?? '') ?? DateTime.now();

    return BookCacheEntry(
      bookKey: map['bookKey']?.toString() ?? '',
      localPath: map['localPath']?.toString() ?? '',
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
      downloadedAt: parseDate('downloadedAt'),
      lastOpenedAt: parseDate('lastOpenedAt'),
      remoteUrl: map['remoteUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'bookKey': bookKey,
        'localPath': localPath,
        'fileSize': fileSize,
        'downloadedAt': downloadedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt.toIso8601String(),
        'remoteUrl': remoteUrl,
      };
}
