import 'package:flutter/material.dart';
import '../../core/theme/admin_colors.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/notifications/admin_notifications_screen.dart';
import '../../features/activity/admin_activity_screen.dart';
import '../../features/users/admin_users_screen.dart';
import '../services/admin_notification_service.dart';
import 'package:provider/provider.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    // Start listening to real-time notifications for the admin
    AdminNotificationService().startListeningToUnreadCount();
  }

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return const AdminNotificationsScreen();
      case 2:
        return const AdminActivityScreen();
      case 3:
        return const AdminUsersScreen();
      default:
        return const Center(child: Text('صفحة قيد الإنشاء', style: TextStyle(fontSize: 24)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && !isDesktop;

    if (!isDesktop && !_isSidebarCollapsed) {
      _isSidebarCollapsed = true;
    }

    return ChangeNotifierProvider.value(
      value: AdminNotificationService(),
      child: Scaffold(
        backgroundColor: AdminColors.background,
        drawer: !isDesktop && !isTablet
            ? Drawer(
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onMenuSelected: (i) {
                    _onMenuSelected(i);
                    Navigator.pop(context);
                  },
                  isCollapsed: false,
                ),
              )
            : null,
        body: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF5F9FF), Color(0xFFEEF4FB)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AdminColors.borderSoft, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: AdminColors.shadowSoft,
                        blurRadius: 24,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      AdminTopbar(
                        onToggleSidebar: _toggleSidebar,
                        isMobile: !isDesktop && !isTablet,
                      ),
                      Expanded(
                        child: Container(
                          color: AdminColors.background,
                          child: _buildContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop || isTablet)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: _isSidebarCollapsed ? 92 : 268,
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: AdminColors.shadowSoft,
                        blurRadius: 18,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AdminSidebar(
                      selectedIndex: _selectedIndex,
                      onMenuSelected: _onMenuSelected,
                      isCollapsed: _isSidebarCollapsed,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
