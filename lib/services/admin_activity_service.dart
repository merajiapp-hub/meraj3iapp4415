import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// أنواع الأنشطة الإدارية
enum AdminActivityType {
  // المستخدمون
  userRegistered,
  userSuspended,
  userReactivated,
  userDeleted,
  userUpdated,
  userRoleChanged,
  passwordForced,

  // الإشعارات
  notificationSent,

  // الكتب والمحتوى
  bookAdded,
  bookUpdated,
  bookDeleted,
  contentUpdated,

  // الإعدادات
  settingChanged,
  featureToggled,
  maintenanceModeChanged,

  // الاختبارات
  examAdded,
  examUpdated,
  examDeleted,

  // عام
  adminLogin,
  generalActivity,
}

extension AdminActivityTypeExtension on AdminActivityType {
  String get label {
    switch (this) {
      case AdminActivityType.userRegistered:    return 'تسجيل مستخدم جديد';
      case AdminActivityType.userSuspended:     return 'تعليق حساب';
      case AdminActivityType.userReactivated:   return 'إعادة تفعيل حساب';
      case AdminActivityType.userDeleted:       return 'حذف حساب';
      case AdminActivityType.userUpdated:       return 'تعديل بيانات مستخدم';
      case AdminActivityType.userRoleChanged:   return 'تغيير صلاحية';
      case AdminActivityType.passwordForced:    return 'إجبار تغيير كلمة المرور';
      case AdminActivityType.notificationSent:  return 'إرسال إشعار';
      case AdminActivityType.bookAdded:         return 'إضافة كتاب';
      case AdminActivityType.bookUpdated:       return 'تعديل كتاب';
      case AdminActivityType.bookDeleted:       return 'حذف كتاب';
      case AdminActivityType.contentUpdated:    return 'تحديث محتوى';
      case AdminActivityType.settingChanged:    return 'تغيير إعداد';
      case AdminActivityType.featureToggled:    return 'تفعيل/تعطيل ميزة';
      case AdminActivityType.maintenanceModeChanged: return 'وضع الصيانة';
      case AdminActivityType.examAdded:         return 'إضافة اختبار';
      case AdminActivityType.examUpdated:       return 'تعديل اختبار';
      case AdminActivityType.examDeleted:       return 'حذف اختبار';
      case AdminActivityType.adminLogin:        return 'دخول مسؤول';
      case AdminActivityType.generalActivity:   return 'نشاط عام';
    }
  }

  String get category {
    switch (this) {
      case AdminActivityType.userRegistered:
      case AdminActivityType.userSuspended:
      case AdminActivityType.userReactivated:
      case AdminActivityType.userDeleted:
      case AdminActivityType.userUpdated:
      case AdminActivityType.userRoleChanged:
      case AdminActivityType.passwordForced:
        return 'users';
      case AdminActivityType.notificationSent:
        return 'notifications';
      case AdminActivityType.bookAdded:
      case AdminActivityType.bookUpdated:
      case AdminActivityType.bookDeleted:
      case AdminActivityType.contentUpdated:
        return 'content';
      case AdminActivityType.settingChanged:
      case AdminActivityType.featureToggled:
      case AdminActivityType.maintenanceModeChanged:
        return 'settings';
      case AdminActivityType.examAdded:
      case AdminActivityType.examUpdated:
      case AdminActivityType.examDeleted:
        return 'exams';
      default:
        return 'general';
    }
  }
}

/// خدمة مركزية لتسجيل الأنشطة الإدارية في Firestore
class AdminActivityService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'admin_activity_logs';

  /// تسجيل نشاط إداري
  static Future<void> log({
    required AdminActivityType type,
    required String title,
    required String description,
    String? targetUserId,
    String? targetUserName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final adminUser = FirebaseAuth.instance.currentUser;
      await _firestore.collection(_collection).add({
        'type': type.name,
        'category': type.category,
        'title': title,
        'description': description,
        'adminId': adminUser?.uid ?? 'system',
        'adminName': adminUser?.displayName ?? adminUser?.email ?? 'النظام',
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'metadata': metadata ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail - logging should not break main flows
    }
  }

  /// تحديث إشعار كمقروء
  static Future<void> markAsRead(String docId) async {
    await _firestore.collection(_collection).doc(docId).update({'isRead': true});
  }

  /// تحديد الكل كمقروء
  static Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final unread = await _firestore
        .collection(_collection)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// حذف إشعار
  static Future<void> deleteLog(String docId) async {
    await _firestore.collection(_collection).doc(docId).delete();
  }

  /// مسح الإشعارات القديمة (أقدم من X أيام)
  static Future<int> clearOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _firestore
        .collection(_collection)
        .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snap.docs.length;
  }

  /// Stream لعدد الإشعارات غير المقروءة
  static Stream<int> unreadCountStream() {
    return _firestore
        .collection(_collection)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Stream للإشعارات مع فلتر
  static Stream<QuerySnapshot> logsStream({String? category, bool? unreadOnly}) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }
    if (unreadOnly == true) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots();
  }
}
