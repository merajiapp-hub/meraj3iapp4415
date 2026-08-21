import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'users/admin_users_list_screen.dart';
import 'notifications/admin_notifications_screen.dart';
import 'books/admin_books_screen.dart';
import 'settings/admin_settings_screen.dart';
import 'monitoring/admin_health_screen.dart';
import 'logs/admin_audit_logs_screen.dart';
import 'admin_guard.dart';
// ignore_for_file: unused_import

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // إجبار الثيم الداكن للوحة التحكم
    return AdminGuard(
      child: Theme(
        data: ThemeData.dark().copyWith(
          primaryColor: Colors.tealAccent,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F1F1F),
            elevation: 0,
            centerTitle: true,
          ),
          cardColor: const Color(0xFF1E1E1E),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('MERAJ3I Admin', style: TextStyle(fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'نظرة عامة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const _StatisticsGrid(),
        const SizedBox(height: 24),
        const Text(
          'الإدارة السريعة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _ActionTile(
          icon: Icons.people,
          title: 'إدارة المستخدمين',
          color: Colors.blueAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersListScreen())),
        ),
        _ActionTile(
          icon: Icons.book,
          title: 'إدارة الكتب والمحتوى',
          color: Colors.orangeAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBooksScreen())),
        ),
        _ActionTile(
          icon: Icons.notifications,
          title: 'مركز الإشعارات',
          color: Colors.purpleAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen())),
        ),
        _ActionTile(
          icon: Icons.settings,
          title: 'إعدادات النظام والـ Remote Config',
          color: Colors.grey,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
        ),
        _ActionTile(
          icon: Icons.health_and_safety,
          title: 'مراقبة النظام والأخطاء',
          color: Colors.redAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHealthScreen())),
        ),
        _ActionTile(
          icon: Icons.list_alt,
          title: 'سجل نشاط الإدارة (Audit Logs)',
          color: Colors.green,
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
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('المستخدمين', _getCount('users'), Icons.people, Colors.blue),
        _buildStatCard('الكتب المتاحة', _getCount('books'), Icons.library_books, Colors.orange),
        _buildStatCard('عمليات البحث', _getCount('search_logs'), Icons.search, Colors.teal),
        _buildStatCard('السجلات الإدارية', _getCount('audit_logs'), Icons.security, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String title, Future<int> countFuture, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 4),
            FutureBuilder<int>(
              future: countFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (snapshot.hasError) {
                  return const Text('خطأ', style: TextStyle(color: Colors.red));
                }
                return Text(
                  '${snapshot.data}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                );
              },
            ),
          ],
        ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
