import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/downloads_provider.dart';
import '../providers/task_provider.dart';
import '../providers/reading_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import 'login_screen.dart';
import 'statistics_screen.dart';
import 'student/reading_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  String? _profileImageUrl;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = auth.user?.displayName ?? '';
    _emailController.text = auth.user?.email ?? '';
    _phoneController.text = auth.userData?['phone'] ?? '';
    _profileImageUrl = auth.user?.photoURL;
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'اختيار صورة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.primaryColor,
              ),
              title: Text('المعرض', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.primaryColor,
              ),
              title: Text('الكاميرا', style: GoogleFonts.tajawal()),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 30, // Highly compressed
      maxWidth: 200, // Small dimensions to save base64 size
      maxHeight: 200,
    );
    if (image == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      final error = await auth.updateProfile(
        _nameController.text,
        null,
        base64Image: base64String,
      );
      if (!mounted) return;
      if (error == null) {
        setState(() => _profileImageUrl = null); // Force using base64
        AppNotification.show(context, 'تم تحديث صورة الملف الشخصي بنجاح');
      } else {
        AppNotification.show(context, error, isError: true);
      }
    } catch (e) {
      if (mounted) AppNotification.show(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getProfileImage() {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // First try base64 if user manually uploaded
    final base64Str = auth.userData?['profileImageBase64'];
    if (base64Str != null && base64Str.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {}
    }

    // Then check if there's a URL in auth user (e.g. from Google Login)
    if (auth.user?.photoURL != null && auth.user!.photoURL!.isNotEmpty) {
      return NetworkImage(auth.user!.photoURL!);
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final error = await auth.updateProfile(_nameController.text, null);
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    if (mounted) {
      if (error == null) {
        AppNotification.show(context, 'تم تحديث الملف بنجاح');
      } else {
        AppNotification.show(context, 'خطأ: $error', isError: true);
      }
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    try {
      await authProvider.signOutGoogle();
    } catch (_) {}
    if (mounted) {
      Provider.of<FavoritesProvider>(context, listen: false).clearAll();
      Provider.of<DownloadsProvider>(context, listen: false).clearAll();
      Provider.of<TaskProvider>(context, listen: false).clearAll();
      Provider.of<ReadingProvider>(context, listen: false).clearAll();
      AppNotification.showLogout(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _changePassword() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final email = auth.user?.email;
    if (email == null || email.isEmpty) {
      AppNotification.show(
        context,
        'لا يوجد بريد إلكتروني مرتبط بهذا الحساب',
        isError: true,
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await auth.resetPassword(email);
    setState(() => _isLoading = false);
    if (mounted) {
      if (error == null) {
        AppNotification.show(
          context,
          'تم إرسال رابط تغيير كلمة المرور إلى: $email',
        );
      } else {
        AppNotification.show(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favorites = Provider.of<FavoritesProvider>(context);
    final downloads = Provider.of<DownloadsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final reading = Provider.of<ReadingProvider>(context);
    final userName = auth.user?.displayName ?? 'المستخدم';
    final userEmail = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : const Color(0xFFF0F4F8),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // ─── الرأس المنحني ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildCurvedHeader(isDark, userName, userEmail),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 80), // مسافة لصورة الحساب
                    // ─── بطاقة الإحصائيات ─────────────────────────────────
                    _buildStatsCard(
                      isDark,
                      favorites.favoriteBooks.length,
                      downloads.downloads.length,
                      reading.readCount,
                    ),
                    const SizedBox(height: 20),
                    // ─── بطاقة المعلومات ───────────────────────────────────
                    _buildInfoCard(isDark),
                    const SizedBox(height: 20),
                    // ─── الأزرار ───────────────────────────────────────────
                    _buildActionsCard(isDark),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── الرأس المنحني مع صورة الحساب ─────────────────────────────────────────
  Widget _buildCurvedHeader(bool isDark, String name, String email) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // الخلفية المنحنية
        ClipPath(
          clipper: _ProfileHeaderClipper(),
          child: Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF14B8A6)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        Text(
                          'حسابي',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        IconButton(
                          onPressed: _isLoading
                              ? null
                              : (_isEditing
                                    ? _saveProfile
                                    : () => setState(() => _isEditing = true)),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? AppTheme.primaryColor
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isEditing
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // صورة الحساب فوق الرأس
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppTheme.backgroundDark
                        : const Color(0xFFF0F4F8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: (_isEditing && !_isLoading)
                        ? _showImageSourceDialog
                        : null,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'م',
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                if (_isEditing && !_isLoading)
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black45,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── بطاقة الإحصائيات ──────────────────────────────────────────────────────
  Widget _buildStatsCard(
    bool isDark,
    int favCount,
    int dlCount,
    int readCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            'المفضلة',
            '$favCount',
            Icons.favorite_rounded,
            const Color(0xFFEF4444),
            isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            'التنزيلات',
            '$dlCount',
            Icons.download_done_rounded,
            const Color(0xFF10B981),
            isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            'مقروءة',
            '$readCount',
            Icons.menu_book_rounded,
            AppTheme.primaryColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 50,
      width: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gender = auth.userData?['gender'] ?? 'غير محدد';
    final creationTime = auth.user?.metadata.creationTime;
    final lastSignInTime = auth.user?.metadata.lastSignInTime;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المعلومات الشخصية',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            isDark: isDark,
            controller: _nameController,
            label: 'الاسم الكامل',
            icon: Icons.person_outline_rounded,
            enabled: _isEditing,
          ),
          const SizedBox(height: 14),
          _buildInfoField(
            isDark: isDark,
            controller: _emailController,
            label: 'البريد الإلكتروني',
            icon: Icons.email_outlined,
            enabled: false,
          ),
          const SizedBox(height: 14),
          _buildInfoField(
            isDark: isDark,
            controller: _phoneController,
            label: 'رقم الهاتف',
            icon: Icons.phone_outlined,
            enabled: false,
          ),
          const SizedBox(height: 14),
          _buildReadOnlyField(
            isDark: isDark,
            label: 'الجنس',
            value: gender,
            icon: gender == 'ذكر' ? Icons.male_rounded : Icons.female_rounded,
          ),
          if (creationTime != null) ...[
            const SizedBox(height: 14),
            _buildReadOnlyField(
              isDark: isDark,
              label: 'تاريخ إنشاء الحساب',
              value:
                  '${creationTime.day}/${creationTime.month}/${creationTime.year}',
              icon: Icons.calendar_today_rounded,
            ),
          ],
          if (lastSignInTime != null) ...[
            const SizedBox(height: 14),
            _buildReadOnlyField(
              isDark: isDark,
              label: 'آخر تسجيل دخول',
              value:
                  '${lastSignInTime.day}/${lastSignInTime.month}/${lastSignInTime.year}',
              icon: Icons.login_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.tajawal(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF8FAFC))
            : (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? AppTheme.primaryColor.withValues(alpha: 0.4)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE2E8F0)),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: GoogleFonts.tajawal(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.tajawal(
            color: Colors.grey[500],
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ─── الأزرار ────────────────────────────────────────────────────────────────
  Widget _buildActionsCard(bool isDark) {
    return Column(
      children: [

        _buildActionButton(
          label: 'سجل القراءة',
          icon: Icons.history_rounded,
          color: Colors.teal,
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReadingHistoryScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'تغيير كلمة المرور',
          icon: Icons.lock_reset_rounded,
          color: AppTheme.primaryColor,
          isDark: isDark,
          onTap: _changePassword,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'الإحصائيات',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatisticsScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          label: 'تسجيل الخروج',
          icon: Icons.logout_rounded,
          color: Colors.redAccent,
          isDark: isDark,
          onTap: _logout,
        ),
        const SizedBox(height: 24),
        Text(
          'MERAJ3I © 2026',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        Text(
          'Développé par Mohamed Mahmoud Abderrahmane',
          style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
          ],
        ),
      ),
    );
  }
}

// ─── منحنى رأس صفحة الحساب ──────────────────────────────────────────────────
class _ProfileHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
