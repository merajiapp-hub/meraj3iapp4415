import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

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
          content: Text('يرجى تسجيل الدخول أولاً', style: GoogleFonts.tajawal()),
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
            content: Text('تم إرسال تقييمك بنجاح. شكراً لك!', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إرسال التقييم.', style: GoogleFonts.tajawal()),
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
          content: Text('يرجى تسجيل الدخول لتقييم التطبيق', style: GoogleFonts.tajawal()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Attempt to load existing review
    _firestore.collection('reviews').doc(user.uid).get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _currentRating = (data['rating'] as num?)?.toDouble() ?? 5.0;
        _reviewController.text = data['text'] as String? ?? '';
      } else {
        _currentRating = 5.0;
        _reviewController.clear();
      }
      
      _openSheet();
    }).catchError((_) {
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
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('شاركنا رأيك في التطبيق', style: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 8),
                  Text('رأيك يهمنا ويساعدنا على تطوير منصة تليق بك', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
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
                            index < _currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: index < _currentRating ? Colors.amber : Colors.grey.withValues(alpha: 0.4),
                            size: index < _currentRating ? 46 : 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'اكتب تجربتك أو اقتراحاتك هنا...',
                      hintStyle: GoogleFonts.tajawal(color: isDark ? Colors.white54 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    style: GoogleFonts.tajawal(color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        await _submitReview();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('حفظ التقييم', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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

    double avg = totalRating / docs.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Average Section
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) => Icon(
                  index < avg.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 16,
                )),
              ),
              const SizedBox(height: 8),
              Text(
                'من ${docs.length} تقييم',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Progress Bars Section
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final starNum = 5 - index; // 5, 4, 3, 2, 1
                final count = starCounts[starNum - 1];
                final percentage = count / docs.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('$starNum', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
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
        title: Text('التقييمات والمراجعات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: textCol)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ ما', style: GoogleFonts.tajawal(color: textCol)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildStatsHeader(docs, isDark),
              ),
              if (docs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline_rounded, size: 80, color: textCol.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text('كن أول من يقيّم التطبيق!', style: GoogleFonts.tajawal(fontSize: 18, color: textCol.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
                        final text = data['text'] as String? ?? '';
                        final userName = data['userName'] as String? ?? 'مستخدم';
                        DateTime? date;
                        if (data['createdAt'] != null) {
                          if (data['createdAt'] is Timestamp) {
                            date = (data['createdAt'] as Timestamp).toDate();
                          } else if (data['createdAt'] is String) {
                            date = DateTime.tryParse(data['createdAt']);
                          } else if (data['createdAt'] is int) {
                            date = DateTime.fromMillisecondsSinceEpoch(data['createdAt']);
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                    child: Text(
                                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'م',
                                      style: GoogleFonts.tajawal(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(userName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: textCol)),
                                        if (date != null)
                                          Text(intl.DateFormat('d MMM yyyy', 'ar').format(date), style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(rating.toStringAsFixed(1), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade700)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (text.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  text,
                                  style: GoogleFonts.tajawal(fontSize: 15, color: textCol.withValues(alpha: 0.85), height: 1.6),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: isGuest ? null : FloatingActionButton.extended(
        onPressed: _showAddReviewSheet,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
        label: Text('أضف تقييمك', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 4,
      ),
    );
  }
}
