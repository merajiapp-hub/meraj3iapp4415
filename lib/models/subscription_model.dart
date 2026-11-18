import 'package:cloud_firestore/cloud_firestore.dart';

/// باقة الاشتراك (شهرية، فصلية، نصف سنوية، سنوية)
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int durationDays;
  final double originalPrice;
  final double discountedPrice;
  final bool hasDiscount;
  final DateTime? discountEndsAt;
  final bool isPopular;
  final List<String> features;
  final int order;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.durationDays,
    required this.originalPrice,
    required this.discountedPrice,
    this.hasDiscount = false,
    this.discountEndsAt,
    this.isPopular = false,
    this.features = const [],
    this.order = 0,
    this.isActive = true,
  });

  double get currentPrice => hasDiscount && isDiscountActive ? discountedPrice : originalPrice;

  bool get isDiscountActive {
    if (!hasDiscount) return false;
    if (discountEndsAt == null) return true;
    return DateTime.now().isBefore(discountEndsAt!);
  }

  int get discountPercentage {
    if (originalPrice <= 0 || !hasDiscount || !isDiscountActive) return 0;
    final diff = originalPrice - discountedPrice;
    return ((diff / originalPrice) * 100).round();
  }

  factory SubscriptionPlan.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return SubscriptionPlan(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 30,
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble() ?? 0.0,
      hasDiscount: data['hasDiscount'] == true,
      discountEndsAt: parseDate(data['discountEndsAt']),
      isPopular: data['isPopular'] == true,
      features: (data['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'durationDays': durationDays,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'hasDiscount': hasDiscount,
      if (discountEndsAt != null) 'discountEndsAt': Timestamp.fromDate(discountEndsAt!),
      'isPopular': isPopular,
      'features': features,
      'order': order,
      'isActive': isActive,
    };
  }
}

/// طريقة الدفع المتاحة (بنكيلي، مصرفي، سداد، إلخ)
class PaymentMethod {
  final String id;
  final String name; // e.g. بنكيلي Bankily
  final String code; // bankily, masrvi, sedad, click, other
  final String accountNumber;
  final String beneficiaryName;
  final String instructions;
  final String? iconAsset;
  final bool isActive;
  final int order;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.code,
    required this.accountNumber,
    required this.beneficiaryName,
    this.instructions = '',
    this.iconAsset,
    this.isActive = true,
    this.order = 0,
  });

  factory PaymentMethod.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PaymentMethod(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      code: data['code']?.toString() ?? 'other',
      accountNumber: data['accountNumber']?.toString() ?? '',
      beneficiaryName: data['beneficiaryName']?.toString() ?? '',
      instructions: data['instructions']?.toString() ?? '',
      iconAsset: data['iconAsset']?.toString(),
      isActive: data['isActive'] != false,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'accountNumber': accountNumber,
      'beneficiaryName': beneficiaryName,
      'instructions': instructions,
      'iconAsset': iconAsset,
      'isActive': isActive,
      'order': order,
    };
  }
}

/// طلب الدفع والاشتراك المقدم من المستخدم
class PaymentRequest {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final String planId;
  final String planName;
  final int planDays;
  final double amount;
  final String paymentMethodId;
  final String paymentMethodName;
  final String transactionRef;
  final String proofImageBase64;
  final String? proofImageUrl;
  final String status; // pending, approved, rejected, needs_info
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const PaymentRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userPhone = '',
    required this.planId,
    required this.planName,
    required this.planDays,
    required this.amount,
    required this.paymentMethodId,
    required this.paymentMethodName,
    this.transactionRef = '',
    this.proofImageBase64 = '',
    this.proofImageUrl,
    this.status = 'pending',
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PaymentRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PaymentRequest(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userEmail: data['userEmail']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      userPhone: data['userPhone']?.toString() ?? '',
      planId: data['planId']?.toString() ?? '',
      planName: data['planName']?.toString() ?? '',
      planDays: (data['planDays'] as num?)?.toInt() ?? 30,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethodId: data['paymentMethodId']?.toString() ?? '',
      paymentMethodName: data['paymentMethodName']?.toString() ?? '',
      transactionRef: data['transactionRef']?.toString() ?? '',
      proofImageBase64: data['proofImageBase64']?.toString() ?? '',
      proofImageUrl: data['proofImageUrl']?.toString(),
      status: data['status']?.toString() ?? 'pending',
      rejectionReason: data['rejectionReason']?.toString(),
      createdAt: parseDate(data['createdAt']),
      reviewedAt: data['reviewedAt'] != null ? parseDate(data['reviewedAt']) : null,
      reviewedBy: data['reviewedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'planId': planId,
      'planName': planName,
      'planDays': planDays,
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'transactionRef': transactionRef,
      if (proofImageBase64.isNotEmpty) 'proofImageBase64': proofImageBase64,
      if (proofImageUrl != null) 'proofImageUrl': proofImageUrl,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
    };
  }
}

/// كود خصم
class PromoCode {
  final String id;
  final String code;
  final double discountPercent;
  final DateTime? expiresAt;
  final int maxUses;
  final int timesUsed;
  final bool isActive;

  const PromoCode({
    required this.id,
    required this.code,
    required this.discountPercent,
    this.expiresAt,
    this.maxUses = 100,
    this.timesUsed = 0,
    this.isActive = true,
  });

  bool get isValid {
    if (!isActive) return false;
    if (timesUsed >= maxUses) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  factory PromoCode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return PromoCode(
      id: doc.id,
      code: data['code']?.toString() ?? doc.id,
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
      expiresAt: parseDate(data['expiresAt']),
      maxUses: (data['maxUses'] as num?)?.toInt() ?? 100,
      timesUsed: (data['timesUsed'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code.toUpperCase().trim(),
      'discountPercent': discountPercent,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'maxUses': maxUses,
      'timesUsed': timesUsed,
      'isActive': isActive,
    };
  }
}
