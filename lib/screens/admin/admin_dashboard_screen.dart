import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users/admin_users_list_screen.dart';
import 'notifications/admin_notifications_screen.dart';
import 'books/admin_books_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'monitoring/admin_health_screen.dart';
import 'logs/admin_audit_logs_screen.dart';
import 'admin_chat_dashboard_screen.dart';
import 'admin_guard.dart';
// ignore_for_file: unused_import

import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Theme(
        data: ThemeData.dark().copyWith(
          primaryColor: Colors.purpleAccent,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Modern dark blue/slate
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          cardColor: const Color(0xFF1E293B),
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.9),
                    const Color(0xFF0F172A).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Text(
              'لوحة تحكم MERAJ3I',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'مركز الإشعارات',
                  icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF8B5CF6)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
                  ),
                ),
              ),
            ],
          ),
          body: const _DashboardBody(),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 24),
      children: [
        Text(
          'نظرة عامة',
          style: GoogleFonts.tajawal(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const _StatisticsGrid(),
        const SizedBox(height: 32),
        Text(
          'الإدارة السريعة',
          style: GoogleFonts.tajawal(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _ActionTile(
          icon: Icons.people_alt_rounded,
          title: 'إدارة المستخدمين',
          color: const Color(0xFF3B82F6), // Blue
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersListScreen())),
        ),
        _ActionTile(
          icon: Icons.my_library_books_rounded,
          title: 'إدارة الكتب والمحتوى',
          color: const Color(0xFFF59E0B), // Amber
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBooksScreen())),
        ),
        _ActionTile(
          icon: Icons.notifications_active_rounded,
          title: 'مركز الإشعارات',
          color: const Color(0xFF8B5CF6), // Purple
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen())),
        ),
        _ActionTile(
          icon: Icons.settings_suggest_rounded,
          title: 'إعدادات النظام (Remote Config)',
          color: const Color(0xFF64748B), // Slate
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
        ),
        _ActionTile(
          icon: Icons.health_and_safety_rounded,
          title: 'مراقبة النظام والأخطاء',
          color: const Color(0xFFEF4444), // Red
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHealthScreen())),
        ),
        _ActionTile(
          icon: Icons.chat_rounded,
          title: 'صندوق الرسائل والدعم',
          color: const Color(0xFF0D9488), // Teal
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminChatDashboardScreen())),
        ),
        _ActionTile(
          icon: Icons.list_alt_rounded,
          title: 'سجل نشاط الإدارة',
          color: const Color(0xFF10B981), // Emerald
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAuditLogsScreen())),
        ),
      ],
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid();

  Future<int> _getCount(String collection) async {
    final snap = await FirebaseFirestore.instance.collection(collection).count().get();
    return snap.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('المستخدمين', _getCount('users'), Icons.group_rounded, const Color(0xFF3B82F6)),
        _buildStatCard('الكتب المتاحة', _getCount('uploaded_books'), Icons.menu_book_rounded, const Color(0xFFF59E0B)),
        _buildStatCard('عمليات البحث', _getCount('search_logs'), Icons.travel_explore_rounded, const Color(0xFF14B8A6)),
        _buildStatCard('سجلات الإدارة', _getCount('admin_activity_logs'), Icons.admin_panel_settings_rounded, const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _buildStatCard(String title, Future<int> countFuture, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              icon,
              size: 100,
              color: color.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<int>(
                      future: countFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        return Text(
                          '${snapshot.data ?? 0}',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
