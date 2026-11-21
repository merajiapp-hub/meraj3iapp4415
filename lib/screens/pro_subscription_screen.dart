import 'dart:async';
import 'dart:convert';
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
  late final Stream<List<SubscriptionPlan>> _plansStream;
  late final Stream<List<PaymentMethod>> _paymentMethodsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service.seedDefaultsIfEmpty();
    _plansStream = _service.streamPlans();
    _paymentMethodsStream = _service.streamPaymentMethods();

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
          backgroundColor: const Color(0xFF006C4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoCtrl.clear();
      _promoError = null;
    });
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
                    color: const Color(0xFF1A146B),
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
        backgroundColor: const Color(0xFF1A146B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0F1D) : const Color(0xFFFAF8FF);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildStandardAppBar(isDark),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // شريط التبويب الأنيق (الباقات والاشتراك | طلباتي وحالتي)
            _buildTabBar(isDark),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // منع السحب باليد والتنقل بالضغط فقط
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

  // ─── رأس الصفحة القياسي المستوحى من الهوية الرسمية ────────────────────────
  PreferredSizeWidget _buildStandardAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_forward_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A146B),
          size: 22,
        ),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'اشتراكات Pro',
        style: GoogleFonts.tajawal(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A146B),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          height: 1,
        ),
      ),
    );
  }

  // ─── شريط التبويب الأنيق ──────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: isDark ? Colors.white : const Color(0xFF3525CD),
        unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
        labelStyle: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'الباقات والاشتراك'),
          Tab(text: 'طلباتي وحالتي'),
        ],
      ),
    );
  }

  // ─── تبويب الباقات ونموذج الدفع الاحترافي الكامل ───────────────────────────
  Widget _buildPlansAndCheckoutTab(bool isDark, AuthProvider auth) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        // 1) شريط عرض خصم العودة للدراسة المؤقت مع عداد رقمي حي
        _LimitedOfferCountdownWidget(isDark: isDark),

        const SizedBox(height: 14),

        // 3) بطاقة حالة الحساب الذكية للمشتركين
        _buildAccountStatusCard(isDark, auth),

        const SizedBox(height: 14),

        // 4) مقارنة سريعة بين المجاني و Pro (بطاقتان جنب إلى جنب)
        _buildSideBySideComparison(isDark),

        const SizedBox(height: 18),

        // 5) باقات الاشتراك الرأسية المطورة
        _buildVerticalPlansSection(isDark),

        const SizedBox(height: 16),

        // 6) كود الخصم الإضافي مع الاحتساب التفاعلي
        _buildPromoCodeSection(isDark),

        const SizedBox(height: 16),

        // 7) طرق الدفع الوطنية ورقم التحويل المعتمد
        _buildPaymentTransferSection(isDark),

        const SizedBox(height: 16),

        // 8) نموذج إرفاق الوصل وزر الإتمام الآمن المثبت
        _buildCheckoutForm(isDark),

        const SizedBox(height: 20),

        // 9) جدول مقارنة المزايا الشامل
        _buildFullFeatureComparisonTable(isDark),

        const SizedBox(height: 20),

        // 10) الأسئلة الشائعة القابلة للتوسيع (FAQ)
        _buildFaqSection(isDark),
      ],
    );
  }

  // ─── 2. بطاقة حالة الحساب الذكية ──────────────────────────────────────────
  Widget _buildAccountStatusCard(bool isDark, AuthProvider auth) {
    if (auth.isPro) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF78350F), Color(0xFFB45309)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(18),
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
    return const SizedBox.shrink();
  }

  // ─── 4. مقارنة سريعة بين المجاني و Pro (جنباً إلى جنب) ─────────────────────
  Widget _buildSideBySideComparison(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'مقارنة سريعة بين المجاني و Pro',
            style: GoogleFonts.tajawal(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF131B2E),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة Pro (الميزة الشاملة)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181836) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF3525CD),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3525CD).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3525CD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'الأفضل قيمة ⭐',
                        style: GoogleFonts.tajawal(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الميزة الشاملة',
                      style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                    Text(
                      'مراجعي Pro',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3525CD),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCompareRow(Icons.check_circle_rounded, 'وصول غير محدود للملخصات', const Color(0xFF059669)),
                    _buildCompareRow(Icons.check_circle_rounded, 'اختبارات تجريبية ذكية', const Color(0xFF059669)),
                    _buildCompareRow(Icons.check_circle_rounded, 'تصحيح ذاتي وشامل', const Color(0xFF059669)),
                    _buildCompareRow(Icons.check_circle_rounded, 'مراجعات نهائية حصرية', const Color(0xFF059669)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // بطاقة المجاني
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2A) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'الباقة الأساسية',
                      style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey[600]),
                    ),
                    Text(
                      'المجاني',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white70 : const Color(0xFF131B2E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCompareRow(Icons.cancel_rounded, 'تصفحات محدودة', const Color(0xFFEF4444)),
                    _buildCompareRow(Icons.cancel_rounded, 'بدون اختبارات ذكية', const Color(0xFFEF4444)),
                    _buildCompareRow(Icons.cancel_rounded, 'إعلانات متكررة', const Color(0xFFEF4444)),
                    _buildCompareRow(Icons.check_circle_rounded, 'الوصول العادي', const Color(0xFF059669)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompareRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color == const Color(0xFFEF4444)
                    ? const Color(0xFFEF4444)
                    : (color == const Color(0xFF059669) ? const Color(0xFF059669) : null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. باقات الاشتراك الرأسية المطورة ─────────────────────────────────────
  Widget _buildVerticalPlansSection(bool isDark) {
    return StreamBuilder<List<SubscriptionPlan>>(
      stream: _plansStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF3525CD)),
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
            Center(
              child: Text(
                'اختر باقة الاشتراك المناسبة لك',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF131B2E),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...plans.map((plan) => _buildVerticalPlanCard(plan, isDark)),
          ],
        );
      },
    );
  }

  Widget _buildVerticalPlanCard(SubscriptionPlan plan, bool isDark) {
    final isSelected = _selectedPlan?.id == plan.id;
    final finalPrice = _calculateFinalPrice(plan);

    // أيقونة مناسبة حسب المدة
    final IconData planIcon;
    if (plan.durationDays >= 365) {
      planIcon = Icons.workspace_premium_rounded;
    } else if (plan.durationDays >= 180) {
      planIcon = Icons.date_range_rounded;
    } else if (plan.durationDays >= 90) {
      planIcon = Icons.calendar_month_rounded;
    } else {
      planIcon = Icons.grid_view_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF181836) : const Color(0xFFEEF2FF))
            : (isDark ? const Color(0xFF131B2A) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3525CD)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF3525CD).withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _selectedPlan = plan),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // أيقونة الباقة
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3525CD).withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        planIcon,
                        size: 24,
                        color: isSelected ? const Color(0xFF3525CD) : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // تفاصيل الباقة والوصف
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: GoogleFonts.tajawal(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF131B2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.description.isNotEmpty
                                ? plan.description
                                : 'اشتراك مراجعي Pro لمدة ${plan.durationDays} يوماً',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // السعر وزر الاختيار
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${finalPrice.round()}',
                              style: GoogleFonts.tajawal(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF3525CD),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'أوقية',
                              style: GoogleFonts.tajawal(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ElevatedButton(
                          onPressed: () => setState(() => _selectedPlan = plan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? const Color(0xFF3525CD)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            foregroundColor: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF3525CD)),
                            elevation: isSelected ? 3 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isSelected ? 'تم الاختيار ✓' : 'اختيار',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // شارة الباقة الأكثر توفيراً في الزاوية العلوية
              if (plan.isPopular)
                Positioned(
                  top: -8,
                  left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3525CD),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3525CD).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'الموصى به (توفير 35%) ⭐',
                  style: GoogleFonts.tajawal(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ─── 6. كود الخصم الإضافي ─────────────────────────────────────────────────
  Widget _buildPromoCodeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'هل لديك كود خصم؟',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'أدخل الكود أدناه للحصول على خصم إضافي فوري على باقتك',
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'مثال: PRO2026',
                    hintStyle: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.grey),
                    prefixIcon: const Icon(Icons.discount_outlined, size: 18, color: Color(0xFF3525CD)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3525CD), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3525CD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'تطبيق',
                  style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (_promoError != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Text(
                  _promoError!,
                  style: GoogleFonts.tajawal(fontSize: 11, color: const Color(0xFFDC2626)),
                ),
              ],
            ),
          ],
          if (_appliedPromo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF82F5C1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF006C4A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تم تفعيل كود الخصم: ${_appliedPromo!.code} (خصم ${_appliedPromo!.discountPercent.round()}%)',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006C4A),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _removePromo,
                    borderRadius: BorderRadius.circular(4),
                    child: const Icon(Icons.cancel_rounded, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ),
            if (_selectedPlan != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع بعد الخصم:',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${_calculateFinalPrice(_selectedPlan!).round()} أوقية (وفّرت ${((_selectedPlan!.currentPrice * _appliedPromo!.discountPercent) / 100).round()} أوقية)',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF006C4A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── 7. طرق الدفع الوطنية ورقم التحويل المعتمد ────────────────────────────
  Widget _buildPaymentTransferSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر وسيلة الدفع المفضلة',
            style: GoogleFonts.tajawal(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 12),

          // بث وسائل الدفع الوطنية
          StreamBuilder<List<PaymentMethod>>(
            stream: _paymentMethodsStream,
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
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedMethod = method),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isChosen
                                ? (isDark ? const Color(0xFF181836) : const Color(0xFFEEF2FF))
                                : (isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isChosen
                                  ? const Color(0xFF3525CD)
                                  : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              width: isChosen ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 24,
                                color: isChosen ? const Color(0xFF3525CD) : Colors.grey[600],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                method.name.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.tajawal(
                                  fontSize: 11.5,
                                  fontWeight: isChosen ? FontWeight.w900 : FontWeight.w600,
                                  color: isChosen
                                      ? const Color(0xFF3525CD)
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
          const SizedBox(height: 14),

          // صندوق رقم التحويل المعتمد 26270009
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A146B), Color(0xFF312E81)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم التحويل المعتمد: $receiverNumber',
                        style: GoogleFonts.tajawal(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'اسم المستلم: $beneficiaryName',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(
                    receiverNumber,
                    'تم نسخ رقم الدفع: $receiverNumber بنجاح ✅',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: Text('نسخ الرقم', style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A146B),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 8. نموذج إرفاق الوصل وزر الإتمام الآمن ──────────────────────────────
  Widget _buildCheckoutForm(bool isDark) {
    final finalAmount = _selectedPlan != null ? _calculateFinalPrice(_selectedPlan!) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إرفاق إثبات الدفع وتأكيد الاشتراك',
            style: GoogleFonts.tajawal(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF131B2E),
            ),
          ),
          const SizedBox(height: 12),

          // منطقة رفع الوصل مع إطار منقط /dashed
          InkWell(
            onTap: _pickReceipt,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _receiptBytes != null
                      ? const Color(0xFF006C4A)
                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  width: 1.5,
                ),
              ),
              child: _receiptBytes != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _receiptBytes!,
                            height: 150,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF006C4A), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'تم إرفاق الوصل بنجاح (${(_receiptSizeBytes / 1024).round()} KB)',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF006C4A),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3525CD).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_upload_outlined,
                              size: 32, color: Color(0xFF3525CD)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ارفع إثبات الدفع (صورة التحويل)',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF131B2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'اسحب الصورة هنا أو اضغط للاختيار من الاستوديو',
                          style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // رقم الهاتف للتواصل
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.tajawal(fontSize: 12.5),
            decoration: InputDecoration(
              labelText: 'رقم الهاتف للتواصل (اختياري)',
              labelStyle: GoogleFonts.tajawal(fontSize: 11),
              hintText: 'مثال: 36000000',
              prefixIcon: const Icon(Icons.phone_outlined, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // المرجع أو اسم الحساب
          TextField(
            controller: _refCtrl,
            style: GoogleFonts.tajawal(fontSize: 12.5),
            decoration: InputDecoration(
              labelText: 'رقم الإشعار أو اسم المرسل (اختياري)',
              labelStyle: GoogleFonts.tajawal(fontSize: 11),
              hintText: 'رقم العملية أو المرجع',
              prefixIcon: const Icon(Icons.tag_rounded, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // كشف الحساب وتفاصيل المبلغ قبل الدفع
          if (_selectedPlan != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2D40) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'سعر الباقة (${_selectedPlan!.name}):',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${_selectedPlan!.currentPrice.round()} أوقية',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (_appliedPromo != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'كود الخصم (${_appliedPromo!.code} ${_appliedPromo!.discountPercent.round()}%):',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006C4A),
                          ),
                        ),
                        Text(
                          '- ${((_selectedPlan!.currentPrice * _appliedPromo!.discountPercent) / 100).round()} أوقية',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006C4A),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: isDark ? const Color(0xFF1E2D40) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المبلغ المطلوب تحويله:',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${finalAmount.round()} أوقية',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3525CD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // زر الإتمام الآمن الفخم والمثبت
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3525CD),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF3525CD).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _appliedPromo != null
                              ? 'إتمام الاشتراك الآمن (${finalAmount.round()} أوقية بعد الخصم)'
                              : 'إتمام الاشتراك الآمن (${finalAmount.round()} أوقية)',
                          style: GoogleFonts.tajawal(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
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

  // ─── 9. جدول مقارنة المزايا الشامل ────────────────────────────────────────
  Widget _buildFullFeatureComparisonTable(bool isDark) {
    final rows = [
      ('التلخيصات الذكية للمقررات', 'محدودة', 'وصول كامل وغير محدود'),
      ('بنك الاختبارات التجريبية', 'نماذج أساسية', 'متقدم وشامل مع الشرح'),
      ('المراجعات النهائية والتمارين', 'غير متاح', 'متاح حصرياً مع الحلول'),
      ('الدعم الفني المباشر', 'عادي', 'أولوية قصوى 24/7'),
      ('تجربة خالية من الإعلانات', 'غير متاح', 'خالية 100% من أي إعلانات'),
      ('التنزيل وتشغيل المحتوى أوفلاين', 'غير متاح', 'تنزيل فوري وتشغيل بدون إنترنت'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'جدول مقارنة المزايا الشامل',
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF131B2E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // رأس الجدول
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'الميزة',
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
                    'مراجعي Pro ⭐',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3525CD),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...rows.map((r) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    child: Text(
                      r.$2,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      r.$3,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF006C4A),
                      ),
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

  // ─── 10. الأسئلة الشائعة القابلة للتوسيع (FAQ) ─────────────────────────────
  Widget _buildFaqSection(bool isDark) {
    final faqs = [
      (
        'كيف يتم تفعيل الاشتراك بعد التحويل البنكي؟',
        'بمجرد إرسال طلب الاشتراك وإرفاق صورة وصل التحويل، يقوم فريق المراجعة بالتحقق من العملية وتفعيل باقة Pro لحسابك خلال دقائق قليلة مع إشعارك فوراً.'
      ),
      (
        'هل يمكنني استعادة قيمة الاشتراك إذا لم أكن راضياً؟',
        'نعم بكل تأكيد! نوفر ضمان استعادة الأموال بالكامل خلال 48 ساعة من الاشتراك في حال واجهت أي مشكلة فنية أو عدم رضا عن الخدمة.'
      ),
      (
        'هل الاشتراك يعمل على أكثر من جهاز؟',
        'نعم، يمكنك تسجيل الدخول بنفس الحساب على هاتفك وجهازك اللوحي والكمبيوتر والاستفادة من كافة مميزات Pro في نفس الوقت.'
      ),
      (
        'كيف يمكنني الاستفادة من ميزة التنزيل والمشاهدة بدون إنترنت؟',
        'عند اشتراكك في Pro يظهر زر «تنزيل الدرس» أسفل كل فيديو أو ملخص، مما يتيح لك حفظه داخل التطبيق ومشاهدته في أي وقت بدون استهلاك للإنترنت.'
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'الأسئلة الشائعة',
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF131B2E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...faqs.map((faq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: ExpansionTile(
                title: Text(
                  faq.$1,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF131B2E),
                  ),
                ),
                iconColor: const Color(0xFF3525CD),
                collapsedIconColor: Colors.grey,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    child: Text(
                      faq.$2,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        height: 1.4,
                      ),
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

class _LimitedOfferCountdownWidget extends StatefulWidget {
  final bool isDark;

  const _LimitedOfferCountdownWidget({required this.isDark});

  @override
  State<_LimitedOfferCountdownWidget> createState() => _LimitedOfferCountdownWidgetState();
}

class _LimitedOfferCountdownWidgetState extends State<_LimitedOfferCountdownWidget> {
  Timer? _timer;
  final DateTime _offerEndTime = DateTime.now().add(const Duration(days: 12, hours: 8, minutes: 45, seconds: 30));

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
    final diff = _offerEndTime.difference(DateTime.now());
    final isExpired = diff.isNegative;
    final isDark = widget.isDark;

    final days = isExpired ? 0 : diff.inDays;
    final hours = isExpired ? 0 : diff.inHours % 24;
    final minutes = isExpired ? 0 : diff.inMinutes % 60;
    final seconds = isExpired ? 0 : diff.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B18) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFCD34D),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF854D0E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: Color(0xFFFEF08A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عرض خصم العودة للدراسة',
                      style: GoogleFonts.tajawal(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      'خصم خاص على جميع الباقات لفترة محدودة جداً',
                      style: GoogleFonts.tajawal(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // صناديق العد التنازلي الرقمية الحية
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOfferTimeBox('$days', 'يوم', isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB45309))),
                ),
                _buildOfferTimeBox(hours.toString().padLeft(2, '0'), 'ساعة', isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB45309))),
                ),
                _buildOfferTimeBox(minutes.toString().padLeft(2, '0'), 'دقيقة', isDark),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFB45309))),
                ),
                _buildOfferTimeBox(seconds.toString().padLeft(2, '0'), 'ثانية', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferTimeBox(String value, String label, bool isDark) {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 42),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF292524) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFDE68A),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF92400E),
          ),
        ),
      ],
    );
  }
}
