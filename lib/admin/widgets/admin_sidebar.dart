import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Image.asset(
            'assets/images/logo.png',
            height: 60,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'لوحة الإدارة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(Icons.dashboard_outlined, 'نظرة عامة', 0),
                _buildNavItem(Icons.people_outline, 'المستخدمون', 1),
                _buildNavItem(Icons.menu_book_outlined, 'الكتب والمحتوى', 2),
                _buildNavItem(Icons.notifications_outlined, 'الإشعارات', 3),
                _buildNavItem(Icons.settings_outlined, 'إعدادات النظام', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF6B7280),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF374151),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFF0FDF4), // Light green tint
      onTap: () => onItemSelected(index),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      mouseCursor: SystemMouseCursors.click,
    );
  }
}
