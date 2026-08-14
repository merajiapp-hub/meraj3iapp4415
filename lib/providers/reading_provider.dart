import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingProvider extends ChangeNotifier {
  static const String _readingKey = 'reading_status_v1';
  final Set<String> _readBooks = {};
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
        _readBooks.clear();
        _loadLocal(); // Load guest data
      }
    }
  }

  Set<String> get readBooks => Set.unmodifiable(_readBooks);
  int get readCount => _readBooks.length;

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _uid != null ? '${_readingKey}_$_uid' : _readingKey;
    final List<String>? list = prefs.getStringList(key);
    if (list != null) {
      _readBooks.addAll(list);
      notifyListeners();
    }
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _uid != null ? '${_readingKey}_$_uid' : _readingKey;
    await prefs.setStringList(key, _readBooks.toList());
  }

  Future<void> _syncFromFirestore() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('data')
          .doc('read_books')
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['books'] != null) {
          final List<dynamic> books = data['books'];
          _readBooks.addAll(books.cast<String>());
          await _saveLocal();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error syncing read books: $e');
    }
  }

  Future<void> markAsRead(String uniqueKey) async {
    if (_readBooks.contains(uniqueKey)) return;
    _readBooks.add(uniqueKey);
    notifyListeners();
    await _saveLocal();

    if (_uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('data')
            .doc('read_books')
            .set({
              'books': FieldValue.arrayUnion([uniqueKey]),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving read state: $e');
      }
    }
  }

  bool isRead(String uniqueKey) {
    return _readBooks.contains(uniqueKey);
  }

  void clearAll() {
    _readBooks.clear();
    notifyListeners();
  }
}
