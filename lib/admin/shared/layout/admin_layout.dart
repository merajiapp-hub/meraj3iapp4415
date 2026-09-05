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
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768 && !isDesktop;

    if (!isDesktop && !_isSidebarCollapsed) {
      _isSidebarCollapsed = true; // Auto collapse on small screens
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
                    Navigator.pop(context); // Close drawer
                  },
                  isCollapsed: false,
                ),
              )
            : null,
        body: Row(
          children: [
            if (isDesktop || isTablet)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarCollapsed ? 80 : 260,
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onMenuSelected: _onMenuSelected,
                  isCollapsed: _isSidebarCollapsed,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminTopbar(
                    onToggleSidebar: _toggleSidebar,
                    isMobile: !isDesktop && !isTablet,
                  ),
                  Expanded(
                    child: ClipRRect(
                      child: _buildContent(),
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
}
