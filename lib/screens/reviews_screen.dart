import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً', style: TextStyle(fontFamily: 'Tajawal'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestore.collection('reviews').add({
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
          const SnackBar(
            content: Text('تم إرسال تقييمك بنجاح. شكراً لك!', style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إرسال التقييم.', style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAddReviewSheet() {
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text('أضف تقييمك', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < _currentRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () {
                          setSheetState(() => _currentRating = index + 1.0);
                          setState(() => _currentRating = index + 1.0);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'اكتب تجربتك هنا...',
                      hintStyle: GoogleFonts.tajawal(color: isDark ? Colors.white54 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? Colors.black12 : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    style: GoogleFonts.tajawal(color: isDark ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () async {
                        await _submitReview();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('إرسال التقييم', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;

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
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline_rounded, size: 80, color: textCol.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text('لا توجد تقييمات بعد', style: GoogleFonts.tajawal(fontSize: 18, color: textCol.withValues(alpha: 0.5))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
              final text = data['text'] as String? ?? '';
              final userName = data['userName'] as String? ?? 'مستخدم';
              DateTime? date;
              if (data['createdAt'] != null) {
                date = (data['createdAt'] as Timestamp).toDate();
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                          child: Text(userName.substring(0, 1).toUpperCase(), style: GoogleFonts.tajawal(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: textCol)),
                              if (date != null)
                                Text(intl.DateFormat('d MMM yyyy', 'ar').format(date), style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIdx) {
                            return Icon(
                              starIdx < rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                      ],
                    ),
                    if (text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        text,
                        style: GoogleFonts.tajawal(fontSize: 14, color: textCol, height: 1.5),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewSheet,
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
        label: Text('أضف تقييم', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
