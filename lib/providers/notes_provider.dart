import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/note_models.dart';

export '../data/note_models.dart';

class NotesProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Note> _notes = [];
  final List<NoteFolder> _folders = [];
  final List<NoteTag> _tags = [];
  
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedFolderId;
  String? _selectedTagId;
  String _currentTab = 'all'; // all, recent, favorites, pinned, archive, folders, trash

  List<NoteFolder> get folders => _folders;
  List<NoteTag> get tags => _tags;
  bool get isLoading => _isLoading;
  String get currentTab => _currentTab;

  List<Note> get notes {
    var filtered = _notes.where((n) => !n.isDeleted).toList();

    // Tab Filtering
    if (_currentTab == 'favorites') {
      filtered = filtered.where((n) => n.isFavorite).toList();
    } else if (_currentTab == 'pinned') {
      filtered = filtered.where((n) => n.isPinned).toList();
    } else if (_currentTab == 'archive') {
      filtered = _notes.where((n) => n.isArchived && !n.isDeleted).toList();
    } else {
      filtered = filtered.where((n) => !n.isArchived).toList();
    }

    // Folder & Tag Filtering
    if (_selectedFolderId != null) {
      filtered = filtered.where((n) => n.folderId == _selectedFolderId).toList();
    }
    if (_selectedTagId != null) {
      filtered = filtered.where((n) => n.tags.contains(_selectedTagId)).toList();
    }

    // Search Filtering
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((n) => 
        n.title.toLowerCase().contains(q) || 
        n.content.toLowerCase().contains(q)
      ).toList();
    }

    // Sorting
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

  NotesProvider() {
    fetchNotes();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTab(String tab) {
    _currentTab = tab;
    _selectedFolderId = null;
    notifyListeners();
  }

  void setFolder(String? folderId) {
    _selectedFolderId = folderId;
    _currentTab = 'folders';
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
      
      // Also fetch folders and tags here if implemented in Firestore
      // For now, initializing empty or mock
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNote(
    String title, 
    String content, {
    int? color, 
    DateTime? reminderTime,
    String? folderId,
    List<String>? tags,
    bool isFavorite = false,
    NotePageSettings? pageSettings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final newNoteData = {
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isPinned': false,
      'isFavorite': isFavorite,
      'isArchived': false,
      'isDeleted': false,
      'color': color,
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime) : null,
      'folderId': folderId,
      'tags': tags ?? [],
      'wordCount': 0,
      'pageCount': 1,
      'pageSettings': pageSettings?.toMap(),
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
          isFavorite: isFavorite,
          isArchived: false,
          isDeleted: false,
          color: color,
          reminderTime: reminderTime,
          folderId: folderId,
          tags: tags ?? [],
          pageSettings: pageSettings,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  Future<void> updateNote(
    String id, 
    String title, 
    String content, {
    int? color, 
    DateTime? reminderTime,
    String? folderId,
    List<String>? tags,
    NotePageSettings? pageSettings,
  }) async {
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
        'folderId': folderId,
        'tags': tags,
        'pageSettings': pageSettings?.toMap(),
      });

      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final old = _notes[index];
        _notes[index] = Note(
          id: id,
          title: title,
          content: content,
          createdAt: old.createdAt,
          updatedAt: now,
          isPinned: old.isPinned,
          isFavorite: old.isFavorite,
          isArchived: old.isArchived,
          isDeleted: old.isDeleted,
          deletedAt: old.deletedAt,
          color: color,
          reminderTime: reminderTime,
          folderId: folderId ?? old.folderId,
          tags: tags ?? old.tags,
          pageSettings: pageSettings ?? old.pageSettings,
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

      final old = _notes[index];
      _notes[index] = Note(
        id: id,
        title: old.title,
        content: old.content,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
        isPinned: newPinnedStatus,
        isFavorite: old.isFavorite,
        isArchived: old.isArchived,
        isDeleted: old.isDeleted,
        folderId: old.folderId,
        tags: old.tags,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling pin: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final newFav = !_notes[index].isFavorite;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(id)
          .update({'isFavorite': newFav});

      final old = _notes[index];
      _notes[index] = Note(
        id: id,
        title: old.title,
        content: old.content,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
        isPinned: old.isPinned,
        isFavorite: newFav,
        isArchived: old.isArchived,
        isDeleted: old.isDeleted,
        folderId: old.folderId,
        tags: old.tags,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling fav: $e');
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

      final old = _notes[index];
      _notes[index] = Note(
        id: id,
        title: old.title,
        content: old.content,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
        isPinned: old.isPinned,
        isFavorite: old.isFavorite,
        isArchived: old.isArchived,
        isDeleted: true,
        deletedAt: now,
        color: old.color,
        reminderTime: old.reminderTime,
        folderId: old.folderId,
        tags: old.tags,
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

      final old = _notes[index];
      _notes[index] = Note(
        id: id,
        title: old.title,
        content: old.content,
        createdAt: old.createdAt,
        updatedAt: now,
        isPinned: old.isPinned,
        isFavorite: old.isFavorite,
        isArchived: old.isArchived,
        isDeleted: false,
        deletedAt: null,
        color: old.color,
        reminderTime: old.reminderTime,
        folderId: old.folderId,
        tags: old.tags,
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
