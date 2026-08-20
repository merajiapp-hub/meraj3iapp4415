import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;
  final List<Map<String, String>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'updatedAt': updatedAt,
      'messages': messages,
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map, String id) {
    return ChatSession(
      id: id,
      title: map['title'] ?? 'محادثة جديدة',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      messages: List<Map<String, String>>.from(
        (map['messages'] as List).map((m) => Map<String, String>.from(m)),
      ),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  bool _isLoading = false;

  List<ChatSession> get sessions => _sessions;
  String? get currentSessionId => _currentSessionId;
  bool get isLoading => _isLoading;

  ChatSession? get currentSession => _currentSessionId != null
      ? _sessions.where((s) => s.id == _currentSessionId).firstOrNull
      : null;

  Future<void> loadSessions(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .orderBy('updatedAt', descending: true)
          .get();

      _sessions = snapshot.docs
          .map((doc) => ChatSession.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading chat sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createSession(String userId, String firstMessage) async {
    final title = firstMessage.length > 30
        ? '${firstMessage.substring(0, 30)}...'
        : firstMessage;

    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .add({
          'title': title,
          'updatedAt': FieldValue.serverTimestamp(),
          'messages': [],
        });

    _currentSessionId = docRef.id;

    // ✅ إضافة الجلسة مباشرةً للقائمة المحلية بدلاً من إعادة تحميل الكل
    final newSession = ChatSession(
      id: docRef.id,
      title: title,
      updatedAt: DateTime.now(),
      messages: [],
    );
    _sessions.insert(0, newSession);
    notifyListeners();

    return docRef.id;
  }

  Future<void> addMessage(
    String userId,
    String sessionId,
    Map<String, String> message,
  ) async {
    // ✅ تحديث الحالة المحلية فوراً لتحديث الـ UI في الحال
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index].messages.add(message);
      notifyListeners();
    } else {
      // إذا لم تكن الجلسة محلياً، نُحمّلها أولاً
      await loadSessions(userId);
      final newIndex = _sessions.indexWhere((s) => s.id == sessionId);
      if (newIndex != -1) {
        _sessions[newIndex].messages.add(message);
        notifyListeners();
      }
    }

    // ثم نحفظ في Firestore بشكل غير متزامن
    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(sessionId);
      await sessionRef.update({
        'messages': FieldValue.arrayUnion([message]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving message to Firestore: $e');
    }
  }

  void setCurrentSession(String? sessionId) {
    _currentSessionId = sessionId;
    notifyListeners();
  }

  Future<void> deleteSession(String userId, String sessionId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(sessionId)
        .delete();
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSessionId == sessionId) _currentSessionId = null;
    notifyListeners();
  }
}
