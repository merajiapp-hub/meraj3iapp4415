import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int _selectedStars = 0;
  String _sort = 'newest';

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtered(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final filtered = docs.where((doc) {
      final data = doc.data();
      final name = (data['userName'] ?? '').toString().toLowerCase();
      final email = (data['userEmail'] ?? data['email'] ?? '').toString().toLowerCase();
      final uid = (data['uid'] ?? doc.id).toString().toLowerCase();
      final phone = (data['userPhone'] ?? data['phone'] ?? '').toString().toLowerCase();
      final search = _query.toLowerCase();
      final ratingMatches = _selectedStars == 0 || ((data['rating'] ?? 0) as num).round() == _selectedStars;
      return ratingMatches &&
          (search.isEmpty ||
              name.contains(search) ||
              email.contains(search) ||
              uid.contains(search) ||
              phone.contains(search));
    }).toList();

    filtered.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aTime = (aData['createdAt'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0;
      final bTime = (bData['createdAt'] as Timestamp?)?.toDate().millisecondsSinceEpoch ?? 0;
      final aRating = ((aData['rating'] ?? 0) as num).toDouble();
      final bRating = ((bData['rating'] ?? 0) as num).toDouble();
      switch (_sort) {
        case 'highest':
          return bRating.compareTo(aRating);
        case 'lowest':
          return aRating.compareTo(bRating);
        case 'newest':
        default:
          return bTime.compareTo(aTime);
      }
    });

    return filtered;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildStatsHeader(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, bool isDark) {
    if (docs.isEmpty) return const SizedBox.shrink();

    double totalRating = 0;
    List<int> starCounts = [0, 0, 0, 0, 0];

    for (var doc in docs) {
      final data = doc.data();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        title: Text(
          'إدارة التقييمات',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('reviews').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}', style: GoogleFonts.tajawal(color: Colors.red)));
          }

          final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final filtered = _filtered(docs);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.tajawal(color: textCol),
                        decoration: InputDecoration(
                          hintText: 'بحث بالاسم / البريد / UID / الهاتف',
                          hintStyle: GoogleFonts.tajawal(color: isDark ? Colors.white54 : Colors.black54),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          suffixIcon: _query.isNotEmpty ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          ) : null,
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('الكل', 0, isDark),
                            ...List.generate(5, (index) => index + 1).map((star) => _buildFilterChip('$star نجوم', star, isDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _sort,
                        dropdownColor: surface,
                        style: GoogleFonts.tajawal(color: textCol, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: [
                          DropdownMenuItem(value: 'newest', child: Text('الأحدث', style: GoogleFonts.tajawal())),
                          DropdownMenuItem(value: 'highest', child: Text('الأعلى', style: GoogleFonts.tajawal())),
                          DropdownMenuItem(value: 'lowest', child: Text('الأقل', style: GoogleFonts.tajawal())),
                        ],
                        onChanged: (value) => setState(() => _sort = value ?? 'newest'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildStatsHeader(filtered, isDark),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'لا توجد تقييمات مطابقة',
                      style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 18),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = filtered[index];
                        final data = doc.data();
                        final rating = ((data['rating'] ?? 0) as num).toDouble();
                        final userName = (data['userName'] ?? 'مستخدم').toString();
                        final email = (data['userEmail'] ?? data['email'] ?? '').toString();
                        final phone = (data['userPhone'] ?? data['phone'] ?? '').toString();
                        final uid = (data['uid'] ?? doc.id).toString();
                        final comment = (data['text'] ?? '').toString();
                        final timestamp = (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();

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
                            border: Border(
                              left: const BorderSide(
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
                                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                    child: Text(
                                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'م',
                                      style: GoogleFonts.tajawal(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: GoogleFonts.tajawal(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textCol,
                                          ),
                                        ),
                                        Text(
                                          email.isNotEmpty ? email : 'بدون بريد',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 12,
                                            color: isDark ? Colors.white54 : Colors.black54,
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
                                          size: 18,
                                        )),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFF6C945),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                  ),
                                  child: Text(
                                    comment,
                                    style: GoogleFonts.tajawal(
                                      color: textCol,
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _metaChip('UID', uid, isDark),
                                  if (phone.isNotEmpty) _metaChip('الهاتف', phone, isDark),
                                  _metaChip('التاريخ', intl.DateFormat('dd/MM/yyyy', 'ar').format(timestamp), isDark),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _copyAction(
                                      icon: Icons.fingerprint,
                                      label: 'نسخ UID',
                                      onTap: () => _copyToClipboard('UID', uid),
                                      isDark: isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _copyAction(
                                      icon: Icons.email_outlined,
                                      label: 'نسخ البريد',
                                      onTap: () => _copyToClipboard('البريد', email),
                                      isDark: isDark,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Expanded(
                                      child: _copyAction(
                                        icon: Icons.phone_outlined,
                                        label: 'نسخ الهاتف',
                                        onTap: () => _copyToClipboard('الهاتف', phone),
                                        isDark: isDark,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _copyToClipboard(String label, String value) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم نسخ $label بنجاح',
          style: GoogleFonts.tajawal(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _copyAction({required IconData icon, required String label, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int stars, bool isDark) {
    final selected = _selectedStars == stars;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.tajawal(
          color: selected ? AppTheme.primaryColor : (isDark ? Colors.white60 : Colors.black54),
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        onSelected: (_) => setState(() => _selectedStars = stars),
      ),
    );
  }

  Widget _metaChip(String title, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$title: $value',
        style: GoogleFonts.tajawal(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }
}
