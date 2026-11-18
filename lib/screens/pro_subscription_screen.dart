import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../models/subscription_model.dart';
import '../providers/auth_provider.dart';
import '../services/subscription_service.dart';
import '../services/r2_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import '../widgets/pro_badge.dart';

/// شاشة باقات واشتراكات مراجعي Pro المطورة بالكامل
class ProSubscriptionScreen extends StatefulWidget {
  const ProSubscriptionScreen({super.key});

  @override
  State<ProSubscriptionScreen> createState() => _ProSubscriptionScreenState();
}

class _ProSubscriptionScreenState extends State<ProSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final _service = SubscriptionService();
  late final TabController _tabController;

  // الباقة وطريقة الدفع المحددة
  SubscriptionPlan? _selectedPlan;
  PaymentMethod? _selectedMethod;
  PromoCode? _appliedPromo;

  // وحدات التحكم بالمدخلات
  final _promoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  // الوصل وبيانات الحالة
  Uint8List? _receiptBytes;
  String? _receiptBase64;
  int _receiptSizeBytes = 0;
  bool _isSubmitting = false;
  String? _promoError;

  // رقم الحساب المعتمد والمستفيد
  static const String receiverNumber = '26270009';
  static const String beneficiaryName = 'مراجعي | MERAJ3I';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.seedDefaultsIfEmpty();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userData?['phone'] != null) {
        _phoneCtrl.text = auth.userData!['phone'].toString();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promoCtrl.dispose();
    _phoneCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  // ─── اختيار صورة الوصل ─────────────────────────────────────────────────────
  Future<void> _pickReceipt() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _receiptBytes = bytes;
        _receiptBase64 = base64Encode(bytes);
        _receiptSizeBytes = bytes.lengthInBytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصورة: $e')),
        );
      }
    }
  }

  void _clearReceipt() {
    setState(() {
      _receiptBytes = null;
      _receiptBase64 = null;
      _receiptSizeBytes = 0;
    });
  }

  // ─── تطبيق كود الخصم ───────────────────────────────────────────────────────
  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;

    final promo = await _service.verifyPromoCode(code);
    if (promo == null) {
      setState(() {
        _promoError = 'كود الخصم غير صالح أو منتهي الصلاحية';
        _appliedPromo = null;
      });
      return;
    }

    setState(() {
      _appliedPromo = promo;
      _promoError = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تطبيق خصم ${promo.discountPercent.round()}% بنجاح! 🎉'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── حساب السعر النهائي بعد الخصم ───────────────────────────────────────────
  double _calculateFinalPrice(SubscriptionPlan plan) {
    double price = plan.currentPrice;
    if (_appliedPromo != null) {
      final discountAmount = price * (_appliedPromo!.discountPercent / 100);
      price -= discountAmount;
    }
    return price < 0 ? 0 : price;
  }

  // ─── إرسال طلب الاشتراك ─────────────────────────────────────────────────────
  Future<void> _submitRequest() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول أولاً لإرسال طلب الاشتراك'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار باقة الاشتراك المناسبة لك'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد طريقة الدفع المستخدمة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_receiptBase64 == null || _receiptBase64!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إرفاق صورة إثبات التحويل / وصل الدفع'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final finalAmount = _calculateFinalPrice(_selectedPlan!);

      // محاولة رفع وصل التحويل إلى منصة Cloudflare R2
      String? r2ImageUrl;
      if (_receiptBytes != null) {
        try {
          r2ImageUrl = await R2StorageService().uploadPaymentProof(
            userId: auth.user!.uid,
            bytes: _receiptBytes!,
          );
        } catch (e) {
          debugPrint('[ProSubscriptionScreen] R2 upload fallback to base64: $e');
        }
      }

      final req = PaymentRequest(
        id: '',
        userId: auth.user!.uid,
        userEmail: auth.user!.email ?? '',
        userName: auth.userData?['name']?.toString() ??
            auth.user!.displayName ??
            'طالب مراجعي',
        userPhone: _phoneCtrl.text.trim(),
        planId: _selectedPlan!.id,
        planName: _selectedPlan!.name,
        planDays: _selectedPlan!.durationDays,
        amount: finalAmount,
        paymentMethodId: _selectedMethod!.id,
        paymentMethodName: _selectedMethod!.name,
        transactionRef: _refCtrl.text.trim(),
        proofImageBase64: _receiptBase64!,
        proofImageUrl: r2ImageUrl,
        createdAt: DateTime.now(),
      );

      await _service.submitPaymentRequest(req);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _receiptBytes = null;
        _receiptBase64 = null;
        _receiptSizeBytes = 0;
        _refCtrl.clear();
      });

      _tabController.animateTo(1);

      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981), size: 26),
                ),
                const SizedBox(width: 10),
                Text(
                  'تم إرسال الطلب بنجاح',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              'استلمنا طلب اشتراكك وإثبات الدفع بنجاح. سيتم التحقق من التحويل وتفعيل مميزات Pro لحسابك خلال وقت وجيز مع إشعارك فوراً.\n\nملاحظة: إذا كان حسابك مشتركاً مسبقاً فستُضاف المدة الجديدة تراكمياً إلى رصيدك الحالي دون خسارة أي يوم!',
              style: GoogleFonts.tajawal(height: 1.5, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'متابعة حالة الطلب',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F766E),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الطلب: $e')),
      );
    }
  }

  // ─── نسخ النص إلى الحافظة ──────────────────────────────────────────────────
  void _copyToClipboard(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMsg),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFC);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: bg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const CurvedHeader(
              title: 'ترقية الحساب إلى Pro',
              gradient: LinearGradient(
                colors: [Color(0xFF92400E), Color(0xFFD97706), Color(0xFFF59E0B)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            Container(
              color: isDark ? const Color(0xFF131D2A) : Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFF59E0B),
                indicatorWeight: 3,
                labelColor: const Color(0xFFF59E0B),
                unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                labelStyle: GoogleFonts.tajawal(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.workspace_premium_rounded, size: 20),
                    text: 'الباقات والاشتراك',
                  ),
                  Tab(
                    icon: Icon(Icons.receipt_long_rounded, size: 20),
                    text: 'طلباتي وحالتي',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlansAndCheckoutTab(isDark, auth),
                  _buildMyRequestsTab(isDark, auth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── تبويب الباقات ونموذج الدفع ─────────────────────────────────────────────
  Widget _buildPlansAndCheckoutTab(bool isDark, AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 36),
      children: [
        // 1) بطاقة حالة الحساب الذكية في أعلى الصفحة
        _buildAccountStatusCard(isDark, auth),

        const SizedBox(height: 14),

        // 2) باقات الاشتراك في شبكة مدمجة 2x2
        _buildPlansGridSection(isDark),

        const SizedBox(height: 14),

        // 3) جدول المقارنة بين الحساب العادي و Pro
        _buildComparisonCard(isDark),

        const SizedBox(height: 14),

        // 4) كود الخصم الإضافي
        _buildPromoCodeSection(isDark),

        const SizedBox(height: 14),

        // 5) بطاقة رقم الاستلام المعتمد ووسائل الدفع
        _buildPaymentTransferSection(isDark),

        const SizedBox(height: 14),

        // 6) نموذج إرفاق الوصل وتأكيد الإرسال
        _buildCheckoutForm(isDark),
      ],
    );
  }

  // ─── 1. بطاقة حالة الحساب الذكية ─────────────────────────────────────────────
  Widget _buildAccountStatusCard(bool isDark, AuthProvider auth) {
    // في حال كان المستخدم مشتركاً نشطاً في Pro
    if (auth.isPro) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF78350F), Color(0xFFB45309)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB45309).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ProBadge(fontSize: 11),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'حسابك مشترك ونشط (Pro)',
                    style: GoogleFonts.tajawal(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'متبقي: ${auth.proDaysRemaining}',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFEF3C7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (auth.proExpiresAt != null)
              Text(
                'تاريخ الانتهاء: ${DateFormat('dd/MM/yyyy').format(auth.proExpiresAt!)}',
                style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.white70),
              ),
            const SizedBox(height: 6),
            Text(
              '⚡ تجديد مبكر: عند الاشتراك الآن ستُضاف المدة الجديدة تراكمياً إلى رصيدك المتبقي دون أن تفقد أي يوم!',
              style: GoogleFonts.tajawal(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFDE68A),
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    // فحص إذا كان هناك طلب قيد المراجعة أو مرفوض حديثاً للمستخدم
    if (auth.user != null) {
      return StreamBuilder<List<PaymentRequest>>(
        stream: _service.streamUserRequests(auth.user!.uid),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          if (requests.isNotEmpty) {
            final latestReq = requests.first;
            if (latestReq.isPending) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب اشتراكك قيد المراجعة',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            'باقة ${latestReq.planName} • نتحقق من الوصل وسيتم التفعيل قريباً.',
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: Text(
                        'عرض',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (latestReq.isRejected) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDC2626), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel_rounded,
                            color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'تعذر قبول طلب الاشتراك السابق',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    if (latestReq.rejectionReason != null &&
                        latestReq.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'السبب: ${latestReq.rejectionReason}',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'يمكنك إعادة إرسال الطلب مع إرفاق الوصل الصحيح أدناه.',
                      style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
          }

          // المستخدم العادي (Free)
          return _buildFreeWelcomeBanner(isDark);
        },
      );
    }

    return _buildFreeWelcomeBanner(isDark);
  }

  Widget _buildFreeWelcomeBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أنت تستخدم الحساب العادي (Free)',
                  style: GoogleFonts.tajawal(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'قم بالترقية لإزالة الإعلانات وفتح جميع بنوك الاختبارات والامتحانات والحلول.',
                  style: GoogleFonts.tajawal(
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. باقات الاشتراك (شبكة 2x2 مدمجة ودقيقة) ───────────────────────────────
  Widget _buildPlansGridSection(bool isDark) {
    return StreamBuilder<List<SubscriptionPlan>>(
      stream: _service.streamPlans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
            ),
          );
        }

        final plans = snapshot.data ?? [];
        if (plans.isEmpty) {
          return Center(
            child: Text(
              'لا توجد باقات متاحة حالياً',
              style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        _selectedPlan ??= plans.firstWhere(
          (p) => p.isPopular,
          orElse: () => plans.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFF59E0B), size: 18),
                const SizedBox(width: 6),
                Text(
                  'اختر باقة الاشتراك المناسبة:',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // عرض الباقات في شبكة مدمجة 2x2
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _buildCompactPlanCard(plan, isDark);
              },
            ),
          ],
        );
      },
    );
  }

  // بطاقة الباقة المدمجة والمقاومة لتجاوز النصوص
  Widget _buildCompactPlanCard(SubscriptionPlan plan, bool isDark) {
    final isSelected = _selectedPlan?.id == plan.id;
    final finalPrice = _calculateFinalPrice(plan);

    return InkWell(
      onTap: () => setState(() => _selectedPlan = plan),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : const Color(0xFFFFFBEB))
              : (isDark ? const Color(0xFF16202E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // السطر العلوي: دائرة الاختيار والشارة
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? const Color(0xFFF59E0B) : Colors.grey,
                  size: 16,
                ),
                const Spacer(),
                if (plan.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                      child: Text(
                        'الأكثر توفيراً ⭐',
                        style: GoogleFonts.tajawal(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                  )
                else if (plan.hasDiscount && plan.discountPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'خصم ${plan.discountPercentage}%',
                      style: GoogleFonts.tajawal(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            // عنوان الباقة
            Text(
              plan.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),

            // المدة بالأيام
            Text(
              '${plan.durationDays} يوماً متواصلاً',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),

            // السعر والشطب
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${finalPrice.round()}',
                  style: GoogleFonts.tajawal(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  'أوقية',
                  style: GoogleFonts.tajawal(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (plan.hasDiscount && plan.originalPrice > plan.discountedPrice) ...[
                  const Spacer(),
                  Text(
                    '${plan.originalPrice.round()}',
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),

            // عداد انتهاء العرض (إن وُجد)
            if (plan.hasDiscount && plan.discountEndsAt != null && plan.isDiscountActive)
              _DiscountCountdownBadge(endsAt: plan.discountEndsAt!, isDark: isDark),
          ],
        ),
      ),
    );
  }

  // ─── 3. جدول المقارنة بين الحساب العادي و Pro ────────────────────────────────
  Widget _buildComparisonCard(bool isDark) {
    final rows = [
      ('إعلانات المنصة', 'تظهر إعلانات', false, 'بدون أي إعلانات نهائياً', true),
      ('بنك الأسئلة والاختبارات', 'وصول جزئي فقط', false, 'وصول كامل وغير محدود', true),
      ('الامتحانات الوطنية والحلول', 'نماذج محدودة', false, 'جميع الامتحانات والحلول', true),
      ('الحاسبة الذكية ومتابعة المستوى', 'وظائف أساسية', false, 'حاسبة متطورة ورسوم بيانية', true),
      ('شارة التميز الذهبية', 'حساب عادي', false, 'شارة Pro رسمية مع الاسم', true),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text(
                'ماذا يميز حساب Pro عن الحساب العادي؟',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // رأس الجدول
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'الخدمة / الميزة',
                    style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'الحساب العادي',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'حساب Pro ⭐',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // صفوف المقارنة
          ...rows.map((r) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.$1,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded, size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            r.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(fontSize: 9.5, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            r.$4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── 4. قسم كود الخصم ───────────────────────────────────────────────────────
  Widget _buildPromoCodeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.discount_rounded, color: Color(0xFFF59E0B), size: 17),
              const SizedBox(width: 6),
              Text(
                'هل تمتلك كود خصم إضافي؟',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.tajawal(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'أدخل الكود (مثال: PRO2026)',
                    hintStyle: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'تطبيق',
                  style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_promoError != null) ...[
            const SizedBox(height: 4),
            Text(
              _promoError!,
              style: GoogleFonts.tajawal(fontSize: 11, color: const Color(0xFFDC2626)),
            ),
          ],
          if (_appliedPromo != null) ...[
            const SizedBox(height: 4),
            Text(
              '✓ تم تفعيل الخصم: ${_appliedPromo!.code} (${_appliedPromo!.discountPercent.round()}%)',
              style: GoogleFonts.tajawal(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 5. قسم رقم التحويل المعتمد وطرق الدفع الوطنية ────────────────────────────
  Widget _buildPaymentTransferSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // شريط رقم الحساب الرسمي
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الدفع المعتمد: $receiverNumber',
                        style: GoogleFonts.tajawal(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'اسم المستفيد: $beneficiaryName',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFCCFBF1),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(
                    receiverNumber,
                    'تم نسخ رقم الدفع: $receiverNumber بنجاح ✅',
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0F766E)),
                        const SizedBox(width: 4),
                        Text(
                          'نسخ الرقم',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'اختر المحفظة المستخدمة للتحويل:',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          // بث طرق الدفع الموريتانية (بنكيلي، مصرفي، سداد)
          StreamBuilder<List<PaymentMethod>>(
            stream: _service.streamPaymentMethods(),
            builder: (context, snapshot) {
              final methods = snapshot.data ?? [];
              if (methods.isNotEmpty && _selectedMethod == null) {
                _selectedMethod = methods.first;
              }

              if (methods.isEmpty) {
                return Text(
                  'جاري تحميل وسائل الدفع...',
                  style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                );
              }

              return Row(
                children: methods.map((method) {
                  final isChosen = _selectedMethod?.id == method.id;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = method),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isChosen
                                ? (isDark
                                    ? const Color(0xFF0F766E).withValues(alpha: 0.2)
                                    : const Color(0xFFF0FDFA))
                                : (isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isChosen
                                  ? const Color(0xFF0D9488)
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              width: isChosen ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (method.iconAsset != null)
                                Image.asset(
                                  method.iconAsset!,
                                  height: 28,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 24,
                                    color: Color(0xFF0D9488),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 24,
                                  color: Color(0xFF0D9488),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                method.name.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.tajawal(
                                  fontSize: 11.5,
                                  fontWeight: isChosen ? FontWeight.w900 : FontWeight.w600,
                                  color: isChosen
                                      ? const Color(0xFF0D9488)
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── 6. نموذج إرفاق الوصل وتأكيد الإرسال ─────────────────────────────────────
  Widget _buildCheckoutForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_rounded, color: Color(0xFFF59E0B), size: 18),
              const SizedBox(width: 6),
              Text(
                'إرفاق وصل التحويل وتأكيد الاشتراك:',
                style: GoogleFonts.tajawal(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // زر إرفاق الوصل ومعاينته
          InkWell(
            onTap: _pickReceipt,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _receiptBytes != null
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  width: 1.5,
                ),
              ),
              child: _receiptBytes != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _receiptBytes!,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'تم إرفاق الوصل (${(_receiptSizeBytes / 1024).round()} KB)',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: _clearReceipt,
                              child: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.upload_file_rounded,
                            size: 34, color: isDark ? Colors.white54 : Colors.grey[500]),
                        const SizedBox(height: 6),
                        Text(
                          'اضغط هنا لرفع لقطة شاشة لوصل التحويل',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'صورة واضحة لرسالة أو إشعار البنك (بنكيلي، مصرفي، سداد)',
                          style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // رقم الهاتف (اختياري / تلقائي)
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.tajawal(fontSize: 12.5),
            decoration: InputDecoration(
              labelText: 'رقم هاتفك للتواصل (اختياري)',
              labelStyle: GoogleFonts.tajawal(fontSize: 11),
              hintText: 'مثال: 36000000',
              hintStyle: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),

          // رقم المرجع / اسم المرسل (اختياري)
          TextField(
            controller: _refCtrl,
            style: GoogleFonts.tajawal(fontSize: 12.5),
            decoration: InputDecoration(
              labelText: 'رقم العملية أو اسم المرسل (اختياري)',
              labelStyle: GoogleFonts.tajawal(fontSize: 11),
              hintText: 'رقم الإشعار أو المرجع',
              hintStyle: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
              prefixIcon: const Icon(Icons.tag_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          // شريط الملخص المالي
          if (_selectedPlan != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المبلغ المطلوب تحويله:',
                        style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[700]),
                      ),
                      Text(
                        '${_selectedPlan!.name} (${_selectedPlan!.durationDays} يوم)',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_calculateFinalPrice(_selectedPlan!).round()} أوقية',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // زر الإرسال النهائي
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'إرسال طلب الترقية وتأكيد الدفع',
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── تبويب طلباتي السابقة وحالة الاشتراك ────────────────────────────────────
  Widget _buildMyRequestsTab(bool isDark, AuthProvider auth) {
    if (auth.user == null) {
      return Center(
        child: Text(
          'يرجى تسجيل الدخول أولاً لمتابعة طلباتك',
          style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return StreamBuilder<List<PaymentRequest>>(
      stream: _service.streamUserRequests(auth.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 48, color: isDark ? Colors.white24 : Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد طلبات اشتراك سابقة',
                    style: GoogleFonts.tajawal(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عند إرسال طلب اشتراك سيظهر هنا لمتابعة مراجعته وتاريخ تفعيله.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return _buildRequestCard(req, isDark);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(PaymentRequest req, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (req.status) {
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusText = 'مقبول وتم تفعيل Pro';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        statusText = 'مرفوض';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'needs_info':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'يحتاج إلى معلومات إضافية';
        statusIcon = Icons.info_rounded;
        break;
      case 'pending':
      default:
        statusColor = const Color(0xFF3B82F6);
        statusText = 'قيد المراجعة من الإدارة';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    final dateStr = DateFormat('dd/MM/yyyy • hh:mm a').format(req.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  req.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.tajawal(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'المبلغ: ${req.amount.round()} أوقية • عبر ${req.paymentMethodName}',
            style: GoogleFonts.tajawal(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'تاريخ الإرسال: $dateStr',
            style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey),
          ),
          if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'سبب الرفض: ${req.rejectionReason}',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── شارة عداد انتهاء الخصم معزولة وثابتة تماماً ──────────────────────────────
class _DiscountCountdownBadge extends StatefulWidget {
  final DateTime endsAt;
  final bool isDark;

  const _DiscountCountdownBadge({
    required this.endsAt,
    required this.isDark,
  });

  @override
  State<_DiscountCountdownBadge> createState() => _DiscountCountdownBadgeState();
}

class _DiscountCountdownBadgeState extends State<_DiscountCountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.endsAt.difference(DateTime.now());
    if (diff.isNegative) return const SizedBox.shrink();

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_rounded, size: 10, color: Color(0xFFDC2626)),
            const SizedBox(width: 3),
            Text(
              '$days ي و ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDC2626),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
