import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../providers/statistics_provider.dart';
import '../widgets/geometric_sliver_app_bar.dart';
import '../data/ad_manager.dart';

// ══════════════════════════════════════════
//  نموذج بيانات لاعب (قابل للتمرير)
// ══════════════════════════════════════════
class _LeaderboardEntry {
  final String uid;
  String name;
  final int points;
  final int verifiedExamCount;
  final int verifiedCorrectAnswers;
  final String? profileImageUrl;
  final double avgScore;

  _LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.points,
    required this.verifiedExamCount,
    required this.verifiedCorrectAnswers,
    this.profileImageUrl,
    this.avgScore = 0,
  });

  factory _LeaderboardEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return _LeaderboardEntry(
      uid: doc.id,
      name: (d['name'] ?? 'طالب مميز').toString(),
      points: (d['points'] ?? 0).toInt(),
      verifiedExamCount: (d['verifiedExamCount'] ?? 0).toInt(),
      verifiedCorrectAnswers: (d['verifiedCorrectAnswers'] ?? 0).toInt(),
      profileImageUrl: d['profileImageUrl'],
      avgScore: (d['avgScore'] ?? 0.0).toDouble(),
    );
  }

  String get levelTitle {
    if (points >= 2000) return 'متفوق MERAJ3I 🏆';
    if (points >= 1000) return 'متميز ⭐';
    if (points >= 500) return 'طالب متقدم 📈';
    if (points >= 200) return 'مجتهد 💪';
    if (points >= 50) return 'مثابر ✨';
    return 'مبتدئ 🌱';
  }

  Color get levelColor {
    if (points >= 2000) return const Color(0xFFFBBF24);
    if (points >= 1000) return const Color(0xFF8B5CF6);
    if (points >= 500) return const Color(0xFF14A085);
    if (points >= 200) return const Color(0xFF0EA5E9);
    if (points >= 50) return const Color(0xFF10B981);
    return const Color(0xFF94A3B8);
  }
}

// ══════════════════════════════════════════
//  الصفحة الرئيسية للتنافس
// ══════════════════════════════════════════
class StudentCompetitionScreen extends StatefulWidget {
  const StudentCompetitionScreen({super.key});

  @override
  State<StudentCompetitionScreen> createState() =>
      _StudentCompetitionScreenState();
}

class _StudentCompetitionScreenState extends State<StudentCompetitionScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late AnimationController _animController;

  // ─── بيانات محملة ───────────────────────
  List<_LeaderboardEntry> _leaderboard = [];
  _LeaderboardEntry? _myEntry;
  int _myRank = 0;
  bool _isLoading = true;
  final bool _rankingUnavailable = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLeaderboard());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── تحميل الترتيب مع تحسين الأداء ────────
  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    if (_rankingUnavailable) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final currentUserId = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).user?.uid;

      if (currentUserId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMsg =
              'يرجى تسجيل الدخول بحسابك لعرض لوحة الشرف والتنافس مع زملائك.';
        });
        return;
      }

      final snap = await _firestore
          .collection('honor_board')
          .orderBy('points', descending: true)
          .limit(100)
          .get();

      final entries = snap.docs
          .map(_LeaderboardEntry.fromDoc)
          .where((entry) => entry.points > 0)
          .toList();

      int myRank = 0;
      _LeaderboardEntry? myEntry;
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].uid == currentUserId) {
          myRank = i + 1;
          myEntry = entries[i];
          break;
        }
      }

      if (myEntry == null) {
        final myDoc = await _firestore
            .collection('honor_board')
            .doc(currentUserId)
            .get();
        if (myDoc.exists) {
          myEntry = _LeaderboardEntry.fromDoc(myDoc);
          if (myEntry.points > 0) {
            final countSnap = await _firestore
                .collection('honor_board')
                .where('points', isGreaterThan: myEntry.points)
                .count()
                .get();
            myRank = (countSnap.count ?? 0) + 1;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _leaderboard = entries;
        _myEntry = myEntry;
        _myRank = myRank;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = error.code == 'permission-denied'
            ? 'صلاحيات قراءة لوحة الشرف غير متاحة. يرجى تحديث قواعد البيانات.'
            : error.code == 'failed-precondition'
            ? 'يتطلب الاستعلام بناء فهرس (Index) في Firebase.'
            : 'تعذر تحميل الترتيب حالياً: ${error.message}';
      });
      debugPrint(
        'Leaderboard FirebaseException: ${error.code} - ${error.message}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'حدث خطأ غير متوقع أثناء تحميل الترتيب.';
      });
      debugPrint('Leaderboard error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).user?.uid;
    final studentProfile = Provider.of<StudentProvider>(
      context,
      listen: false,
    ).profile;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── Header ──────────────────────────────────────
            const GeometricSliverAppBar(
              title: 'لوحة الشرف',
              icon: Icons.emoji_events_rounded,
              gradient: AppTheme.brandGradient,
            ),

            // تمت إزالة التبويبات (الأسبوع/الشهر) لعدم توفر بيانات تاريخية دقيقة لحساب النقاط المكتسبة أسبوعياً

            // ─── بطاقة إحصائياتي ─────────────────────────────
            if (!_rankingUnavailable && currentUserId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _buildMyStatsCard(isDark, studentProfile),
                ),
              ),

            // ─── بطاقة كسب النقاط بمشاهدة إعلان مكافأة ─────────
            if (currentUserId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: _buildRewardAdCard(isDark),
                ),
              ),

            // ─── المحتوى ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : _rankingUnavailable
                  ? _buildUnavailableWidget(isDark)
                  : _errorMsg != null
                  ? _buildErrorWidget()
                  : _leaderboard.isEmpty
                  ? _buildEmptyWidget(isDark)
                  : _buildLeaderboardContent(isDark, currentUserId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 80),
      child: Column(
        children: [
          Icon(
            Icons.lock_clock_rounded,
            color: AppTheme.primaryColor,
            size: 54,
          ),
          const SizedBox(height: 16),
          Text(
            'لوحة الشرف متوقفة مؤقتًا',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'على خطة Firebase المجانية (Spark)، لا يتوفر خادم موثوق لاحتساب النقاط. أوقفنا الترتيب بدل عرض نقاط يمكن تعديلها من التطبيق. ستعود اللوحة عند توفير احتساب خادمي موثوق.',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeLeaderboardName(
    String? sourceName, {
    String fallback = 'طالب متميز',
  }) {
    final cleaned = (sourceName ?? '').trim();
    if (cleaned.isEmpty) return fallback;

    final lower = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    final placeholderNames = {
      'طالب',
      'طالب متميز',
      'طالب متميز ',
      'طالب مميز',
      'student',
      'user',
      'مستخدم',
    };

    if (placeholderNames.contains(lower)) {
      return fallback;
    }

    return cleaned;
  }

  String _buildStudentNameDisplay(
    String? sourceName, {
    String fallback = 'طالب متميز',
  }) {
    final resolved = _normalizeLeaderboardName(sourceName, fallback: fallback);
    if (resolved == 'طالب متميز' && fallback != 'طالب متميز') {
      return fallback;
    }
    return resolved;
  }

  // ── بطاقة كسب النقاط بمشاهدة إعلان مكافأة ──────────────────────────────
  Widget _buildRewardAdCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AdManager.showRewardedAdWithLoader(
              context,
              onRewarded: () async {
                final stats = context.read<StatisticsProvider>();
                await stats.incrementUserStat('points', value: 5);

                final studentProvider = context.read<StudentProvider>();
                await studentProvider.addPoints(5);

                final authUser = context.read<AuthProvider>().user;
                if (authUser != null) {
                  try {
                    final profile = studentProvider.profile;
                    final studentName = profile.name.trim().isNotEmpty
                        ? profile.name.trim()
                        : (authUser.displayName ?? 'طالب متميز');
                    await FirebaseFirestore.instance
                        .collection('honor_board')
                        .doc(authUser.uid)
                        .set({
                          'name': studentName,
                          'points': FieldValue.increment(5),
                          'profileImageUrl': profile.avatarPath ?? authUser.photoURL,
                          'lastActive': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));
                  } catch (e) {
                    debugPrint('Error updating honor_board from rewarded ad: $e');
                  }
                }

                if (mounted) {
                  _loadLeaderboard();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '🎉 مبروك! حصلت على 5 نقاط إضافية لدعمك التطبيق.',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppTheme.primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppTheme.secondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اكسب 5 نقاط إضافية! 🎁',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'شاهد إعلاناً قصيراً لزيادة نقاطك في لوحة الشرف',
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'مشاهدة (+5)',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── بطاقة "إحصائياتي" ─────────────────────────────────────────────────
  Widget _buildMyStatsCard(bool isDark, dynamic profile) {
    final myE = _myEntry;
    final stats = context.watch<StatisticsProvider>();
    final displayName = _buildStudentNameDisplay(
      myE?.name ?? profile.name,
      fallback: _normalizeLeaderboardName(profile.name, fallback: 'طالب متميز'),
    );

    final displayPoints = (myE != null && myE.points > 0)
        ? myE.points
        : (profile.points > 0
              ? profile.points
              : (stats.userCorrectAnswers * 10));
    final displayExams = (myE != null && myE.verifiedExamCount > 0)
        ? myE.verifiedExamCount
        : stats.userTestsTaken;
    final displayCorrect = (myE != null && myE.verifiedCorrectAnswers > 0)
        ? myE.verifiedCorrectAnswers
        : stats.userCorrectAnswers;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Opacity(
        opacity: Curves.easeIn.transform(_animController.value.clamp(0, 1)),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // صورة المستخدم المدمجة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: myE?.profileImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: myE!.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (ctx, err, stk) =>
                                _defaultAvatar(profile.name, Colors.white),
                          )
                        : _defaultAvatar(profile.name, Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          myE?.levelTitle ?? 'مبتدئ 🌱',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // الترتيب
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_myRank > 0 ? _myRank : '—'}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'ترتيبي',
                        style: GoogleFonts.tajawal(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMyStatChip(
                  Icons.star_rounded,
                  '$displayPoints',
                  'نقطة',
                ),
                _buildMyStatChip(Icons.quiz_rounded, '$displayExams', 'اختبار'),
                _buildMyStatChip(
                  Icons.check_circle_rounded,
                  '$displayCorrect',
                  'إجابة صحيحة',
                ),
              ],
            ),
            if (_myRank > 1 && _leaderboard.length > 1) ...[
              const SizedBox(height: 8),
              _buildMotivationBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyStatChip(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildMotivationBanner() {
    final aboveMe = _myRank > 1 ? _leaderboard[_myRank - 2] : null;
    if (aboveMe == null) return const SizedBox.shrink();
    final myPoints = _myEntry?.points ?? 0;
    final diff = aboveMe.points - myPoints;
    String msg = diff > 0
        ? 'أنت على بعد $diff نقطة من المركز ${_myRank - 1} 🔥'
        : 'أنت على وشك تخطي المركز ${_myRank - 1}!';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        msg,
        style: GoogleFonts.tajawal(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── محتوى لوحة الترتيب ────────────────────────────────────────────────
  Widget _buildLeaderboardContent(bool isDark, String? currentUserId) {
    final top3 = _leaderboard.take(3).toList();
    final rest = _leaderboard.skip(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── المراكز الثلاثة الأولى (المنصة) ──────────────
        if (top3.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFFBBF24),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'منصة الأوائل',
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildPodium(top3, isDark, currentUserId),
        ],

        // ─── قائمة الترتيب العام ────────────────────────────
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Text(
              'الترتيب العام (${_leaderboard.length})',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          ...rest.asMap().entries.map((entry) {
            final rank = entry.key + 4;
            final e = entry.value;
            final isMe = e.uid == currentUserId;
            return _buildRankCard(e, rank, isMe, isDark);
          }),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  // ── المنصة المدمجة والمحترفة (Podium) ───────────────────────────────────
  Widget _buildPodium(
    List<_LeaderboardEntry> top,
    bool isDark,
    String? currentUserId,
  ) {
    const goldColor = Color(0xFFFBBF24);
    const silverColor = Color(0xFF94A3B8);
    const bronzeColor = Color(0xFFCD7F32);

    // ترتيب المنصة: 2 - 1 - 3
    final List<_LeaderboardEntry?> ordered = [
      top.length > 1 ? top[1] : null,
      top.isNotEmpty ? top[0] : null,
      top.length > 2 ? top[2] : null,
    ];
    final List<int> ranks = [2, 1, 3];
    final List<Color> colors = [silverColor, goldColor, bronzeColor];
    final List<double> heights = [58, 86, 46];

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          24 * (1 - Curves.easeOutQuart.transform(_animController.value)),
        ),
        child: Opacity(
          opacity: Curves.easeIn.transform(_animController.value.clamp(0, 1)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final entry = ordered[i];
            if (entry == null) return const SizedBox(width: 60);
            final isMe = entry.uid == currentUserId;
            return Expanded(
              child: _buildPodiumItem(
                entry: entry,
                rank: ranks[i],
                podiumHeight: heights[i],
                color: colors[i],
                isDark: isDark,
                isMe: isMe,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPodiumItem({
    required _LeaderboardEntry entry,
    required int rank,
    required double podiumHeight,
    required Color color,
    required bool isDark,
    required bool isMe,
  }) {
    final avatarSize = rank == 1 ? 48.0 : 38.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFBBF24),
              size: 22,
            ),
          ),
        // صورة المستخدم
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe ? AppTheme.primaryColor : color,
              width: isMe ? 2.5 : 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: entry.profileImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: entry.profileImageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (ctx, err, stk) =>
                        _defaultAvatar(entry.name, color),
                  )
                : _defaultAvatar(entry.name, color),
          ),
        ),
        const SizedBox(height: 4),
        // الاسم
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            isMe
                ? 'أنت'
                : _buildStudentNameDisplay(
                    entry.name,
                    fallback: 'طالب متميز',
                  ).split(RegExp(r'\s+')).first,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 12.5 : 11,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // النقاط
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.points} ن',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 5),
        // قاعدة المنصة
        Container(
          width: double.infinity,
          height: podiumHeight,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: GoogleFonts.outfit(
                  fontSize: rank == 1 ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
              if (rank == 1) ...[
                Text(
                  '${entry.verifiedExamCount} اختبار',
                  style: GoogleFonts.cairo(
                    fontSize: 9,
                    color: color.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── كرت الترتيب العام المدمج والأنيق ─────────────────────────────────
  Widget _buildRankCard(_LeaderboardEntry e, int rank, bool isMe, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : (isDark ? AppTheme.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppTheme.primaryColor.withValues(alpha: 0.6)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: isMe ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // رقم الترتيب
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isMe
                      ? AppTheme.primaryColor
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // صورة المستخدم
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isMe
                      ? AppTheme.primaryColor
                      : e.levelColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: ClipOval(
                child: e.profileImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: e.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (ctx, err, stk) =>
                            _defaultAvatar(e.name, e.levelColor),
                      )
                    : _defaultAvatar(e.name, e.levelColor),
              ),
            ),
            const SizedBox(width: 10),
            // الاسم والمستوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMe
                        ? 'أنت (${_buildStudentNameDisplay(e.name, fallback: 'طالب متميز')})'
                        : _buildStudentNameDisplay(
                            e.name,
                            fallback: 'طالب متميز',
                          ),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: isMe
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    e.levelTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: e.levelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // النقاط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isMe ? AppTheme.primaryColor : e.levelColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${e.points}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isMe ? AppTheme.primaryColor : e.levelColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'ن',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMe ? AppTheme.primaryColor : e.levelColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── حالة الخطأ ──────────────────────────────────────────────────────
  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _errorMsg ?? 'حدث خطأ غير متوقع.',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadLeaderboard,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'إعادة المحاولة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── حالة القائمة الفارغة ────────────────────────────────────────────
  Widget _buildEmptyWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج محتسبة في لوحة الشرف بعد.\nأكمل اختباراً منشوراً لتظهر نقاطك بعد إعادة تصحيح الإجابات على الخادم.',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ── الصورة الافتراضية ────────────────────────────────────────────────
  Widget _defaultAvatar(String name, Color color) {
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: color,
          ),
        ),
      ),
    );
  }
}
