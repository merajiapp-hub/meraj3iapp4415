import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AdminNotificationService extends ChangeNotifier {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Listen to unread notifications count in real-time
  void startListeningToUnreadCount() {
    _firestore
        .collection('admin_notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to admin notifications count: $e');
    });
  }

  // Get notifications stream
  Stream<QuerySnapshot> getNotificationsStream({int limit = 50}) {
    return _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Create a new notification (used by Cloud Functions or other admin areas)
  Future<void> createNotification({
    required String type, // 'new_user', 'new_book', 'system_error'
    required String title,
    required String message,
    String priority = 'normal', // 'low', 'normal', 'high', 'critical'
    String severity = 'info', // 'info', 'warning', 'error', 'success'
    String? targetId,
    String? targetType,
  }) async {
    try {
      await _firestore.collection('admin_notifications').add({
        'type': type,
        'title': title,
        'message': message,
        'priority': priority,
        'severity': severity,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'targetId': targetId,
        'targetType': targetType,
      });
    } catch (e) {
      debugPrint('Error creating admin notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('admin_notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    try {
      final unreadDocs = await _firestore
          .collection('admin_notifications')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
