import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginActivityService {
  AdminLoginActivityService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamForUser(
    String uid, {
    int limit = 30,
  }) {
    return _firestore
        .collection('login_attempts')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  static Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamIssues({
    int limit = 50,
  }) {
    return _firestore
        .collection('login_attempts')
        .where('needsSupport', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  static String resultLabel(String result) {
    switch (result) {
      case 'success':
        return 'نجاح';
      case 'invalid_password':
        return 'كلمة المرور غير صحيحة';
      case 'account_not_found':
        return 'الحساب غير موجود';
      case 'invalid_credential':
        return 'بيانات الدخول غير صحيحة';
      case 'account_suspended':
        return 'الحساب موقوف';
      case 'account_disabled':
        return 'الحساب معطل';
      case 'network_error':
        return 'مشكلة في الشبكة';
      case 'service_unavailable':
        return 'الخدمة غير متاحة مؤقتًا';
      case 'repeated_failure':
        return 'محاولات فاشلة متكررة';
      case 'system_error':
        return 'مشكلة في النظام';
      default:
        return 'فشل تسجيل الدخول';
    }
  }

  static String methodLabel(String method) {
    switch (method) {
      case 'email':
        return 'البريد الإلكتروني';
      case 'phone':
        return 'رقم الهاتف';
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      default:
        return 'غير متوفر';
    }
  }

  static DateTime? dateValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String formatDate(Object? value) {
    final date = dateValue(value);
    if (date == null) return 'غير متوفر';
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
