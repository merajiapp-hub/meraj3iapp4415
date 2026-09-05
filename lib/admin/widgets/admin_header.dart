import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/admin_login_screen.dart';
import '../../providers/theme_provider.dart';

class AdminHeader extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const AdminHeader({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 16),
          ],
          const Expanded(
            child: Text(
              'لوحة تحكم مراجعي',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: const Color(0xFF6B7280),
            ),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
            tooltip: 'تغيير المظهر',
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Badge(
              label: Text('2'), // Example badge for notifications
              child: Icon(Icons.notifications_outlined, color: Color(0xFF6B7280)),
            ),
            onPressed: () {
              // Open admin notifications
            },
            tooltip: 'الإشعارات',
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0F766E),
                backgroundImage: authProvider.profileImageProvider,
                child: authProvider.profileImageProvider == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.user?.displayName ?? 'مدير النظام',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    authProvider.user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                );
              }
            },
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
    );
  }
}
