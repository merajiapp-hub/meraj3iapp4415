import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Note.fromMap(String id, Map<String, dynamic> map) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class NotesProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NotesProvider() {
    fetchNotes();
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
          .orderBy('createdAt', descending: true)
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

    final newNoteData = {
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
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
          createdAt: DateTime.now(),
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

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update({
        'title': title,
        'content': content,
      });

      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notes[index] = Note(
          id: id,
          title: title,
          content: content,
          createdAt: _notes[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
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
