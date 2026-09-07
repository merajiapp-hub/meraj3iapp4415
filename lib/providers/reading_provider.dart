import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reading_session.dart';
import '../models/book.dart';

class ReadingProvider extends ChangeNotifier {
  static const String _readingKey = 'reading_sessions_v2';
  final Map<String, ReadingSession> _sessions = {};
  String? _uid;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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

  List<ReadingSession> get sessions =>
      _sessions.values.toList()
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
    final user = _auth.currentUser;
    if (user == null || _uid != user.uid) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('reading_sessions')
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final sessionData = data['session'];
        if (sessionData is! Map<String, dynamic>) continue;
        final remote = ReadingSession.fromMap(sessionData);
        final local = _sessions[remote.bookKey];
        if (local == null || remote.lastReadAt.isAfter(local.lastReadAt)) {
          _sessions[remote.bookKey] = remote;
        }
      }
      await _saveLocal();
      notifyListeners();
    } catch (e) {
      debugPrint('Error syncing reading sessions: $e');
    }
  }

  Future<void> updateSession(ReadingSession session) async {
    _sessions[session.bookKey] = session;
    notifyListeners();
    await _saveLocal();
    final user = _auth.currentUser;
    if (user != null && _uid == user.uid) {
      try {
        final docId = base64Url
            .encode(utf8.encode(session.bookKey))
            .replaceAll('=', '');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('reading_sessions')
            .doc(docId)
            .set({
              'session': session.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving reading session: $e');
      }
    }
  }

  Future<void> markAsToRead(Book book) async {
    final session =
        _sessions[book.uniqueKey] ??
        ReadingSession(bookKey: book.uniqueKey, book: book);
    session.status = ReadingStatus.toRead;
    await updateSession(session);
  }

  Future<void> markAsReading(Book book, {int? page, int? totalPages}) async {
    final session =
        _sessions[book.uniqueKey] ??
        ReadingSession(bookKey: book.uniqueKey, book: book);
    session.status = ReadingStatus.reading;
    session.lastReadAt = DateTime.now();
    if (page != null) session.lastPage = page;
    if (totalPages != null) session.totalPages = totalPages;
    await updateSession(session);
  }

  Future<void> markAsCompleted(Book book) async {
    final session =
        _sessions[book.uniqueKey] ??
        ReadingSession(bookKey: book.uniqueKey, book: book);
    session.status = ReadingStatus.completed;
    session.lastReadAt = DateTime.now();
    if (session.totalPages > 1) {
      session.lastPage = session.totalPages;
    }
    await updateSession(session);
  }

  Future<void> addReadingTime(Book book, int seconds) async {
    final session =
        _sessions[book.uniqueKey] ??
        ReadingSession(bookKey: book.uniqueKey, book: book);
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
