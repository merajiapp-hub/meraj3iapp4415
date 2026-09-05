import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/admin_colors.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final bool isCollapsed;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.sidebarBackground,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(context, 0, Icons.dashboard_outlined, 'الرئيسية'),
                _buildMenuItem(context, 1, Icons.notifications_none_outlined, 'الإشعارات'),
                _buildMenuItem(context, 2, Icons.history_outlined, 'النشاط'),
                const Divider(color: Colors.white24, height: 32),
                _buildMenuItem(context, 3, Icons.people_outline, 'المستخدمون'),
                _buildMenuItem(context, 4, Icons.library_books_outlined, 'المحتوى والكتب'),
                _buildMenuItem(context, 5, Icons.quiz_outlined, 'الامتحانات والنتائج'),
                _buildMenuItem(context, 6, Icons.star_outline, 'المراجعات والتقييمات'),
                const Divider(color: Colors.white24, height: 32),
                _buildMenuItem(context, 7, Icons.message_outlined, 'الرسائل والتواصل'),
                _buildMenuItem(context, 8, Icons.analytics_outlined, 'التحليلات'),
                _buildMenuItem(context, 9, Icons.settings_outlined, 'إعدادات التطبيق'),
                _buildMenuItem(context, 10, Icons.security_outlined, 'سجل التدقيق الأمني'),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 80,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            width: 40,
            errorBuilder: (_, _, _) => const Icon(Icons.school, color: Colors.white, size: 40),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'MERAJ3I Admin',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, int index, IconData icon, String title) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? AdminColors.sidebarItemSelected : AdminColors.sidebarItemText;
    final bgColor = isSelected ? AdminColors.sidebarItemBackgroundSelected : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMenuSelected(index),
        child: Container(
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              if (!isCollapsed) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.tajawal(
                      color: color,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: AdminColors.primary,
            radius: 16,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المدير',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: GoogleFonts.tajawal(
                      color: AdminColors.sidebarItemText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
