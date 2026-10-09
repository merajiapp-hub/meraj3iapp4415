import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/references_screen.dart';
import '../screens/student/reading_history_screen.dart';
import '../screens/reviews_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/info_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/donations_screen.dart';
import '../screens/dedication_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/terms_of_use_screen.dart';

class AppDrawer extends StatelessWidget {
  final bool isGuest;
  
  const AppDrawer({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final userName = auth.userData?['fullName']?.toString().trim().isNotEmpty == true
        ? auth.userData!['fullName'].toString().trim()
        : auth.userData?['name']?.toString().trim().isNotEmpty == true
            ? auth.userData!['name'].toString().trim()
            : user?.displayName?.trim().isNotEmpty == true
                ? user!.displayName!.trim()
                : 'حساب الطالب';
    final userEmail = user?.email ?? '';

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        left: false,
        right: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.deepBlueGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white24,
                      backgroundImage: auth.profileImageProvider,
                      child: auth.profileImageProvider == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      isGuest ? 'مستخدم زائر' : userName,
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    isGuest
                        ? 'سجل دخولك للحصول على مميزات أكثر'
                        : userEmail,
                    style: GoogleFonts.tajawal(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDrawerItem(context, Icons.library_books_rounded, 'مراجع أخرى', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReferencesScreen()),
                    );
                  }),
                  _buildDrawerItem(context, Icons.history_edu_rounded, 'سجل القراءة', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReadingHistoryScreen(),
                      ),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildDrawerItem(context, Icons.reviews_rounded, 'آراء المستخدمين', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReviewsScreen()),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildDrawerItem(context, Icons.notifications_rounded, 'الإشعارات', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  }),
                  _buildDrawerItem(context, Icons.settings_rounded, 'الإعدادات', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildDrawerItem(context, Icons.info_rounded, 'عن التطبيق', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const InfoScreen()),
                    );
                  }),
                  _buildDrawerItem(context, Icons.help_rounded, 'الأسئلة الشائعة', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    );
                  }),
                  _buildDrawerItem(context, 
                    Icons.privacy_tip_rounded,
                    'سياسة الخصوصية',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(context, 
                    Icons.volunteer_activism_rounded,
                    'دعم التطبيق',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DonationsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(context, Icons.auto_awesome_rounded, 'الإهداء', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DedicationScreen()),
                    );
                  }),
                  _buildDrawerItem(context, Icons.contact_support_rounded, 'اتصل بنا', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                    );
                  }),
                  _buildDrawerItem(context, Icons.gavel_rounded, 'شروط الاستخدام', () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                    );
                  }),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Divider(height: 1, thickness: 0.5),
                  ),
                  _buildDrawerItem(context, 
                    Image.asset(
                      'assets/images/logo.png',
                      width: 22,
                      height: 22,
                      color: Colors.red,
                    ),
                    'تسجيل الخروج',
                    () {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: isDark
                                ? AppTheme.surfaceDark
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Column(
                              children: [
                                Image.asset('assets/images/logo.png', height: 60),
                                const SizedBox(height: 12),
                                Text(
                                  'تسجيل الخروج',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                            content: Text(
                              'هل أنت متأكد من أنك تريد تسجيل الخروج من حسابك؟',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.tajawal(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'إلغاء',
                                  style: GoogleFonts.tajawal(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false,
                                  );
                                  await authProvider.signOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'خروج',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    textColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    dynamic icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : const Color(0xFF4A5568);

    return ListTile(
      leading: icon is IconData
          ? Icon(icon, color: textColor ?? defaultColor, size: 24)
          : icon as Widget,
      title: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor ?? (isDark ? Colors.white : const Color(0xFF2D3748)),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: const Color(0xFF0B6B58).withValues(alpha: 0.05),
    );
  }
}
