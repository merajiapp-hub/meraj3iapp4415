import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../core/theme/admin_colors.dart';
import '../services/admin_notification_service.dart';

class AdminTopbar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final bool isMobile;

  const AdminTopbar({
    super.key,
    required this.onToggleSidebar,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AdminColors.topbarBackground,
        border: const Border(bottom: BorderSide(color: AdminColors.borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AdminColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 20),
              onPressed: onToggleSidebar,
              color: AdminColors.primaryDeep,
              splashRadius: 20,
              tooltip: 'تبديل القائمة',
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AdminColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AdminColors.borderSoft),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث سريع',
                    hintStyle: GoogleFonts.tajawal(color: AdminColors.textLight, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.textLight, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  style: GoogleFonts.tajawal(fontSize: 13, color: AdminColors.textDark),
                ),
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(width: 12),
          _buildNotificationIcon(context),
          const SizedBox(width: 8),
          _buildIconButton(Icons.dark_mode_outlined, context),
          const SizedBox(width: 12),
          _buildProfileMenu(context),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: AdminColors.textDark,
      onPressed: () {
        // Handle action
      },
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    return Consumer<AdminNotificationService>(
      builder: (context, notificationService, _) {
        final count = notificationService.unreadCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              color: AdminColors.textDark,
              onPressed: () {
                // Navigate to notifications tab or open dropdown
              },
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: const CircleAvatar(
        backgroundColor: AdminColors.primaryLight,
        child: Icon(Icons.person, color: AdminColors.primaryDark),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'تسجيل الخروج',
                style: GoogleFonts.tajawal(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        if (value == 'logout') {
          await Provider.of<AuthProvider>(context, listen: false).signOut();
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      },
    );
  }
}
