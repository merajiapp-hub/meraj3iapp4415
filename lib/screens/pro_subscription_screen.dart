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
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import '../widgets/pro_badge.dart';

class ProSubscriptionScreen extends StatefulWidget {
  const ProSubscriptionScreen({super.key});

  @override
  State<ProSubscriptionScreen> createState() => _ProSubscriptionScreenState();
}

class _ProSubscriptionScreenState extends State<ProSubscriptionScreen>
    with SingleTickerProviderStateMixin {
  final _service = SubscriptionService();
  late final TabController _tabController;

  SubscriptionPlan? _selectedPlan;
  PaymentMethod? _selectedMethod;
  PromoCode? _appliedPromo;
  int _selectedMonths = 3;

  final _promoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  Uint8List? _receiptBytes;
  String? _receiptBase64;
  bool _isSubmitting = false;
  String? _promoError;

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

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _receiptBytes = bytes;
      _receiptBase64 = base64Encode(bytes);
    });
  }

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
          content: Text('تم تطبيق خصم ${promo.discountPercent.round()}% بنجاح!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  double _calculateFinalPrice(SubscriptionPlan plan) {
    double price = plan.currentPrice;
    if (_appliedPromo != null) {
      final discountAmount = price * (_appliedPromo!.discountPercent / 100);
      price -= discountAmount;
    }
    return price < 0 ? 0 : price;
  }

  Future<void> _submitRequest() async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً لإرسال طلب الاشتراك')),
      );
      return;
    }

    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار باقة الاشتراك المناسبة')),
      );
      return;
    }

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار طريقة الدفع المستخدمة')),
      );
      return;
    }

    if (_receiptBase64 == null || _receiptBase64!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إرفاق صورة إثبات التحويل / وصل الدفع')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final finalAmount = _calculateFinalPrice(_selectedPlan!);
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
        createdAt: DateTime.now(),
      );

      await _service.submitPaymentRequest(req);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _receiptBytes = null;
        _receiptBase64 = null;
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
                      color: Color(0xFF10B981), size: 28),
                ),
                const SizedBox(width: 10),
                const Text('تم إرسال الطلب بنجاح'),
              ],
            ),
            content: const Text(
              'استلمنا طلب اشتراكك وإثبات الدفع بنجاح. سيتم التحقق من التحويل وتفعيل مميزات Pro لحسابك خلال وقت وجيز مع إشعارك فوراً.',
              style: TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('متابعة حالة الطلب',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
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
                  fontSize: 14,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // بانر حالة المشترك الحالي
        if (auth.isPro) ...[
          _buildActiveSubscriberBanner(isDark, auth),
          const SizedBox(height: 20),
        ],

        // ─── اختيار مدة الاشتراك وعدد الأشهر ───
        _buildDurationSelector(isDark),

        const SizedBox(height: 16),

        // الباقات المتاحة
        StreamBuilder<List<SubscriptionPlan>>(
          stream: _service.streamPlans(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                ),
              );
            }

            final plans = snapshot.data ?? [];
            if (plans.isEmpty) {
              return Center(
                child: Text(
                  'لا توجد باقات متاحة حالياً',
                  style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey),
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
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'الباقات المتوفرة للمدة المحددة:',
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...plans.map((plan) => _buildPlanCard(plan, isDark)),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // قسم كود الخصم
        _buildPromoCodeSection(isDark),

        const SizedBox(height: 16),

        // طرق الدفع الموريتانية (بنكيلي، مصرفي، سداد...)
        StreamBuilder<List<PaymentMethod>>(
          stream: _service.streamPaymentMethods(),
          builder: (context, snapshot) {
            final methods = snapshot.data ?? [];
            if (methods.isNotEmpty && _selectedMethod == null) {
              _selectedMethod = methods.first;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'اختر طريقة الدفع (رقم الاستلام المعتمد 26270009):',
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (methods.isEmpty)
                  Text(
                    'جاري تحميل طرق الدفع المعتمدة...',
                    style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                  )
                else
                  ...methods.map((method) => _buildPaymentMethodCard(method, isDark)),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // نموذج إرفاق الوصل والدفع
        _buildCheckoutForm(isDark),
      ],
    );
  }

  // ─── محدد عدد الأشهر التفاعلي والمدة ─────────────────────────────────────
  Widget _buildDurationSelector(bool isDark) {
    final durations = [
      (1, 'شهر واحد', '30 يوم'),
      (3, '3 أشهر (فصلي)', 'توفير 38%'),
      (6, '6 أشهر', 'توفير 40%'),
      (12, '12 شهراً (سنوي)', 'الأوفر 45%'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'تحديد مدة الاشتراك (بالأشهر):',
                    style: GoogleFonts.tajawal(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              // عداد الأشهر السريع
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _selectedMonths > 1
                          ? () => _onMonthsChanged(_selectedMonths - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_selectedMonths شهر',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: _selectedMonths < 12
                          ? () => _onMonthsChanged(_selectedMonths + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // شرائح الفترات السريعة
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: durations.map((d) {
              final isChosen = _selectedMonths == d.$1;
              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(d.$2),
                    Text(
                      d.$3,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.normal,
                        color: isChosen ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                selected: isChosen,
                selectedColor: const Color(0xFFF59E0B),
                backgroundColor: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                labelStyle: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: isChosen ? FontWeight.w800 : FontWeight.w600,
                  color: isChosen ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
                onSelected: (_) => _onMonthsChanged(d.$1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onMonthsChanged(int months) {
    setState(() {
      _selectedMonths = months;
      // مزامنة باقة مطابقة إن وجدت
      int days = months * 30;
      if (months == 12) days = 365;
      double basePrice = months * 100.0;
      double disc = months >= 12
          ? 0.45
          : (months >= 6 ? 0.40 : (months >= 3 ? 0.38 : 0.0));
      double discPrice = basePrice * (1.0 - disc);

      _selectedPlan = SubscriptionPlan(
        id: 'plan_${months}m',
        name: 'Pro لمدة $months ${months == 1 ? 'شهر' : 'أشهر'}',
        description: 'اشتراك Pro لمدة $days يوماً متواصلاً بدون أي إعلانات مع كافة الاختبارات والامتحانات',
        durationDays: days,
        originalPrice: basePrice,
        discountedPrice: discPrice,
        hasDiscount: disc > 0,
        discountEndsAt: DateTime.now().add(const Duration(days: 30)),
        order: months,
      );
    });
  }

  // بطاقة الباقة المصغرة المدمجة
  Widget _buildPlanCard(SubscriptionPlan plan, bool isDark) {
    final isSelected = _selectedPlan?.id == plan.id;
    final finalPrice = _calculateFinalPrice(plan);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPlan = plan;
          _selectedMonths = (plan.durationDays / 30).round().clamp(1, 12);
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected ? const Color(0xFFF59E0B) : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan.name,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (plan.isPopular) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'الأكثر طلباً',
                      style: GoogleFonts.tajawal(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (plan.hasDiscount && plan.discountPercentage > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'خصم ${plan.discountPercentage}%',
                      style: GoogleFonts.tajawal(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${finalPrice.round()}',
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'أوقية (MRU)',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    if (plan.hasDiscount && plan.originalPrice > plan.discountedPrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${plan.originalPrice.round()}',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${plan.durationDays} يوم',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (plan.hasDiscount && plan.discountEndsAt != null && plan.isDiscountActive) ...[
              const SizedBox(height: 6),
              _DiscountCountdownBadge(endsAt: plan.discountEndsAt!, isDark: isDark),
            ],
          ],
        ),
      ),
    );
  }

  // قسم كود الخصم
  Widget _buildPromoCodeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'هل لديك كود خصم إضافي؟',
            style: GoogleFonts.tajawal(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'مثال: PRO2026',
                    hintStyle: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('تطبيق',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_promoError != null) ...[
            const SizedBox(height: 6),
            Text(
              _promoError!,
              style: GoogleFonts.tajawal(fontSize: 11.5, color: const Color(0xFFDC2626)),
            ),
          ],
          if (_appliedPromo != null) ...[
            const SizedBox(height: 6),
            Text(
              '✓ تم تطبيق الخصم: ${_appliedPromo!.code} (${_appliedPromo!.discountPercent.round()}%)',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // بطاقة طريقة الدفع
  Widget _buildPaymentMethodCard(PaymentMethod method, bool isDark) {
    final isSelected = _selectedMethod?.id == method.id;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? const Color(0xFF0F766E).withValues(alpha: 0.15)
                  : const Color(0xFFF0FDFA))
              : (isDark ? const Color(0xFF16202E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (method.iconAsset != null)
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Image.asset(method.iconAsset!, fit: BoxFit.contain),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: Color(0xFF0D9488)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: GoogleFonts.tajawal(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'رقم التحويل: ${method.accountNumber} (${method.beneficiaryName})',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'نسخ رقم التحويل',
              icon: const Icon(Icons.copy_rounded, size: 20, color: Color(0xFF0D9488)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: method.accountNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم نسخ رقم الحساب: ${method.accountNumber}')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // نموذج إرفاق الوصل
  Widget _buildCheckoutForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات التحويل وإثبات الدفع:',
            style: GoogleFonts.tajawal(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),

          // رقم الهاتف
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'رقم هاتفك للتواصل',
              hintText: 'مثال: 36000000',
              prefixIcon: const Icon(Icons.phone_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // رقم العملية / المرجع
          TextField(
            controller: _refCtrl,
            decoration: InputDecoration(
              labelText: 'رقم العملية أو اسم المرسل (اختياري)',
              hintText: 'رقم الإشعار أو مرجع التحويل',
              prefixIcon: const Icon(Icons.tag_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // زر ومعاينة رفع صورة الوصل
          InkWell(
            onTap: _pickReceipt,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _receiptBytes != null
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: _receiptBytes != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _receiptBytes!,
                            height: 160,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'تم إرفاق إثبات الدفع (انقر للتغيير)',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 42, color: isDark ? Colors.white60 : Colors.grey[500]),
                        const SizedBox(height: 8),
                        Text(
                          'انقر هنا لإرفاق صورة إثبات التحويل / وصل الدفع',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'صورة لقطة شاشة من تطبيق البنك أو رسالة التأكيد',
                          style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ملخص الطلب والمبلغ الإجمالي
          if (_selectedPlan != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الباقة والمدة المحددة:',
                        style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selectedPlan!.name} (${_selectedPlan!.durationDays} يوم)',
                        style: GoogleFonts.tajawal(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المبلغ المطلوب تحويله:',
                        style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_calculateFinalPrice(_selectedPlan!).round()} أوقية (MRU)',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedMethod != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'طريقة وحساب الاستلام:',
                          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${_selectedMethod!.name} (${_selectedMethod!.accountNumber})',
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 16),

          // زر الإرسال النهائي
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'إرسال طلب الاشتراك وتأكيد الدفع',
                          style: GoogleFonts.tajawal(
                            fontSize: 15,
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

  // بانر المشترك الحالي
  Widget _buildActiveSubscriberBanner(bool isDark, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF78350F), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB45309).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ProBadge(fontSize: 12),
              const SizedBox(width: 10),
              Text(
                'حسابك مشترك ونشط',
                style: GoogleFonts.tajawal(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'باقة ${auth.proPlanName} • متبقي: ${auth.proDaysRemaining}',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFEF3C7),
            ),
          ),
          if (auth.proExpiresAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'تاريخ انتهاء الاشتراك: ${DateFormat('dd/MM/yyyy').format(auth.proExpiresAt!)}',
              style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.white70),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'ملاحظة: يمكنك التجديد الآن وسيتم إضافة المدة الجديدة تراكمياً إلى رصيدك المتبقي دون أن تفقد أي يوم!',
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: const Color(0xFFFDE68A),
              height: 1.4,
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
          'يرجى تسجيل الدخول لمتابعة طلباتك',
          style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey),
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
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 54, color: isDark ? Colors.white24 : Colors.grey[400]),
                  const SizedBox(height: 14),
                  Text(
                    'لا توجد طلبات اشتراك سابقة',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'عند إرسال طلب اشتراك سيظهر هنا لمتابعة حالته وتاريخ تفعيله.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16202E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
              Expanded(
                child: Text(
                  req.planName,
                  style: GoogleFonts.tajawal(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'المبلغ: ${req.amount.round()} MRU • عبر ${req.paymentMethodName}',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تاريخ الطلب: $dateStr',
            style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.grey),
          ),
          if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سبب الرفض: ${req.rejectionReason}',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
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

// ─── شارة عداد انتهاء الخصم معزولة ومعاد رسمها داخلياً فقط ──────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_rounded, size: 12, color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
            Text(
              'ينتهي العرض: $days يوم و ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.tajawal(
                fontSize: 10,
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
