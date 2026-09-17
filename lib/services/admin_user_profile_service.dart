import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserProfile {
  const AdminUserProfile({
    required this.uid,
    required this.raw,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.username,
    required this.gender,
    required this.provider,
    required this.status,
    required this.createdAt,
    required this.lastLoginAt,
    required this.photoUrl,
  });

  final String uid;
  final Map<String, dynamic> raw;
  final String fullName;
  final String email;
  final String phone;
  final String username;
  final String gender;
  final String provider;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final String photoUrl;

  static const Set<String> _blockedKeys = {
    'password',
    'pass',
    'currentpassword',
    'oldpassword',
    'newpassword',
    'resetcode',
    'token',
    'accesstoken',
    'refreshtoken',
    'secret',
    'apikey',
    'privatekey',
    'authorization',
  };

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static String _statusLabel(Map<String, dynamic> data) {
    final value = data['accountStatus'] ??
        data['status'] ??
        data['userStatus'] ??
        data['isSuspended'];

    if (data['isSuspended'] == true ||
        data['disabled'] == true ||
        value.toString().toLowerCase() == 'suspended' ||
        value.toString().toLowerCase() == 'disabled') {
      return 'موقوف';
    }

    if (value.toString().toLowerCase() == 'active') {
      return 'نشط';
    }

    return 'نشط';
  }

  static String _providerLabel(Object? providerRaw) {
    final value = providerRaw?.toString().trim().toLowerCase();

    if (value == null || value.isEmpty) return 'غير متوفر';
    if (value == 'google') return 'Google';
    if (value == 'phone') return 'Phone';
    if (value == 'email' || value == 'password') return 'Email/Password';
    if (value == 'apple') return 'Apple';
    if (value == 'facebook') return 'Facebook';
    return value;
  }

  static Map<String, dynamic> sanitize(Map<String, dynamic> source) {
    final cleaned = <String, dynamic>{};

    source.forEach((key, value) {
      final normalizedKey = key.toString().toLowerCase();
      final isBlocked = _blockedKeys.contains(normalizedKey) ||
          normalizedKey.contains('password') ||
          normalizedKey.contains('token') ||
          normalizedKey.contains('secret') ||
          normalizedKey.contains('api') ||
          normalizedKey.contains('key');

      if (!isBlocked) {
        cleaned[key] = value;
      }
    });

    return cleaned;
  }

  static String _firstValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'غير متوفر';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'غير متوفر';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  factory AdminUserProfile.fromUidAndData(String uid, Map<String, dynamic> data) {
    final clean = sanitize(data);

    final fullName = _firstValue(clean, [
      'fullName',
      'name',
      'displayName',
      'firstName',
      'userName',
    ]);

    final email = _firstValue(clean, ['email', 'userEmail']);
    final phone = _firstValue(clean, [
      'phone',
      'phoneNumber',
      'mobile',
      'telephone',
      'phoneNormalized',
    ]);

    final username = _firstValue(clean, ['username', 'userName', 'nickName']);
    final gender = _firstValue(clean, ['gender', 'sex']);
    final photoUrl = _firstValue(clean, [
      'profileImageUrl',
      'photoUrl',
      'photoURL',
      'avatarUrl',
      'imageUrl',
    ]);

    final providerRaw = clean['authProvider'] ?? clean['provider'] ?? clean['loginProvider'];
    final provider = _providerLabel(providerRaw);

    final createdAt = _parseDate(clean['createdAt'] ?? clean['accountCreatedAt']);
    final lastLoginAt = _parseDate(clean['lastLoginAt'] ?? clean['lastActivity'] ?? clean['lastSeenAt']);

    return AdminUserProfile(
      uid: uid,
      raw: clean,
      fullName: fullName,
      email: email,
      phone: phone,
      username: username,
      gender: gender,
      provider: provider,
      status: _statusLabel(clean),
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      photoUrl: photoUrl == 'غير متوفر' ? '' : photoUrl,
    );
  }
}
