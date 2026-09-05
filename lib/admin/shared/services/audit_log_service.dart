import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAction({
    required String action,
    required String targetId,
    required String targetType,
    String? userId,
    String? userName,
    required String result,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final deviceInfo = await _getDeviceInfo();

      final data = {
        'adminId': user.uid,
        'adminEmail': user.email,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'userId': userId,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceType': deviceInfo['deviceType'],
        'platform': deviceInfo['platform'],
        'browser': deviceInfo['browser'],
        'os': deviceInfo['os'],
        'result': result,
        'metadata': metadata,
        'error': errorMessage,
      };

      await _firestore.collection('admin_audit_logs').add(data);
    } catch (e) {
      debugPrint('Error logging audit action: $e');
    }
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
        // Fallback for native if somehow running outside web
        // But admin should be web primarily
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
