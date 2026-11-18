import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _plansCol =>
      _firestore.collection('subscription_plans');
  CollectionReference<Map<String, dynamic>> get _methodsCol =>
      _firestore.collection('payment_methods');
  CollectionReference<Map<String, dynamic>> get _requestsCol =>
      _firestore.collection('payment_requests');
  CollectionReference<Map<String, dynamic>> get _promoCodesCol =>
      _firestore.collection('promo_codes');
  DocumentReference<Map<String, dynamic>> get _featuresDoc =>
      _firestore.collection('app_settings').doc('feature_permissions');
  DocumentReference<Map<String, dynamic>> get _adsDoc =>
      _firestore.collection('ad_settings').doc('config');

  /// بث الباقات المتاحة
  Stream<List<SubscriptionPlan>> streamPlans() {
    return _plansCol
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(SubscriptionPlan.fromFirestore).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  /// بث طرق الدفع المتاحة
  Stream<List<PaymentMethod>> streamPaymentMethods() {
    return _methodsCol
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(PaymentMethod.fromFirestore).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  /// بث طلبات الدفع الخاصة بالمستخدم
  Stream<List<PaymentRequest>> streamUserRequests(String userId) {
    return _requestsCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(PaymentRequest.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// بث صلاحيات الخدمات (الصفحات المجانية والمدفوعة)
  Stream<Map<String, bool>> streamFeaturePermissions() {
    return _featuresDoc.snapshots().map((snap) {
      if (!snap.exists) {
        // الإعداد الافتراضي: الاختبارات والامتحانات مقفلة لغير المشتركين
        return {
          'quizzes': true, // pro only
          'national_exams': true, // pro only
          'books': false, // free
          'notes': false, // free
          'solutions': false, // free
        };
      }
      final data = snap.data() ?? {};
      final map = <String, bool>{};
      data.forEach((k, v) {
        if (v is bool) map[k] = v;
        if (v is Map && v['isProOnly'] != null) map[k] = v['isProOnly'] == true;
      });
      return map;
    });
  }

  /// بث إعدادات الإعلانات
  Stream<Map<String, dynamic>> streamAdSettings() {
    return _adsDoc.snapshots().map((snap) {
      if (!snap.exists) {
        return {
          'webAdsEnabled': true,
          'mobileAdsEnabled': true,
          'webPublisherId': 'ca-pub-0000000000000000',
          'mobileBannerId': 'ca-app-pub-3940256099942544/6300978111',
          'mobileInterstitialId': 'ca-app-pub-3940256099942544/1033173712',
        };
      }
      return snap.data() ?? {};
    });
  }

  /// التحقق من كود الخصم
  Future<PromoCode?> verifyPromoCode(String rawCode) async {
    final cleaned = rawCode.trim().toUpperCase();
    if (cleaned.isEmpty) return null;

    final doc = await _promoCodesCol.doc(cleaned).get();
    if (!doc.exists) return null;

    final promo = PromoCode.fromFirestore(doc);
    if (!promo.isValid) return null;
    return promo;
  }

  /// إرسال طلب اشتراك جديد
  Future<String> submitPaymentRequest(PaymentRequest req) async {
    final docRef = await _requestsCol.add(req.toMap());
    
    // إنشاء إشعار فوري للمستخدم في حسابه
    try {
      await _firestore.collection('notifications').add({
        'userId': req.userId,
        'title': 'تم استلام طلب اشتراكك بنجاح',
        'body': 'طلب اشتراكك في ${req.planName} قيد المراجعة الآن من قبل الإدارة وسيتم تفعيله قريباً.',
        'type': 'subscription',
        'targetId': docRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return docRef.id;
  }

  /// تهيئة الباقات الافتراضية وطرق الدفع إن كانت فارغة
  Future<void> seedDefaultsIfEmpty() async {
    try {
      final plansSnap = await _plansCol.limit(1).get();
      if (plansSnap.docs.isEmpty) {
        final defaultPlans = [
          SubscriptionPlan(
            id: 'monthly',
            name: 'Pro شهري',
            description: 'وصول كامل لكافة الاختبارات والامتحانات بدون إعلانات لمدة شهر',
            durationDays: 30,
            originalPrice: 150.0,
            discountedPrice: 100.0,
            hasDiscount: true,
            discountEndsAt: DateTime.now().add(const Duration(days: 30)),
            features: [
              'فتح كافة الاختبارات الذكية',
              'فتح الامتحانات الوطنية السابقة مع الحلول',
              'إزالة جميع الإعلانات نهائياً',
              'شارة Pro ذهبية على حسابك',
            ],
            order: 1,
          ),
          SubscriptionPlan(
            id: 'quarterly',
            name: 'Pro فصلي (3 أشهر)',
            description: 'مثالي للاستعداد لاختبارات الفصل الدراسي والمراجعة الشاملة',
            durationDays: 90,
            originalPrice: 400.0,
            discountedPrice: 250.0,
            hasDiscount: true,
            discountEndsAt: DateTime.now().add(const Duration(days: 30)),
            isPopular: true,
            features: [
              'كل مميزات الباقة الشهرية',
              'توفير 38% مقارنة بالاشتراك الشهري',
              'أولوية الدعم الفني والمراجعة',
            ],
            order: 2,
          ),
          SubscriptionPlan(
            id: 'semi_annual',
            name: 'Pro نصف سنوي (6 أشهر)',
            description: 'تغطية دراسية واسعة لنصف العام الدراسي مع تدريبات مكثفة',
            durationDays: 180,
            originalPrice: 750.0,
            discountedPrice: 450.0,
            hasDiscount: true,
            discountEndsAt: DateTime.now().add(const Duration(days: 30)),
            features: [
              'كل مميزات الباقة الفصلية',
              'توفير 40% من التكلفة الإجمالية',
              'دخول غير محدود لجميع التحديثات القادمة',
            ],
            order: 3,
          ),
          SubscriptionPlan(
            id: 'yearly',
            name: 'Pro سنوي (12 شهراً)',
            description: 'العرض الأقوى والأوفر لعام دراسي متكامل حتى نهاية المسابقات',
            durationDays: 365,
            originalPrice: 1400.0,
            discountedPrice: 790.0,
            hasDiscount: true,
            discountEndsAt: DateTime.now().add(const Duration(days: 30)),
            features: [
              'كل مميزات باقات مراجعي Pro',
              'أعلى نسبة توفير (حوالي 45%)',
              'الوصول المبكر لأي ميزة أو مسابقة جديدة',
            ],
            order: 4,
          ),
        ];

        for (final p in defaultPlans) {
          await _plansCol.doc(p.id).set(p.toMap());
        }
      }

      final methodsSnap = await _methodsCol.limit(1).get();
      // تهيئة أو تحديث طرق الدفع الأساسية بأرقام الحسابات الرسمية
      final defaultMethods = [
        const PaymentMethod(
          id: 'bankily',
          name: 'بنكيلي (Bankily)',
          code: 'bankily',
          accountNumber: '26270009',
          beneficiaryName: 'مراجعي | MERAJ3I',
          instructions: 'حوّل المبلغ إلى رقم بنكيلي 26270009 ثم التقط صورة لوصل التحويل وأرفقها في النموذج.',
          iconAsset: 'assets/pay/Bankily.png',
          order: 1,
        ),
        const PaymentMethod(
          id: 'masrvi',
          name: 'مصرفي (Masrvi)',
          code: 'masrvi',
          accountNumber: '26270009',
          beneficiaryName: 'مراجعي | MERAJ3I',
          instructions: 'حوّل المبلغ إلى رقم مصرفي 26270009 ثم التقط لقطة شاشة للوصل وأرفقها.',
          iconAsset: 'assets/pay/Masrvi.png',
          order: 2,
        ),
        const PaymentMethod(
          id: 'sedad',
          name: 'سداد (SEDAD)',
          code: 'sedad',
          accountNumber: '26270009',
          beneficiaryName: 'مراجعي | MERAJ3I',
          instructions: 'أرسل المبلغ عبر تطبيق سداد إلى الرقم 26270009 مع كتابة اسمك في الملاحظات ثم أرفق الوصل.',
          iconAsset: 'assets/pay/SEDAD.png',
          order: 3,
        ),
      ];

      for (final m in defaultMethods) {
        await _methodsCol.doc(m.id).set(m.toMap(), SetOptions(merge: true));
      }

      // كود خصم ترحيبي افتراضي PRO2026
      final promoDoc = await _promoCodesCol.doc('PRO2026').get();
      if (!promoDoc.exists) {
        await _promoCodesCol.doc('PRO2026').set({
          'code': 'PRO2026',
          'discountPercent': 15.0,
          'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
          'maxUses': 500,
          'timesUsed': 0,
          'isActive': true,
        });
      }

      // إعدادات إعلانات جوجل AdSense و AdMob المعتمدة
      await _adsDoc.set({
        'webAdsEnabled': true,
        'mobileAdsEnabled': true,
        'adSensePublisherId': 'ca-pub-7381352612061383',
        'adSenseSlotId': '2865554530',
        'adMobBannerId': 'ca-app-pub-3940256099942544/6300978111',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error seeding subscription defaults: $e');
    }
  }
}
