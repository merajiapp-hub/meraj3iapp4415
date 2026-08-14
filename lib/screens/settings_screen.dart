import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../providers/theme_provider.dart';
import '../data/notification_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricsEnabled = false;
  bool _canCheckBiometrics = false;
  bool _studyReminders = true;
  bool _bookUpdates = true;
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const _keyStudyReminders = 'notif_study_reminders';
  static const _keyBookUpdates = 'notif_book_updates';
  static const _keyBiometrics = 'biometrics_enabled';

  String _version = '';
  String _patchNumber = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadPreferences();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final updater = ShorebirdUpdater();
      final patch = await updater.readCurrentPatch();
      if (mounted) {
        setState(() {
          _version = '${info.version}+${info.buildNumber}';
          _patchNumber = patch != null ? 'Patch ${patch.number}' : '';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = false;
    try {
      canCheck =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {}
    if (mounted) setState(() => _canCheckBiometrics = canCheck);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometricsEnabled = prefs.getBool(_keyBiometrics) ?? false;
        _studyReminders = prefs.getBool(_keyStudyReminders) ?? true;
        _bookUpdates = prefs.getBool(_keyBookUpdates) ?? true;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      bool authenticated = false;
      try {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'قم بالمصادقة لتفعيل الدخول بالبصمة',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } catch (_) {}
      if (!authenticated) {
        if (!mounted) return;
        _showSnack('فشلت المصادقة بالبصمة', isError: true);
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometrics, value);
    if (mounted) {
      setState(() => _biometricsEnabled = value);
      _showSnack(value ? 'تم تفعيل الدخول بالبصمة' : 'تم إلغاء الدخول بالبصمة');
    }
  }

  Future<void> _toggleStudyReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStudyReminders, value);
    if (mounted) setState(() => _studyReminders = value);

    if (!value) {
      // إلغاء جميع إشعارات المهام
      await NotificationService().cancelAll();
      _showSnack('تم إيقاف تذكيرات الدراسة');
    } else {
      _showSnack('تم تفعيل تذكيرات الدراسة');
    }
  }

  Future<void> _toggleBookUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBookUpdates, value);
    if (mounted) setState(() => _bookUpdates = value);
    _showSnack(value ? 'تم تفعيل إشعارات الكتب' : 'تم إيقاف إشعارات الكتب');
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.tajawal()),
        backgroundColor: isError ? Colors.redAccent : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'الإعدادات',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.deepBlueGradient,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── المظهر ──────────────────────────────────────────
                        _sectionTitle('المظهر'),
                        _buildCard(
                          isDark: isDark,
                          bgColor: bgCard,
                          child: SwitchListTile(
                            title: Text(
                              'الوضع الليلي',
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              'سمة داكنة مريحة للعين',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppTheme.accentColor
                                            : AppTheme.primaryColor)
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isDark
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: isDark
                                    ? AppTheme.accentColor
                                    : AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            value: themeProvider.isDarkMode,
                            onChanged: (val) => themeProvider.toggleTheme(val),
                            activeThumbColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── الأمان ──────────────────────────────────────────
                        _sectionTitle('الأمان والخصوصية'),
                        _buildCard(
                          isDark: isDark,
                          bgColor: bgCard,
                          child: _canCheckBiometrics
                              ? SwitchListTile(
                                  title: Text(
                                    'الدخول بالبصمة',
                                    style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'استخدام البصمة لفتح التطبيق',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  secondary: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  value: _biometricsEnabled,
                                  onChanged: _toggleBiometrics,
                                  activeThumbColor: AppTheme.primaryColor,
                                )
                              : ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Colors.grey,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    'البصمة غير مدعومة',
                                    style: GoogleFonts.tajawal(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'جهازك لا يدعم المصادقة البيومترية',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),

                        // ── الإشعارات ───────────────────────────────────────
                        _sectionTitle('الإشعارات'),
                        _buildCard(
                          isDark: isDark,
                          bgColor: bgCard,
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: Text(
                                  'تذكيرات الدراسة',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  _studyReminders
                                      ? 'إشعار عند انتهاء وقت المهمة'
                                      : 'مُعطَّل',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: Colors.blue,
                                    size: 22,
                                  ),
                                ),
                                value: _studyReminders,
                                onChanged: _toggleStudyReminders,
                                activeThumbColor: AppTheme.primaryColor,
                              ),
                              Divider(
                                height: 1,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey[200],
                              ),
                              SwitchListTile(
                                title: Text(
                                  'تحديثات الكتب',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  _bookUpdates
                                      ? 'تنبيه عند إضافة كتب جديدة'
                                      : 'مُعطَّل',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.bookmark_added_rounded,
                                    color: Colors.green,
                                    size: 22,
                                  ),
                                ),
                                value: _bookUpdates,
                                onChanged: _toggleBookUpdates,
                                activeThumbColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── تذييل ───────────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '© 2025 MERAJ3I. جميع الحقوق محفوظة.',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (_version.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'الإصدار: $_version${_patchNumber.isNotEmpty ? ' ($_patchNumber)' : ''}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.8),
                                  ),
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.tajawal(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Color bgColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}
