import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../widgets/geometric_sliver_app_bar.dart';

// ══════════════════════════════════════════
//  نموذج بيانات لاعب (قابل للتمرير)
// ══════════════════════════════════════════
class _LeaderboardEntry {
  final String uid;
  final String name;
  final int points;
  final int booksRead;
  final int quizzesTaken;
  final int completedTasks;
  final double progressLevel;
  final String? profileImageUrl;
  final int streakDays;
  final double avgScore;

  const _LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.points,
    required this.booksRead,
    required this.quizzesTaken,
    required this.completedTasks,
    required this.progressLevel,
    this.profileImageUrl,
    this.streakDays = 0,
    this.avgScore = 0,
  });

  factory _LeaderboardEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return _LeaderboardEntry(
      uid: doc.id,
      name: d['name'] ?? 'طالب',
      points: (d['points'] ?? 0).toInt(),
      booksRead: (d['booksRead'] ?? 0).toInt(),
      quizzesTaken: (d['quizzesTaken'] ?? 0).toInt(),
      completedTasks: (d['completedTasks'] ?? 0).toInt(),
      progressLevel: (d['progressLevel'] ?? 0.0).toDouble(),
      profileImageUrl: d['profileImageUrl'],
      streakDays: (d['streakDays'] ?? 0).toInt(),
      avgScore: (d['avgScore'] ?? 0.0).toDouble(),
    );
  }

  String get levelTitle {
    if (points >= 2000) return 'بطل MERAJ3I 🏆';
    if (points >= 1000) return 'متفوق ⭐';
    if (points >= 500) return 'طالب متقدم 📈';
    if (points >= 200) return 'قارئ نشيط 📚';
    if (points >= 50) return 'مجتهد 💪';
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
  State<StudentCompetitionScreen> createState() => _StudentCompetitionScreenState();
}

class _StudentCompetitionScreenState extends State<StudentCompetitionScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  late AnimationController _animController;

  // ─── بيانات محملة ───────────────────────
  List<_LeaderboardEntry> _leaderboard = [];
  _LeaderboardEntry? _myEntry;
  int _myRank = 0;
  bool _isLoading = true;
  String? _errorMsg;
  Timer? _refreshTimer;

  // التبويب: 0 = الأسبوع, 1 = الشهر, 2 = كل الوقت
  int _selectedPeriod = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedPeriod = _tabController.index);
        _loadLeaderboard();
      }
    });
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLeaderboard());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ─── تحميل الترتيب مع تحسين الأداء ────────
  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final currentUserId =
          Provider.of<AuthProvider>(context, listen: false).user?.uid;

      // تحديد نطاق التاريخ حسب الفترة
      DateTime? since;
      if (_selectedPeriod == 0) {
        since = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedPeriod == 1) {
        since = DateTime.now().subtract(const Duration(days: 30));
      }

      Query query = _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(100);

      if (since != null) {
        query = query.where('lastActivity',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since));
      }

      final snap = await query.get();
      final entries = snap.docs
          .map((d) => _LeaderboardEntry.fromDoc(d))
          .where((e) => e.points > 0 || e.booksRead > 0)
          .toList();

      // حساب ترتيب المستخدم الحالي
      int myRank = 0;
      _LeaderboardEntry? myEntry;
      for (int i = 0; i < entries.length; i++) {
        if (entries[i].uid == currentUserId) {
          myRank = i + 1;
          myEntry = entries[i];
          break;
        }
      }

      // إذا لم يُجد المستخدم ضمن أفضل 100 — جلب بياناته منفرداً
      if (myEntry == null && currentUserId != null) {
        final myDoc =
            await _firestore.collection('users').doc(currentUserId).get();
        if (myDoc.exists) {
          myEntry = _LeaderboardEntry.fromDoc(myDoc);
          // تقدير الترتيب
          final countSnap = await _firestore
              .collection('users')
              .where('points', isGreaterThan: myEntry.points)
              .count()
              .get();
          myRank = (countSnap.count ?? 0) + 1;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'تعذر تحميل الترتيب. تحقق من اتصالك بالإنترنت.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.uid;
    final studentProfile =
        Provider.of<StudentProvider>(context, listen: false).profile;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
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

            // ─── تبويبات الفترة ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.surfaceDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        isDark ? Colors.white60 : Colors.black54,
                    labelStyle: GoogleFonts.tajawal(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle:
                        GoogleFonts.tajawal(fontSize: 13),
                    tabs: const [
                      Tab(text: 'هذا الأسبوع'),
                      Tab(text: 'هذا الشهر'),
                      Tab(text: 'كل الوقت'),
                    ],
                  ),
                ),
              ),
            ),

            // ─── بطاقة إحصائياتي ─────────────────────────────
            if (currentUserId != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildMyStatsCard(
                      isDark, studentProfile, currentUserId),
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
                  : _errorMsg != null
                      ? _buildErrorWidget()
                      : _leaderboard.isEmpty
                          ? _buildEmptyWidget(isDark)
                          : _buildLeaderboardContent(
                              isDark, currentUserId),
            ),
          ],
        ),
      ),
    );
  }

  // ── بطاقة "إحصائياتي" ─────────────────────────────────────────────────
  Widget _buildMyStatsCard(
      bool isDark, dynamic profile, String currentUserId) {
    final myE = _myEntry;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Opacity(
        opacity: Curves.easeIn.transform(_animController.value.clamp(0, 1)),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // صورة المستخدم
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          myE?.levelTitle ?? 'مبتدئ 🌱',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // الترتيب
                Column(
                  children: [
                    Text(
                      '#${_myRank > 0 ? _myRank : '—'}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'ترتيبي',
                      style: GoogleFonts.tajawal(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMyStatChip(
                    Icons.star_rounded,
                    '${myE?.points ?? profile.points}',
                    'نقطة'),
                _buildMyStatChip(
                    Icons.menu_book_rounded,
                    '${myE?.booksRead ?? profile.booksRead}',
                    'كتاب'),
                _buildMyStatChip(
                    Icons.task_alt_rounded,
                    '${myE?.completedTasks ?? profile.completedTasks}',
                    'مهمة'),
                _buildMyStatChip(
                    Icons.quiz_rounded,
                    '${myE?.quizzesTaken ?? profile.quizzesTaken}',
                    'اختبار'),
              ],
            ),
            // ─── رسالة تحفيزية ──────────────────────────────
            if (_myRank > 1 && _leaderboard.length > 1) ...[
              const SizedBox(height: 14),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'المراكز الثلاثة الأولى 🏆',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
          _buildPodium(top3, isDark, currentUserId),
        ],

        // ─── قائمة الترتيب العام ────────────────────────────
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'الترتيب العام',
              style: GoogleFonts.tajawal(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
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

        const SizedBox(height: 40),
      ],
    );
  }

  // ── المنصة (Podium) ────────────────────────────────────────────────────
  Widget _buildPodium(List<_LeaderboardEntry> top, bool isDark, String? currentUserId) {
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
    final List<double> heights = [100, 140, 80];

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            0, 40 * (1 - Curves.easeOutQuart.transform(_animController.value))),
        child: Opacity(
          opacity: Curves.easeIn.transform(_animController.value.clamp(0, 1)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final entry = ordered[i];
            if (entry == null) return const SizedBox(width: 80);
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
    final avatarSize = rank == 1 ? 72.0 : 58.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rank == 1)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Icon(Icons.workspace_premium_rounded,
                color: Color(0xFFFBBF24), size: 32),
          ),
        // صورة المستخدم
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: isMe ? Colors.white : color,
                width: isMe ? 3 : 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
        const SizedBox(height: 8),
        // الاسم
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isMe ? 'أنت' : entry.name.split(' ').first,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 14 : 12,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // النقاط
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${entry.points} pt',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // قاعدة المنصة
        Container(
          width: double.infinity,
          height: podiumHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
                color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: GoogleFonts.outfit(
                  fontSize: rank == 1 ? 42 : 32,
                  fontWeight: FontWeight.w900,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
              // معلومات إضافية مختصرة
              if (rank == 1) ...[
                const SizedBox(height: 4),
                Icon(Icons.menu_book_rounded, size: 14, color: color.withValues(alpha: 0.7)),
                Text(
                  '${entry.booksRead} كتب',
                  style: GoogleFonts.tajawal(fontSize: 10, color: color.withValues(alpha: 0.8)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── كرت الترتيب العام ────────────────────────────────────────────────
  Widget _buildRankCard(
      _LeaderboardEntry e, int rank, bool isMe, bool isDark) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            0,
            30 *
                (1 -
                    Curves.easeOut.transform(
                        (_animController.value - 0.3).clamp(0, 1)))),
        child: Opacity(
          opacity: ((_animController.value - 0.2) / 0.8).clamp(0, 1),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : (isDark ? AppTheme.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isMe ? AppTheme.primaryColor : Colors.transparent,
            width: isMe ? 1.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // رقم الترتيب
              SizedBox(
                width: 36,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isMe
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white54 : Colors.black38),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              // صورة المستخدم
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe
                        ? AppTheme.primaryColor
                        : e.levelColor.withValues(alpha: 0.4),
                    width: 1.5,
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
              const SizedBox(width: 12),
              // الاسم والمستوى
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'أنت (${e.name})' : e.name,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isMe
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.levelTitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: e.levelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // النقاط
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${e.points}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isMe ? AppTheme.primaryColor : e.levelColor,
                    ),
                  ),
                  Text(
                    'نقطة',
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black38,
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
            style: GoogleFonts.tajawal(
                fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadLeaderboard,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('إعادة المحاولة',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          Icon(Icons.workspace_premium_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا يوجد نشاط بعد في هذه الفترة.\nابدأ القراءة والاختبارات لتتصدر القائمة!',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
                fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ── الصورة الافتراضية ────────────────────────────────────────────────
  Widget _defaultAvatar(String name, Color color) {
    final initial =
        name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
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
