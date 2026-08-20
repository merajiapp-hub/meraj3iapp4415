import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';
import '../widgets/geometric_sliver_app_bar.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math;

class StudentCompetitionScreen extends StatefulWidget {
  const StudentCompetitionScreen({super.key});

  @override
  State<StudentCompetitionScreen> createState() => _StudentCompetitionScreenState();
}

class _StudentCompetitionScreenState extends State<StudentCompetitionScreen> with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          const GeometricSliverAppBar(
            title: 'التنافس بين الطلاب',
            icon: Icons.emoji_events_rounded,
            gradient: AppTheme.brandGradient,
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: _buildHeaderCard(isDark),
            ),
          ),
          
          // إحصائيات التنافس
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'إحصائيات التنافس',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').orderBy('booksRead', descending: true).limit(1).snapshots(),
                builder: (context, booksSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').orderBy('quizzesTaken', descending: true).limit(1).snapshots(),
                    builder: (context, quizzesSnapshot) {
                      return ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildTopStatCard(
                            title: 'الأكثر قراءة',
                            icon: Icons.menu_book_rounded,
                            color: Colors.blue,
                            data: booksSnapshot.data?.docs.firstOrNull?.data() as Map<String, dynamic>?,
                            valKey: 'booksRead',
                            isDark: isDark,
                          ),
                          const SizedBox(width: 12),
                          _buildTopStatCard(
                            title: 'الأكثر اختباراً',
                            icon: Icons.quiz_rounded,
                            color: Colors.green,
                            data: quizzesSnapshot.data?.docs.firstOrNull?.data() as Map<String, dynamic>?,
                            valKey: 'quizzesTaken',
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          // لوحة الشرف والترتيب
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .orderBy('points', descending: true)
                  .orderBy('progressLevel', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('حدث خطأ أثناء جلب الترتيب.', style: GoogleFonts.tajawal()),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                final activeUsers = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['points'] ?? 0) > 0 || (data['booksRead'] ?? 0) > 0;
                }).toList();

                if (activeUsers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.workspace_premium_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد نشاط بعد.\nكن أول من يتصدر القائمة!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'لوحة الشرف 🏆',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    
                    if (activeUsers.length >= 3)
                      _buildPodium(activeUsers.take(3).toList(), isDark)
                    else if (activeUsers.isNotEmpty)
                      _buildPodium(activeUsers, isDark),

                    const SizedBox(height: 10),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'الترتيب العام',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 40),
                      itemCount: math.max(0, activeUsers.length - 3),
                      itemBuilder: (context, index) {
                        final realIndex = index + 3;
                        final doc = activeUsers[realIndex];
                        final data = doc.data() as Map<String, dynamic>;
                        final isMe = doc.id == currentUserId;
                        
                        return _buildStudentRankCard(data, realIndex + 1, isMe, isDark);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<QueryDocumentSnapshot> topUsers, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (topUsers.length > 1) 
            _buildPodiumItem(topUsers[1], 2, 110, const Color(0xFF94A3B8), isDark), // الفضي
          if (topUsers.isNotEmpty)
            _buildPodiumItem(topUsers[0], 1, 150, const Color(0xFFFBBF24), isDark), // الذهبي
          if (topUsers.length > 2)
            _buildPodiumItem(topUsers[2], 3, 90, const Color(0xFFB45309), isDark), // البرونزي
        ],
      ),
    );
  }

  Widget _buildPodiumItem(QueryDocumentSnapshot doc, int rank, double height, Color color, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'طالب';
    final points = data['points'] ?? 0;
    final profileImageUrl = data['profileImageUrl'];
    
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - Curves.easeOutQuart.transform(_animController.value))),
          child: Opacity(
            opacity: Curves.easeIn.transform(_animController.value),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            if (rank == 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 36),
              ),
            Container(
              width: rank == 1 ? 75 : 60,
              height: rank == 1 ? 75 : 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipOval(
                child: profileImageUrl != null 
                    ? CachedNetworkImage(
                        imageUrl: profileImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(color: color, strokeWidth: 2),
                        errorWidget: (context, url, error) => Icon(Icons.person, color: color, size: rank == 1 ? 40 : 30),
                      )
                    : Container(
                        color: isDark ? Colors.white10 : Colors.grey[200],
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.tajawal(
                              fontSize: rank == 1 ? 28 : 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: rank == 1 ? 100 : 85,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$points pt',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: rank == 1 ? 90 : 80,
              height: height,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -2),
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 15,
                    child: Text(
                      '$rank',
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: color.withValues(alpha: 0.5),
                      ),
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

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
          const SizedBox(height: 12),
          Text(
            'تنافس للوصول للقمة!',
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يتم احتساب الترتيب بناءً على قراءتك، إنجازاتك في المهام ونتائج اختباراتك. استمر في التقدم!',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRankCard(Map<String, dynamic> data, int rank, bool isMe, bool isDark) {
    final name = data['name'] ?? 'طالب';
    final points = data['points'] ?? 0;
    final booksRead = data['booksRead'] ?? 0;
    final tests = data['quizzesTaken'] ?? 0;
    final tasks = data['completedTasks'] ?? 0;
    final progress = data['progressLevel'] ?? 0.0;
    final profileImageUrl = data['profileImageUrl'];

    Color cardColor = isDark ? AppTheme.surfaceDark : Colors.white;
    Color borderColor = Colors.transparent;
    
    if (isMe) {
      borderColor = AppTheme.primaryColor;
      cardColor = AppTheme.primaryColor.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isMe ? 1.5 : 0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  backgroundImage: profileImageUrl != null ? CachedNetworkImageProvider(profileImageUrl) : null,
                  child: profileImageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? 'أنت ($name)' : name,
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isMe ? AppTheme.primaryColor : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$points نقطة',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : Colors.grey[200]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.menu_book_rounded, 'كتب', booksRead, isDark),
                _buildStatItem(Icons.task_alt_rounded, 'مهام', tasks, isDark),
                _buildStatItem(Icons.quiz_rounded, 'اختبارات', tests, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white54 : Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, dynamic>? data,
    required String valKey,
    required bool isDark,
  }) {
    final name = data?['name'] ?? 'لا يوجد';
    final val = data?[valKey] ?? 0;
    
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$val',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
