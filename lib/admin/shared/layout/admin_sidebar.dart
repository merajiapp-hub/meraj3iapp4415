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
    final menuItems = [
      _MenuItem(id: 0, icon: Icons.dashboard_outlined, title: 'الرئيسية'),
      _MenuItem(id: 1, icon: Icons.notifications_none_outlined, title: 'الإشعارات'),
      _MenuItem(id: 2, icon: Icons.history_outlined, title: 'النشاط'),
      _MenuItem(id: 3, icon: Icons.people_outline, title: 'المستخدمون'),
      _MenuItem(id: 4, icon: Icons.library_books_outlined, title: 'الكتب'),
      _MenuItem(id: 5, icon: Icons.quiz_outlined, title: 'الاختبارات'),
      _MenuItem(id: 6, icon: Icons.star_outline, title: 'التقييمات'),
      _MenuItem(id: 7, icon: Icons.message_outlined, title: 'الرسائل'),
      _MenuItem(id: 8, icon: Icons.analytics_outlined, title: 'التحليلات'),
      _MenuItem(id: 9, icon: Icons.settings_outlined, title: 'الإعدادات'),
      _MenuItem(id: 10, icon: Icons.security_outlined, title: 'الأمان'),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AdminColors.sidebarBackground, AdminColors.sidebarBackgroundAlt],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = selectedIndex == item.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1) : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onMenuSelected(item.id),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: EdgeInsets.symmetric(
                            horizontal: isCollapsed ? 0 : 14,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: isSelected ? AdminColors.primaryDeep : AdminColors.sidebarItemText,
                                  size: 18,
                                ),
                              ),
                              if (!isCollapsed) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.tajawal(
                                      color: isSelected ? Colors.white : AdminColors.sidebarItemText,
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: isCollapsed
          ? Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.business_center_rounded, color: AdminColors.primaryDeep, size: 22),
            )
          : Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.business_center_rounded, color: AdminColors.primaryDeep, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MERAJ3I',
                        style: GoogleFonts.tajawal(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: GoogleFonts.tajawal(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: AdminColors.primaryDeep, size: 18),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'المدير',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  final int id;
  final IconData icon;
  final String title;

  const _MenuItem({required this.id, required this.icon, required this.title});
}
