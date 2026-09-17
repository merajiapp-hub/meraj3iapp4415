import 'dart:io' show Platform;

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginActivityService {
  LoginActivityService._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const String _pendingKey = 'pending_login_activity';

  static Future<void> record({
    required String result,
    required String method,
    String? authCode,
    String? identifier,
  }) async {
    try {
      final context = await _clientContext();
      final event = <String, dynamic>{
        'result': result,
        'method': method,
        'authCode': _safeCode(authCode),
        'identifierMasked': _maskIdentifier(identifier, method),
        'identifierHash': _hashIdentifier(identifier, method),
        'consecutiveFailedAttempts': result == 'success' ? 0 : 1,
        'needsSupport': false,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        ...context,
      };
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _queue(event);
        return;
      }

      await _writeForUser(user.uid, event);
      if (result == 'success') {
        await _flushMatching(user.uid, _hashIdentifier(identifier, method));
      }
    } catch (error) {
      debugPrint('[LoginActivity] record failed: $error');
    }
  }

  static Future<void> _writeForUser(String uid, Map<String, dynamic> event) async {
    final data = Map<String, dynamic>.from(event)
      ..remove('identifierHash')
      ..['userId'] = uid
      ..['createdAt'] = Timestamp.fromDate(DateTime.parse(event['createdAt'] as String));
    await FirebaseFirestore.instance.collection('login_attempts').add(data);
  }

  static Future<void> _flushMatching(String uid, String? identifierHash) async {
    if (identifierHash == null) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = _pending(prefs);
    final matching = pending.where((event) => event['identifierHash'] == identifierHash).toList();
    var failedCount = 0;
    Map<String, dynamic>? lastFailure;
    for (final event in matching) {
      final failed = event['result'] != 'success';
      failedCount = failed ? failedCount + 1 : 0;
      event['consecutiveFailedAttempts'] = failedCount;
      event['needsSupport'] = failedCount >= 3;
      if (failed) lastFailure = event;
      await _writeForUser(uid, event);
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'failedLoginAttempts': failedCount,
      'needsSupport': failedCount >= 3,
      'lastLoginAttemptAt': FieldValue.serverTimestamp(),
      if (lastFailure != null) ...{
        'lastLoginFailureAt': FieldValue.serverTimestamp(),
        'lastLoginFailureReason': lastFailure['result'],
      } else ...{
        'lastLoginSuccessAt': FieldValue.serverTimestamp(),
      },
      'loginActivityUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (matching.isNotEmpty) {
      pending.removeWhere((event) => event['identifierHash'] == identifierHash);
      await prefs.setString(_pendingKey, jsonEncode(pending));
    }
  }

  static Future<void> _queue(Map<String, dynamic> event) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _pending(prefs);
    pending.add(event);
    if (pending.length > 20) {
      pending.removeRange(0, pending.length - 20);
    }
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  static List<Map<String, dynamic>> _pending(SharedPreferences prefs) {
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static String? _hashIdentifier(String? value, String method) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = method == 'phone'
        ? value.replaceAll(RegExp(r'[^0-9]'), '')
        : value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    var hash = 0;
    for (final codeUnit in normalized.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return '$method-$hash';
  }

  static String? _maskIdentifier(String? value, String method) {
    if (value == null || value.trim().isEmpty) return null;
    if (method == 'phone') {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      return '••••${digits.length > 4 ? digits.substring(digits.length - 4) : digits}';
    }
    final parts = value.trim().split('@');
    if (parts.length != 2) return '••••';
    return '${parts.first.isEmpty ? '' : parts.first[0]}•••@${parts.last}';
  }

  static String? _safeCode(String? code) {
    if (code == null) return null;
    final sanitized = code.replaceAll(RegExp(r'password|token|secret|otp', caseSensitive: false), 'redacted');
    return sanitized.substring(0, sanitized.length > 80 ? 80 : sanitized.length);
  }

  static Future<Map<String, dynamic>> _clientContext() async {
    final package = await PackageInfo.fromPlatform();
    final data = <String, dynamic>{
      'appVersion': package.version,
      'buildNumber': package.buildNumber,
      'platform': _platformName,
    };

    try {
      if (kIsWeb) {
        final info = await _deviceInfo.webBrowserInfo;
        data['deviceType'] = info.browserName.name;
        data['deviceModel'] = info.platform;
      } else if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        data['deviceType'] = 'Android';
        data['deviceModel'] = '${info.manufacturer} ${info.model}'.trim();
        data['osVersion'] = info.version.release;
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        data['deviceType'] = 'iOS';
        data['deviceModel'] = info.utsname.machine;
        data['osVersion'] = info.systemVersion;
      } else if (Platform.isWindows) {
        final info = await _deviceInfo.windowsInfo;
        data['deviceType'] = 'Windows';
        data['deviceModel'] = info.computerName;
      } else if (Platform.isMacOS) {
        final info = await _deviceInfo.macOsInfo;
        data['deviceType'] = 'macOS';
        data['deviceModel'] = info.model;
      } else if (Platform.isLinux) {
        final info = await _deviceInfo.linuxInfo;
        data['deviceType'] = 'Linux';
        data['deviceModel'] = info.prettyName;
      }
    } catch (error) {
      debugPrint('[LoginActivity] device info unavailable: $error');
    }

    return data;
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
