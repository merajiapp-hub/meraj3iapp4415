import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../widgets/app_dropdown.dart';

enum ReviewSort { newest, highestRating, lowestRating, withComment, withoutComment }

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final int _limit = 10;
  final List<DocumentSnapshot> _reviews = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final ScrollController _scrollController = ScrollController();
  
  ReviewSort _currentSort = ReviewSort.newest;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  int _chartDays = 30;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchReviews(refresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore) {
          _fetchReviews();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final coll = _firestore.collection('reviews');
      final snapshot = await coll.get();
      final docs = snapshot.docs;
      
      int total = docs.length;
      if (total == 0) {
        setState(() {
          _stats = {
            'total': 0, 'avg': 0.0, 'dist': {5:0, 4:0, 3:0, 2:0, 1:0},
            'positivePercent': 0, 'withComment': 0, 'newReviews': 0, 'chart': <FlSpot>[],
          };
          _isLoadingStats = false;
        });
        return;
      }

      double sum = 0;
      int withComment = 0;
      int positive = 0;
      int newReviews = 0; 
      Map<int, int> dist = {5:0, 4:0, 3:0, 2:0, 1:0};
      
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final chartStartDate = now.subtract(Duration(days: _chartDays));
      
      Map<String, List<double>> chartData = {};

      for (var d in docs) {
        final data = d.data();
        final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
        final text = data['text'] as String? ?? '';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
        
        sum += rating;
        if (text.trim().isNotEmpty) withComment++;
        if (rating >= 4) positive++;
        if (createdAt.isAfter(sevenDaysAgo)) newReviews++;
        
        int rInt = rating.round().clamp(1, 5);
        dist[rInt] = (dist[rInt] ?? 0) + 1;
        
        if (createdAt.isAfter(chartStartDate)) {
          String dayKey = intl.DateFormat('MM-dd').format(createdAt);
          if (!chartData.containsKey(dayKey)) chartData[dayKey] = [];
          chartData[dayKey]!.add(rating);
        }
      }

      List<FlSpot> spots = [];
      if (chartData.isNotEmpty) {
        var sortedKeys = chartData.keys.toList()..sort();
        for (int i = 0; i < sortedKeys.length; i++) {
          final ratings = chartData[sortedKeys[i]]!;
          final dayAvg = ratings.fold(0.0, (a, b) => a + b) / ratings.length;
          spots.add(FlSpot(i.toDouble(), dayAvg));
        }
      }

      setState(() {
        _stats = {
          'total': total,
          'avg': sum / total,
          'dist': dist,
          'positivePercent': (positive / total * 100).round(),
          'withComment': withComment,
          'newReviews': newReviews,
          'chart': spots,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchReviews({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _hasMore = true;
      _lastDoc = null;
      _reviews.clear();
    }
    if (!_hasMore) return;

    setState(() => _isLoading = true);
    
    try {
      Query query = _firestore.collection('reviews');
      
      if (_currentSort == ReviewSort.newest) {
        query = query.orderBy('createdAt', descending: true);
      } else if (_currentSort == ReviewSort.highestRating) {
        query = query.orderBy('rating', descending: true).orderBy('createdAt', descending: true);
      } else if (_currentSort == ReviewSort.lowestRating) {
        query = query.orderBy('rating', descending: false).orderBy('createdAt', descending: true);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }

      query = query.limit(_limit);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }
      
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        
        var newDocs = snapshot.docs;
        if (_searchQuery.isNotEmpty || _currentSort == ReviewSort.withComment || _currentSort == ReviewSort.withoutComment) {
           newDocs = newDocs.where((d) {
             final data = d.data() as Map<String, dynamic>;
             final text = (data['text'] as String? ?? '').toLowerCase();
             final name = (data['userName'] as String? ?? '').toLowerCase();
             
             if (_searchQuery.isNotEmpty && !text.contains(_searchQuery) && !name.contains(_searchQuery)) return false;
             if (_currentSort == ReviewSort.withComment && text.trim().isEmpty) return false;
             if (_currentSort == ReviewSort.withoutComment && text.trim().isNotEmpty) return false;
             
             return true;
           }).toList();
        }
        
        _reviews.addAll(newDocs);
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSortChanged(ReviewSort sort) {
    if (_currentSort == sort) return;
    setState(() => _currentSort = sort);
    _fetchReviews(refresh: true);
  }

  Future<void> _toggleHelpful(String reviewId, List<dynamic> currentHelpful) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isGuest || auth.user == null) {
      AppNotification.show(context, 'يجب تسجيل الدخول للإعجاب', isError: true);
      return;
    }
    
    final uid = auth.user!.uid;
    final isHelpful = currentHelpful.contains(uid);
    
    try {
      setState(() {
        final index = _reviews.indexWhere((d) => d.id == reviewId);
        if (index != -1) {
          // Trigger a refresh after updating to avoid complex DocumentSnapshot mocking
        }
      });

      await _firestore.collection('reviews').doc(reviewId).update({
        'helpfulVotes': isHelpful 
            ? FieldValue.arrayRemove([uid]) 
            : FieldValue.arrayUnion([uid])
      });
      _fetchReviews(refresh: true); 
    } catch (e) {
      debugPrint('Error toggling helpful: $e');
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      if (mounted) {
        AppNotification.show(context, 'تم حذف التقييم بنجاح', isError: false);
      }
      _fetchStats();
      _fetchReviews(refresh: true);
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'حدث خطأ أثناء الحذف', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'آراء المستخدمين',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReviewModal(context, isDark),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.rate_review_rounded, color: Colors.white),
        label: Text(
          'اكتب تقييمك',
          style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingStats 
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildSummaryHeader(isDark)),
                SliverToBoxAdapter(child: _buildStatsGrid(isDark)),
                SliverToBoxAdapter(child: _buildTrendChart(isDark)),
                SliverToBoxAdapter(child: _buildControls(isDark)),
                if (_reviews.isEmpty && !_isLoading)
                  SliverFillRemaining(child: _buildEmpty(isDark, _stats?['total'] == 0))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _reviews.length) {
                            return _isLoading 
                                ? const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()))
                                : const SizedBox.shrink();
                          }
                          final doc = _reviews[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildReviewCard(doc.id, data, isDark, index);
                        },
                        childCount: _reviews.length + (_hasMore ? 1 : 0),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildSummaryHeader(bool isDark) {
    if (_stats == null) return const SizedBox.shrink();
    final avg = _stats!['avg'] as double;
    final total = _stats!['total'] as int;
    final dist = _stats!['dist'] as Map<int, int>;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, height: 1),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < avg.floor() ? Icons.star_rounded : (i < avg ? Icons.star_half_rounded : Icons.star_outline_rounded),
                  color: Colors.amber, size: 20,
                )),
              ),
              const SizedBox(height: 8),
              Text(
                'من أصل $total تقييم',
                style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final percent = total > 0 ? count / total : 0.0;
                final pctText = (percent * 100).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$star', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey[700])),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(star >= 4 ? AppTheme.primaryColor : (star == 3 ? Colors.amber : Colors.redAccent)),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 35,
                        child: Text('$pctText%', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold), textAlign: TextAlign.left),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    if (_stats == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildStatCard('إجمالي التقييمات', '${_stats!['total']}', Icons.group_rounded, isDark),
          _buildStatCard('إيجابية', '${_stats!['positivePercent']}%', Icons.thumb_up_rounded, isDark),
          _buildStatCard('بمراجعة نصية', '${_stats!['withComment']}', Icons.comment_rounded, isDark),
          _buildStatCard('آخر 7 أيام', '+${_stats!['newReviews']}', Icons.fiber_new_rounded, isDark),
          _buildStatCard('متوسط النجوم', (_stats!['avg'] as double).toStringAsFixed(1), Icons.star_rounded, isDark),
          _buildStatCard('رضا عام', _stats!['avg'] >= 4 ? 'ممتاز' : 'جيد', Icons.emoji_emotions_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.8), size: 24),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTrendChart(bool isDark) {
    final spots = _stats?['chart'] as List<FlSpot>? ?? [];
    if (spots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      height: 240,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 20, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'اتجاه التقييمات',
                style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
              SizedBox(
                width: 130,
                child: AppDropdown<int>(
                  label: '',
                  value: _chartDays,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('آخر 7 أيام', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 30, child: Text('آخر 30 يوماً', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 90, child: Text('آخر 3 أشهر', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 180, child: Text('آخر 6 أشهر', overflow: TextOverflow.ellipsis)),
                    DropdownMenuItem(value: 365, child: Text('آخر سنة', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _chartDays = val);
                      _fetchStats(); 
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200], strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 30, interval: 1,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 12)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: spots.isNotEmpty ? spots.last.x : 0,
                minY: 1, maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true, color: AppTheme.primaryColor, barWidth: 3, isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              _searchQuery = v.trim().toLowerCase();
              _fetchReviews(refresh: true);
            },
            decoration: InputDecoration(
              hintText: 'ابحث في التقييمات...',
              hintStyle: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _searchQuery = '';
                        _fetchReviews(refresh: true);
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.tajawal(fontSize: 14),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _sortChip(ReviewSort.newest, 'الأحدث', isDark),
                _sortChip(ReviewSort.highestRating, 'الأعلى', isDark),
                _sortChip(ReviewSort.lowestRating, 'الأقل', isDark),
                _sortChip(ReviewSort.withComment, 'بتعليق', isDark),
                _sortChip(ReviewSort.withoutComment, 'بدون', isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sortChip(ReviewSort sort, String label, bool isDark) {
    final isSelected = _currentSort == sort;
    return GestureDetector(
      onTap: () => _onSortChanged(sort),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white24 : Colors.grey[300]!)),
        ),
        child: Text(label, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[700]))),
      ),
    );
  }

  Widget _buildReviewCard(String docId, Map<String, dynamic> review, bool isDark, int index) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
    final text = review['text'] as String? ?? '';
    final name = review['userName'] as String? ?? 'مستخدم';
    final photoUrl = review['userPhotoUrl'] as String?;
    final date = review['createdAt'] != null ? (review['createdAt'] as Timestamp).toDate() : null;
    final dateStr = date != null ? intl.DateFormat('d MMM yyyy', 'ar').format(date) : '';
    
    final helpfulVotes = List<dynamic>.from(review['helpfulVotes'] ?? []);
    final helpfulCount = helpfulVotes.length;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isHelpful = auth.user != null && helpfulVotes.contains(auth.user!.uid);
    final isOwner = auth.user != null && review['userId'] == auth.user!.uid;

    String badge = '';
    Color badgeColor = Colors.green;
    if (rating == 5) { badge = '⭐ ممتاز'; badgeColor = const Color(0xFF059669); }
    else if (rating == 4) { badge = '👍 جيد جداً'; badgeColor = const Color(0xFF0891B2); }
    else if (rating == 3) { badge = '🙂 جيد'; badgeColor = const Color(0xFFF59E0B); }
    else if (rating == 2) { badge = '⚠️ يحتاج تحسين'; badgeColor = const Color(0xFFEA580C); }
    else { badge = '⛔ ضعيف'; badgeColor = const Color(0xFFDC2626); }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 15 * (1 - value)), child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 16, offset: const Offset(0, 6))],
          border: Border(
            right: BorderSide(color: rating >= 4 ? AppTheme.primaryColor : (rating >= 3 ? Colors.amber : Colors.redAccent), width: 5),
            top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100]!),
            bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100]!),
            left: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[100]!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryColor]),
                    ),
                    child: photoUrl != null
                        ? ClipOval(child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => _buildInitialAvatar(name)))
                        : _buildInitialAvatar(name),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(name, style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(badge, style: GoogleFonts.tajawal(fontSize: 11, color: badgeColor, fontWeight: FontWeight.bold)),
                            ),
                            if (isOwner || auth.isAdmin) ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
                                onSelected: (value) {
                                  if (value == 'delete') _deleteReview(docId);
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'delete', child: Text('حذف التقييم', style: GoogleFonts.tajawal(color: Colors.red))),
                                ],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                return Icon(
                                  i < rating.floor() ? Icons.star_rounded : (i < rating ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                  color: Colors.amber, size: 16,
                                );
                              }),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text('${rating.toInt()}/5', style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber[700], fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            if (dateStr.isNotEmpty)
                              Text(dateStr, style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : AppTheme.primaryColor.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.tajawal(fontSize: 14, height: 1.7, color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => _toggleHelpful(docId, helpfulVotes),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isHelpful ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isHelpful ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isHelpful ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded, size: 14, color: isHelpful ? AppTheme.primaryColor : Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text('مفيد ($helpfulCount)', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: isHelpful ? FontWeight.bold : FontWeight.normal, color: isHelpful ? AppTheme.primaryColor : Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    return Center(child: Text(name.isNotEmpty ? name[0] : 'م', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)));
  }

  Widget _buildEmpty(bool isDark, bool noReviews) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(noReviews ? Icons.rate_review_outlined : Icons.search_off_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(noReviews ? 'لا توجد تقييمات حالياً' : 'لا توجد نتائج', style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(noReviews ? 'كن أول من يشاركنا رأيه!' : 'جرّب البحث بكلمة مختلفة', style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[500])),
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 24),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
                    const SizedBox(height: 20),
                    Text('شارك رأيك في التطبيق', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('تقييمك يساعدنا على التحسين المستمر', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryColor])),
                          child: auth.user?.photoURL != null
                              ? ClipOval(child: Image.network(auth.user!.photoURL!, fit: BoxFit.cover))
                              : Center(child: Text((auth.user?.displayName ?? 'م')[0], style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.user?.displayName ?? 'مستخدم', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text('سيظهر اسمك فقط • بريدك خاص', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(_ratingLabel(currentRating), style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (i) {
                              return GestureDetector(
                                onTap: () => setModalState(() => currentRating = (i + 1).toDouble()),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: i < currentRating ? 1.3 : 1.0, end: i < currentRating ? 1.0 : 0.85),
                                  duration: const Duration(milliseconds: 200),
                                  builder: (ctx, v, child) => Transform.scale(
                                    scale: i < currentRating ? 1.1 : 0.9,
                                    child: Icon(i < currentRating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 42),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: textCtrl,
                        maxLines: 4, minLines: 2,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.tajawal(fontSize: 14),
                        decoration: InputDecoration(hintText: 'اكتب رأيك هنا (اختياري)...', hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]), border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  final newDocRef = await _firestore.collection('reviews').add({
                                    'userId': auth.user!.uid,
                                    'userName': auth.user!.displayName ?? 'مستخدم',
                                    'userPhotoUrl': auth.user!.photoURL,
                                    'rating': currentRating,
                                    'text': textCtrl.text.trim(),
                                    'createdAt': Timestamp.now(), // استخدمنا التوقيت المحلي لكي يظهر فوراً
                                    'helpfulVotes': [],
                                  });
                                  
                                  // جلب المستند الجديد لإضافته محلياً
                                  final newDocSnap = await newDocRef.get();

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    AppNotification.show(context, 'شكراً لتقييمك!');
                                    
                                    // تحديث الواجهة فوراً
                                    setState(() {
                                      _reviews.insert(0, newDocSnap);
                                    });
                                    _fetchStats();
                                  }
                                } catch (e) {
                                  if (context.mounted) AppNotification.show(context, 'حدث خطأ، حاول مرة أخرى', isError: true);
                                } finally {
                                  if (context.mounted) setModalState(() => isSubmitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text('إرسال التقييم', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _ratingLabel(double rating) {
    if (rating == 5) return 'ممتاز جداً 🤩';
    if (rating == 4) return 'جيد جداً 👍';
    if (rating == 3) return 'جيد 🙂';
    if (rating == 2) return 'يحتاج تحسين ⚠️';
    return 'ضعيف ⛔';
  }
}
