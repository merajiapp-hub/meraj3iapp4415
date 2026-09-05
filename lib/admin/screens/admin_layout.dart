import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_header.dart';
import 'admin_overview_screen.dart';
import 'admin_users_screen.dart';
import 'admin_books_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_login_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminOverviewScreen(),
    const AdminUsersScreen(),
    const AdminBooksScreen(),
    const AdminNotificationsScreen(),
    const AdminSettingsScreen(),
  ];

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Security check: if not admin, immediately return to login
    if (!authProvider.isAuthenticated || !authProvider.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        drawer: !isDesktop 
            ? Drawer(
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    _onMenuSelected(index);
                    Navigator.pop(context); // Close drawer
                  },
                ),
              )
            : null,
        body: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 250,
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onMenuSelected,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  AdminHeader(
                    onMenuPressed: !isDesktop
                        ? () {
                            Scaffold.of(context).openDrawer();
                          }
                        : null,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
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
