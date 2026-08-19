import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('آراء المستخدمين', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ أثناء جلب التقييمات', style: GoogleFonts.tajawal()));
          }

          final reviews = snapshot.data?.docs ?? [];
          
          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reviews_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('لا توجد تقييمات حالياً', style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('كن أول من يشاركنا رأيه!', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index].data() as Map<String, dynamic>;
              return _buildReviewCard(review, isDark);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewModal(context, isDark),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text('أضف رأيك', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isDark) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
    final text = review['text'] as String? ?? '';
    final name = review['userName'] as String? ?? 'مستخدم غير معروف';
    final date = review['createdAt'] != null 
        ? (review['createdAt'] as Timestamp).toDate()
        : null;
    final dateStr = date != null ? intl.DateFormat('yyyy/MM/dd').format(date) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0] : 'م',
                  style: GoogleFonts.tajawal(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(dateStr, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.tajawal(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddReviewModal(BuildContext context, bool isDark) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (auth.isGuest || auth.user == null) {
      AppNotification.show(context, 'يجب تسجيل الدخول لإضافة تقييم', isError: true);
      return;
    }

    final nameCtrl = TextEditingController(text: auth.user?.displayName ?? '');
    final textCtrl = TextEditingController();
    double currentRating = 5.0;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.backgroundDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أضف تقييمك', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    // النجوم
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setModalState(() {
                              currentRating = (index + 1).toDouble();
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب رأيك هنا...',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                        filled: true,
                        fillColor: isDark ? AppTheme.surfaceDark : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                        ),
                      ),
                      style: GoogleFonts.tajawal(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting ? null : () async {
                          if (textCtrl.text.trim().isEmpty) {
                            AppNotification.show(ctx, 'يرجى كتابة رأيك أولاً', isError: true);
                            return;
                          }
                          setModalState(() => isSubmitting = true);
                          try {
                            await _firestore.collection('reviews').add({
                              'userId': auth.user!.uid,
                              'userName': nameCtrl.text.trim(),
                              'userEmail': auth.user!.email, // للإدارة فقط ولن يعرض
                              'text': textCtrl.text.trim(),
                              'rating': currentRating,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              AppNotification.show(context, 'شكراً لمشاركتك رأيك!');
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              AppNotification.show(ctx, 'حدث خطأ، يرجى المحاولة لاحقاً', isError: true);
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('حفظ التقييم', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }
}
