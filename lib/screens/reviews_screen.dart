import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/geometric_header_card.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _reviewController = TextEditingController();
  double _currentRating = 5.0;
  bool _isSubmitting = false;
  final Set<String> _expandedReviews = <String>{};

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تسجيل الدخول أولاً',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // By using user.uid as the document ID, we enforce one review per user.
      await _firestore.collection('reviews').doc(user.uid).set({
        'rating': _currentRating,
        'text': _reviewController.text.trim(),
        'userId': user.uid,
        'userName': user.displayName ?? 'مستخدم',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _reviewController.clear();
      setState(() => _currentRating = 5.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إرسال تقييمك بنجاح. شكراً لك!',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء إرسال التقييم.',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAddReviewSheet() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تسجيل الدخول لتقييم التطبيق',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Attempt to load existing review
    _firestore
        .collection('reviews')
        .doc(user.uid)
        .get()
        .then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            _currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
            _reviewController.text = data['text'] as String? ?? '';
          } else {
            _currentRating = 5.0;
            _reviewController.clear();
          }

          _openSheet();
        })
        .catchError((_) {
          _currentRating = 5.0;
          _reviewController.clear();
          _openSheet();
        });
  }

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            return Container(
              padding: EdgeInsets.only(
                bottom: bottomInset + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'شاركنا رأيك في التطبيق',
                      style: GoogleFonts.tajawal(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'رأيك يهمنا ويساعدنا على تطوير منصة تليق بك',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _currentRating = index + 1.0);
                            setState(() => _currentRating = index + 1.0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < _currentRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: index < _currentRating
                                  ? Colors.amber
                                  : Colors.grey.withValues(alpha: 0.4),
                              size: index < _currentRating ? 46 : 40,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // Text field
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      autofocus: false,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'اكتب تجربتك أو اقتراحاتك هنا...',
                        hintStyle: GoogleFonts.tajawal(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      style: GoogleFonts.tajawal(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                await _submitReview();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'حفظ التقييم',
                                style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsHeader(List<QueryDocumentSnapshot> docs, bool isDark) {
    if (docs.isEmpty) return const SizedBox.shrink();

    double totalRating = 0;
    List<int> starCounts = [0, 0, 0, 0, 0]; // 1 to 5 stars

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
      totalRating += rating;
      int r = rating.round().clamp(1, 5);
      starCounts[r - 1]++;
    }

    final avg = totalRating / docs.length;
    final mostCommonStar = starCounts.indexOf(
          starCounts.reduce((a, b) => a > b ? a : b),
        ) +
        1;
    final cardColor = isDark ? const Color(0xFF172A3D) : Colors.white;
    final softColor = isDark ? const Color(0xFF20384D) : const Color(0xFFF4F8FC);
    final logoColor = AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: logoColor.withValues(alpha: isDark ? 0.25 : 0.12)),
        boxShadow: [
          BoxShadow(
            color: logoColor.withValues(alpha: isDark ? 0.08 : 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_rounded, color: logoColor, size: 28),
              const SizedBox(width: 10),
              Text(
                'إحصائيات التقييمات',
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF172B4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;
                final metrics = [
                  _buildMetric(
                    value: avg.toStringAsFixed(1),
                    label: 'متوسط التقييم',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFF6C945),
                    isDark: isDark,
                  ),
                  _buildMetric(
                    value: '${docs.length}',
                    label: 'إجمالي التقييمات',
                    icon: Icons.groups_rounded,
                    color: logoColor,
                    isDark: isDark,
                  ),
                  _buildMetric(
                    value: '$mostCommonStar',
                    label: 'الأكثر تكراراً',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFEF6B73),
                    isDark: isDark,
                    suffix: ' نجوم',
                  ),
                ];
                return compact
                    ? Column(children: metrics)
                    : Row(
                        children: metrics
                            .map((metric) => Expanded(child: metric))
                            .toList(),
                      );
              },
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'توزيع النجوم',
            textAlign: TextAlign.right,
            style: GoogleFonts.tajawal(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF172B4D),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            final starNum = 5 - index;
            final count = starCounts[starNum - 1];
            final percentage = count / docs.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('$starNum', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: logoColor)),
                  ),
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF6C945)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 9,
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFE6EDF1),
                        valueColor: AlwaysStoppedAnimation<Color>(logoColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(width: 26, child: Text('$count', textAlign: TextAlign.end, style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black54))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text('$value$suffix', style: GoogleFonts.outfit(fontSize: 25, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          const SizedBox(height: 3),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildReviewsSkeleton(bool isDark) {
    final shimmer = isDark ? Colors.white10 : const Color(0xFFE8F1EE);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 128,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162D27) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: shimmer),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 180,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        title: Text(
          'التقييمات والمراجعات',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // لا نفرض orderBy على Firestore حتى لا تفشل المستندات القديمة أو ينقص index.
        stream: _firestore
            .collection('reviews')
            .snapshots(includeMetadataChanges: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: textCol.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تعذر تحميل التقييمات.',
                      style: GoogleFonts.tajawal(color: textCol),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.tajawal(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildReviewsSkeleton(isDark);
          }

          final docs = [...?snapshot.data?.docs];
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['createdAt'] is Timestamp)
                ? (aData['createdAt'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = (bData['createdAt'] is Timestamp)
                ? (bData['createdAt'] as Timestamp).toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          return Column(
            children: [
              if (snapshot.data?.metadata.isFromCache == true)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 17,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'عرض البيانات المحفوظة مؤقتاً دون اتصال',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: textCol,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: GeometricHeaderCard(
                        title: 'آراء مجتمع MERAJ3I',
                        subtitle:
                            'تجارب الطلاب تساعدنا على تطوير التطبيق باستمرار.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildStatsHeader(docs, isDark)),
                    if (docs.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star_outline_rounded,
                                size: 80,
                                color: textCol.withValues(alpha: 0.1),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'كن أول من يقيّم التطبيق!',
                                style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  color: textCol.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14, top: 4),
                                child: Text(
                                  'التقييمات الأخيرة',
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                  ),
                                ),
                              );
                            }
                            final reviewIndex = index - 1;
                            final data =
                                docs[reviewIndex].data() as Map<String, dynamic>;
                            final reviewId = docs[reviewIndex].id;
                            final rating =
                                (data['rating'] as num?)?.toDouble() ?? 5.0;
                            final text = data['text'] as String? ?? '';
                            final userName =
                                data['userName'] as String? ?? 'مستخدم';
                            DateTime? date;
                            if (data['createdAt'] != null) {
                              if (data['createdAt'] is Timestamp) {
                                date = (data['createdAt'] as Timestamp)
                                    .toDate();
                              } else if (data['createdAt'] is String) {
                                date = DateTime.tryParse(data['createdAt']);
                              } else if (data['createdAt'] is int) {
                                date = DateTime.fromMillisecondsSinceEpoch(
                                  data['createdAt'],
                                );
                              }
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.05 : 0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                // The green edge is the visual anchor used by the ratings design.
                                border: Border(
                                  left: BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 7,
                                  ),
                                  top: BorderSide(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.14)),
                                  right: BorderSide(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.14)),
                                  bottom: BorderSide(color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.3 : 0.14)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryColor
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          userName.isNotEmpty
                                              ? userName
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                              : 'م',
                                          style: GoogleFonts.tajawal(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: GoogleFonts.tajawal(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: textCol,
                                              ),
                                            ),
                                            if (date != null)
                                              Text(
                                                intl.DateFormat(
                                                  'd MMM yyyy',
                                                  'ar',
                                                ).format(date),
                                                style: GoogleFonts.tajawal(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(5, (starIndex) => Icon(
                                              starIndex < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                              color: starIndex < rating.round() ? const Color(0xFFF6C945) : Colors.grey.shade300,
                                              size: 17,
                                            )),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryColor),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          rating.round().toString(),
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (text.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF7F9FC),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          AnimatedSize(
                                            duration: const Duration(milliseconds: 220),
                                            curve: Curves.easeOut,
                                            child: Text(
                                              text,
                                              maxLines: _expandedReviews.contains(reviewId) ? null : 4,
                                              overflow: _expandedReviews.contains(reviewId) ? TextOverflow.visible : TextOverflow.ellipsis,
                                              textDirection: TextDirection.rtl,
                                              style: GoogleFonts.tajawal(fontSize: 15, color: textCol.withValues(alpha: 0.85), height: 1.6),
                                            ),
                                          ),
                                          if (text.length > 180)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: () => setState(() {
                                                  if (!_expandedReviews.add(reviewId)) _expandedReviews.remove(reviewId);
                                                }),
                                                child: Text(_expandedReviews.contains(reviewId) ? 'عرض أقل' : 'عرض المزيد', style: GoogleFonts.tajawal(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }, childCount: docs.length + 1),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddReviewSheet,
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
              label: Text(
                'أضف تقييمك',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              elevation: 4,
            ),
    );
  }
}
