import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════
//  أنواع الأنشطة الإدارية
// ═══════════════════════════════════════════════════════════════
enum AdminActivityType {
  // المستخدمون
  userRegistered,
  userLoggedIn,
  userLoggedOut,
  userSuspended,
  userReactivated,
  userDeleted,
  userUpdated,
  userRoleChanged,
  passwordForced,

  // الإشعارات
  notificationSent,
  notificationRead,

  // الكتب والمحتوى
  bookAdded,
  bookUpdated,
  bookDeleted,
  bookFavorited,
  bookUnfavorited,
  bookDownloaded,
  contentUpdated,

  // المهام
  taskCreated,
  taskUpdated,
  taskDeleted,

  // الإعدادات
  settingChanged,
  featureEnabled,
  featureDisabled,
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
      case AdminActivityType.userRegistered:         return 'تسجيل مستخدم جديد';
      case AdminActivityType.userLoggedIn:           return 'تسجيل دخول';
      case AdminActivityType.userLoggedOut:          return 'تسجيل خروج';
      case AdminActivityType.userSuspended:          return 'تعليق حساب';
      case AdminActivityType.userReactivated:        return 'إعادة تفعيل حساب';
      case AdminActivityType.userDeleted:            return 'حذف حساب';
      case AdminActivityType.userUpdated:            return 'تعديل بيانات مستخدم';
      case AdminActivityType.userRoleChanged:        return 'تغيير صلاحية';
      case AdminActivityType.passwordForced:         return 'إجبار تغيير كلمة المرور';
      case AdminActivityType.notificationSent:       return 'إرسال إشعار';
      case AdminActivityType.notificationRead:       return 'قراءة إشعار';
      case AdminActivityType.bookAdded:              return 'إضافة كتاب';
      case AdminActivityType.bookUpdated:            return 'تعديل كتاب';
      case AdminActivityType.bookDeleted:            return 'حذف كتاب';
      case AdminActivityType.bookFavorited:          return 'إضافة إلى المفضلة';
      case AdminActivityType.bookUnfavorited:        return 'إزالة من المفضلة';
      case AdminActivityType.bookDownloaded:         return 'تنزيل كتاب';
      case AdminActivityType.contentUpdated:         return 'تحديث محتوى';
      case AdminActivityType.taskCreated:            return 'إنشاء مهمة';
      case AdminActivityType.taskUpdated:            return 'تعديل مهمة';
      case AdminActivityType.taskDeleted:            return 'حذف مهمة';
      case AdminActivityType.settingChanged:         return 'تغيير إعداد';
      case AdminActivityType.featureEnabled:         return 'تفعيل ميزة';
      case AdminActivityType.featureDisabled:        return 'تعطيل ميزة';
      case AdminActivityType.featureToggled:         return 'تفعيل/تعطيل ميزة';
      case AdminActivityType.maintenanceModeChanged: return 'وضع الصيانة';
      case AdminActivityType.examAdded:              return 'إضافة اختبار';
      case AdminActivityType.examUpdated:            return 'تعديل اختبار';
      case AdminActivityType.examDeleted:            return 'حذف اختبار';
      case AdminActivityType.adminLogin:             return 'دخول مسؤول';
      case AdminActivityType.generalActivity:        return 'نشاط عام';
    }
  }

  String get category {
    switch (this) {
      case AdminActivityType.userRegistered:
      case AdminActivityType.userLoggedIn:
      case AdminActivityType.userLoggedOut:
      case AdminActivityType.userSuspended:
      case AdminActivityType.userReactivated:
      case AdminActivityType.userDeleted:
      case AdminActivityType.userUpdated:
      case AdminActivityType.userRoleChanged:
      case AdminActivityType.passwordForced:
        return 'users';
      case AdminActivityType.notificationSent:
      case AdminActivityType.notificationRead:
        return 'notifications';
      case AdminActivityType.bookAdded:
      case AdminActivityType.bookUpdated:
      case AdminActivityType.bookDeleted:
      case AdminActivityType.bookFavorited:
      case AdminActivityType.bookUnfavorited:
      case AdminActivityType.bookDownloaded:
      case AdminActivityType.contentUpdated:
        return 'content';
      case AdminActivityType.taskCreated:
      case AdminActivityType.taskUpdated:
      case AdminActivityType.taskDeleted:
        return 'tasks';
      case AdminActivityType.settingChanged:
      case AdminActivityType.featureEnabled:
      case AdminActivityType.featureDisabled:
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

// ═══════════════════════════════════════════════════════════════
//  خدمة مركزية لتسجيل الأنشطة الإدارية في Firestore
// ═══════════════════════════════════════════════════════════════
class AdminActivityService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'admin_activity_logs';

  /// تسجيل نشاط — يفشل بصمت ولا يكسر أي تدفق رئيسي
  static Future<void> log({
    required AdminActivityType type,
    required String title,
    required String description,
    String? targetUserId,
    String? targetUserName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection(_collection).add({
        'type': type.name,
        'category': type.category,
        'title': title,
        'description': description,
        'adminId': user?.uid ?? 'system',
        'adminName': user?.displayName ?? user?.email ?? 'النظام',
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'metadata': metadata ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ActivityLog] log failed: $e');
    }
  }

  /// تحديث سجل كمقروء
  static Future<void> markAsRead(String docId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(docId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('[ActivityLog] markAsRead error: $e');
    }
  }

  /// تحديد الكل كمقروء
  static Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final unread = await _firestore
          .collection(_collection)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[ActivityLog] markAllAsRead error: $e');
    }
  }

  /// حذف سجل
  static Future<void> deleteLog(String docId) async {
    try {
      await _firestore.collection(_collection).doc(docId).delete();
    } catch (e) {
      debugPrint('[ActivityLog] deleteLog error: $e');
    }
  }

  /// مسح السجلات الأقدم من X أيام
  static Future<int> clearOlderThan(int days) async {
    try {
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
    } catch (e) {
      debugPrint('[ActivityLog] clearOlderThan error: $e');
      return 0;
    }
  }

  /// Stream عدد الإشعارات غير المقروءة
  static Stream<int> unreadCountStream() {
    try {
      return _firestore
          .collection(_collection)
          .snapshots()
          .map((s) => s.docs.where((d) => d.data()['isRead'] == false).length)
          .handleError((e) {
        debugPrint('[ActivityLog] unreadCountStream error: $e');
        return 0;
      });
    } catch (e) {
      debugPrint('[ActivityLog] unreadCountStream build error: $e');
      return Stream.value(0);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ الإصلاح الجوهري: جلب بدون where/orderBy مركب لتجنب FAILED_PRECONDITION
  // الفلترة تتم محلياً على العميل
  // ─────────────────────────────────────────────────────────────
  static Stream<List<QueryDocumentSnapshot>> logsStream({
    String? category,
    bool? unreadOnly,
  }) {
    try {
      return _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots()
          .map((snap) {
            return snap.docs.where((doc) {
              final data = doc.data();
              if (category != null && category != 'all') {
                if (data['category'] != category) return false;
              }
              if (unreadOnly == true) {
                if (data['isRead'] != false) return false;
              }
              return true;
            }).toList();
          })
          .handleError((dynamic e) {
            debugPrint('[ActivityLog] logsStream error: $e');
            // لا نُعيد قيمة هنا – نترك Flutter يتعامل مع hasError
          });
    } catch (e) {
      debugPrint('[ActivityLog] logsStream build error: $e');
      return const Stream.empty();
    }
  }
}

