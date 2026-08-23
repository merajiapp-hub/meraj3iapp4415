import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: map['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
    };
  }
}

class NotesProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Note> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<Note> get notes {
    var filtered = _notes;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) => 
        n.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
        n.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    // Sort: Pinned first, then by updatedAt descending
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return filtered;
  }
  
  bool get isLoading => _isLoading;

  NotesProvider() {
    fetchNotes();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchNotes() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      _notes = snapshot.docs.map((doc) => Note.fromMap(doc.id, doc.data())).toList();
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(String title, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final newNoteData = {
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isPinned': false,
    };

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add(newNoteData);

      _notes.insert(
        0,
        Note(
          id: docRef.id,
          title: title,
          content: content,
          createdAt: now,
          updatedAt: now,
          isPinned: false,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  Future<void> updateNote(String id, String title, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notes[index] = Note(
          id: id,
          title: title,
          content: content,
          createdAt: _notes[index].createdAt,
          updatedAt: now,
          isPinned: _notes[index].isPinned,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
    }
  }

  Future<void> togglePin(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final newPinnedStatus = !_notes[index].isPinned;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update({'isPinned': newPinnedStatus});

      _notes[index] = Note(
        id: id,
        title: _notes[index].title,
        content: _notes[index].content,
        createdAt: _notes[index].createdAt,
        updatedAt: _notes[index].updatedAt,
        isPinned: newPinnedStatus,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .delete();

      _notes.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting note: $e');
    }
  }
}
