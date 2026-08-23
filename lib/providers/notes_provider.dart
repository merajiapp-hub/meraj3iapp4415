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
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime? reminderTime;
  final int? color;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isDeleted = false,
    this.deletedAt,
    this.reminderTime,
    this.color,
  });

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPinned: map['isPinned'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      reminderTime: (map['reminderTime'] as Timestamp?)?.toDate(),
      color: map['color'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'color': color,
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
    var filtered = _notes.where((n) => !n.isDeleted).toList();
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
  
  List<Note> get trashedNotes {
    var filtered = _notes.where((n) => n.isDeleted).toList();
    filtered.sort((a, b) {
      final aDate = a.deletedAt ?? a.updatedAt;
      final bDate = b.deletedAt ?? b.updatedAt;
      return bDate.compareTo(aDate);
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

  Future<void> addNote(String title, String content, {int? color, DateTime? reminderTime}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final newNoteData = {
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isPinned': false,
      'isDeleted': false,
      'color': color,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime) : null,
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
          isDeleted: false,
          color: color,
          reminderTime: reminderTime,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  Future<void> updateNote(String id, String title, String content, {int? color, DateTime? reminderTime}) async {
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
        'color': color,
        'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime) : null,
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
          isDeleted: _notes[index].isDeleted,
          deletedAt: _notes[index].deletedAt,
          color: color,
          reminderTime: reminderTime,
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

  Future<void> moveToTrash(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final now = DateTime.now();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      _notes[index] = Note(
        id: id,
        title: _notes[index].title,
        content: _notes[index].content,
        createdAt: _notes[index].createdAt,
        updatedAt: _notes[index].updatedAt,
        isPinned: _notes[index].isPinned,
        isDeleted: true,
        deletedAt: now,
        color: _notes[index].color,
        reminderTime: _notes[index].reminderTime,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error moving note to trash: $e');
    }
  }

  Future<void> restoreFromTrash(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final now = DateTime.now();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _notes[index] = Note(
        id: id,
        title: _notes[index].title,
        content: _notes[index].content,
        createdAt: _notes[index].createdAt,
        updatedAt: now,
        isPinned: _notes[index].isPinned,
        isDeleted: false,
        deletedAt: null,
        color: _notes[index].color,
        reminderTime: _notes[index].reminderTime,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring note from trash: $e');
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
      debugPrint('Error permanently deleting note: $e');
    }
  }
}
