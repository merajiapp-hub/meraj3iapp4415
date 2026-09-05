import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AdminActivityService {
  static final AdminActivityService _instance = AdminActivityService._internal();
  factory AdminActivityService() => _instance;
  AdminActivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logActivity({
    required String type, // e.g. 'login', 'new_user', 'book_added'
    required String title,
    required String message,
    String? userId,
    String? userName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final deviceInfo = await _getDeviceInfo();

      final data = {
        'type': type,
        'title': title,
        'message': message,
        'userId': userId,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceType': deviceInfo['deviceType'],
        'platform': deviceInfo['platform'],
        'browser': deviceInfo['browser'],
        'os': deviceInfo['os'],
        'metadata': metadata,
      };

      await _firestore.collection('admin_activity').add(data);
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  Stream<QuerySnapshot> getActivityStream({int limit = 50}) {
    return _firestore
        .collection('admin_activity')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    String deviceType = 'Unknown';
    String platform = 'Unknown';
    String browser = 'Unknown';
    String os = 'Unknown';

    try {
      final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      
      if (kIsWeb) {
        platform = 'Web';
        deviceType = 'Desktop/Web';
        final webBrowserInfo = await deviceInfoPlugin.webBrowserInfo;
        browser = webBrowserInfo.browserName.name;
        os = webBrowserInfo.platform ?? 'Unknown';
      } else {
        platform = 'Native';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {
      'deviceType': deviceType,
      'platform': platform,
      'browser': browser,
      'os': os,
    };
  }
}
