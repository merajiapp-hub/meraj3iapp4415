
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_session.dart';
import '../models/book.dart';

class ReadingProvider extends ChangeNotifier {
  static const String _readingKey = 'reading_sessions_v2';
  final Map<String, ReadingSession> _sessions = {};
  String? _uid;

  ReadingProvider() {
    _loadLocal();
  }

  void updateUid(String? uid) {
    if (_uid != uid) {
      _uid = uid;
      if (_uid != null) {
        _syncFromFirestore();
      } else {
        _sessions.clear();
        _loadLocal();
      }
    }
  }

  List<ReadingSession> get sessions => _sessions.values.toList()
    ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

  List<ReadingSession> get toReadList => 
      sessions.where((s) => s.status == ReadingStatus.toRead).toList();

  List<ReadingSession> get readingList => 
      sessions.where((s) => s.status == ReadingStatus.reading).toList();

  List<ReadingSession> get completedList => 
      sessions.where((s) => s.status == ReadingStatus.completed).toList();

  int get readCount => completedList.length;

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _uid != null ? '${_readingKey}_$_uid' : _readingKey;
    final List<String>? list = prefs.getStringList(key);
    
    if (list != null) {
      for (var jsonStr in list) {
        try {
          final session = ReadingSession.fromJson(jsonStr);
          _sessions[session.bookKey] = session;
        } catch (e) {
          debugPrint('Error parsing session: $e');
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _uid != null ? '${_readingKey}_$_uid' : _readingKey;
    final List<String> list = _sessions.values.map((s) => s.toJson()).toList();
    await prefs.setStringList(key, list);
  }

  Future<void> _syncFromFirestore() async {
    // Sync logic can be expanded later to sync full sessions
  }

  Future<void> updateSession(ReadingSession session) async {
    _sessions[session.bookKey] = session;
    notifyListeners();
    await _saveLocal();
  }

  Future<void> markAsToRead(Book book) async {
    final session = _sessions[book.uniqueKey] ?? ReadingSession(bookKey: book.uniqueKey, book: book);
    session.status = ReadingStatus.toRead;
    await updateSession(session);
  }

  Future<void> markAsReading(Book book, {int? page, int? totalPages}) async {
    final session = _sessions[book.uniqueKey] ?? ReadingSession(bookKey: book.uniqueKey, book: book);
    session.status = ReadingStatus.reading;
    session.lastReadAt = DateTime.now();
    if (page != null) session.lastPage = page;
    if (totalPages != null) session.totalPages = totalPages;
    await updateSession(session);
  }

  Future<void> markAsCompleted(Book book) async {
    final session = _sessions[book.uniqueKey] ?? ReadingSession(bookKey: book.uniqueKey, book: book);
    session.status = ReadingStatus.completed;
    session.lastReadAt = DateTime.now();
    if (session.totalPages > 1) {
      session.lastPage = session.totalPages;
    }
    await updateSession(session);
  }

  Future<void> addReadingTime(Book book, int seconds) async {
    final session = _sessions[book.uniqueKey] ?? ReadingSession(bookKey: book.uniqueKey, book: book);
    session.readingTimeSeconds += seconds;
    await updateSession(session);
  }

  bool isRead(String uniqueKey) {
    return _sessions[uniqueKey]?.status == ReadingStatus.completed;
  }
  
  ReadingSession? getSession(String uniqueKey) {
    return _sessions[uniqueKey];
  }

  void clearAll() {
    _sessions.clear();
    notifyListeners();
  }
}
