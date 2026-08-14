import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/notification_service.dart';
import '../screens/notification_details_screen.dart';
import '../main.dart' show navigatorKey;

enum NotificationType { general, update, reminder, system }

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  bool isRead;
  final DateTime timestamp;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.timestamp,
  });

  String get typeLabel {
    switch (type) {
      case NotificationType.general:
        return 'عام';
      case NotificationType.update:
        return 'تحديث';
      case NotificationType.reminder:
        return 'تذكير';
      case NotificationType.system:
        return 'نظام';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.general:
        return Icons.notifications_rounded;
      case NotificationType.update:
        return Icons.system_update_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.general:
        return const Color(0xFF14B8A6);
      case NotificationType.update:
        return const Color(0xFF8B5CF6);
      case NotificationType.reminder:
        return const Color(0xFFF59E0B);
      case NotificationType.system:
        return const Color(0xFF0EA5E9);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.index,
    'isRead': isRead,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) =>
      AppNotificationModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        type: NotificationType.values[json['type'] ?? 0],
        isRead: json['isRead'] ?? false,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );
}

class NotificationsProvider extends ChangeNotifier {
  static const _storageKey = 'app_notifications';
  static const _maxNotifications = 100;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _uid;
  List<AppNotificationModel> _notifications = [];
  bool _isLoading = false;

  NotificationsProvider() {
    _setupFirebaseMessaging();
  }

  void updateUser(String? uid) {
    if (_uid != uid) {
      _uid = uid;
      if (_uid != null) {
        _loadFromFirestore();
      } else {
        _loadFromStorage();
      }
    }
  }

  List<AppNotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;
  bool get isLoading => _isLoading;

  List<AppNotificationModel> getByType(NotificationType? type) {
    if (type == null) return notifications;
    return _notifications.where((n) => n.type == type).toList();
  }

  List<AppNotificationModel> search(String query) {
    if (query.trim().isEmpty) return notifications;
    final q = query.toLowerCase();
    return _notifications
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.body.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
  }) async {
    final notification = AppNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      isRead: false,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);
    if (_notifications.length > _maxNotifications) {
      _notifications = _notifications.take(_maxNotifications).toList();
    }

    notifyListeners();
    await _saveData();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
      await _updateInFirestore(id, {'isRead': true});
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    if (_uid != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting notification: $e');
      }
    } else {
      await _saveData(); // Save local storage
    }
  }

  Future<void> deleteAll() async {
    _notifications.clear();
    notifyListeners();
    if (_uid != null) {
      try {
        final batch = _firestore.batch();
        final snapshots = await _firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .get();
        for (var doc in snapshots.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error clearing notifications: $e');
      }
    } else {
      await _saveData();
    }
  }

  // ─── حفظ وتحميل ───────────────────────────────────────────────────────────
  Future<void> _saveData() async {
    if (_uid != null) {
      try {
        final batch = _firestore.batch();
        final notifRef = _firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications');
        for (var n in _notifications) {
          batch.set(notifRef.doc(n.id), n.toJson(), SetOptions(merge: true));
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Error saving notifications to Firestore: $e');
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, jsonList);
    }
  }

  Future<void> _updateInFirestore(String id, Map<String, dynamic> data) async {
    if (_uid != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_uid)
            .collection('notifications')
            .doc(id)
            .update(data);
      } catch (e) {
        // Ignored
      }
    } else {
      await _saveData();
    }
  }

  Future<void> _loadFromFirestore() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(_maxNotifications)
          .get();

      _notifications = snapshot.docs
          .map((doc) => AppNotificationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications from Firestore: $e');
      await _loadFromStorage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey) ?? [];
      _notifications = jsonList
          .map((s) => AppNotificationModel.fromJson(jsonDecode(s)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  // ─── Firebase Messaging ───────────────────────────────────────────────────
  void _setupFirebaseMessaging() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notif = _handleMessage(message);
        if (notif != null) {
          NotificationService().showInstantNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: notif.title,
            body: notif.body,
            payload: notif.id,
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // لا نقوم بـ markAllAsRead() هنا — نفتح فقط الإشعار المحدد
        final notif = _handleMessage(message);
        if (notif != null) _navigateToDetails(notif);
      });

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          final notif = _handleMessage(message);
          if (notif != null) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              _navigateToDetails(notif);
            });
          }
        }
      });
    } catch (e) {
      debugPrint('Firebase Messaging setup error: $e');
    }
  }

  void _navigateToDetails(AppNotificationModel notif) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // وضع علامة مقروء فقط للإشعار المحدد
      markAsRead(notif.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationDetailsScreen(notification: notif),
        ),
      );
    }
  }

  AppNotificationModel? _handleMessage(RemoteMessage message) {
    final title =
        message.notification?.title ?? message.data['title'] ?? 'إشعار جديد';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    // Check if we already received this to prevent duplicates in short time
    if (_notifications.isNotEmpty &&
        _notifications.first.title == title &&
        _notifications.first.body == body) {
      final diff = DateTime.now().difference(_notifications.first.timestamp);
      if (diff.inSeconds < 5) return null;
    }

    final notification = AppNotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: _parseType(message.data['type']),
      isRead: false,
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);
    if (_notifications.length > _maxNotifications) {
      _notifications = _notifications.take(_maxNotifications).toList();
    }

    notifyListeners();
    _saveData();
    return notification;
  }

  NotificationType _parseType(String? typeStr) {
    switch (typeStr) {
      case 'update':
        return NotificationType.update;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.general;
    }
  }
}
