import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';

class StudentCardScreen extends StatefulWidget {
  const StudentCardScreen({super.key});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  Future<void> _shareCard() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/student_card.png').create();
        await imagePath.writeAsBytes(image);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'بطاقتي الرقمية من منصة مراجعي 🎓',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'فشل في مشاركة البطاقة', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final stats = Provider.of<StatisticsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final name = auth.user?.displayName ?? 'طالب مراجعي';
    final photoUrl = auth.user?.photoURL;
    final level = auth.userData?['stage'] ?? 'مرحلة غير محددة';

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('البطاقة الرقمية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/images/logo.png', width: 40, height: 40, errorBuilder: (_, _, _) => const SizedBox(width: 40)),
                          Text(
                            'MERAJ3I',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        level,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('الكتب', '${stats.userReadBooks}'),
                            _buildStatItem('الاختبارات', '${stats.userTestsTaken}'),
                            _buildStatItem('المهام', '${stats.userCompletedTasks}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isCapturing)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _shareCard,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: Text('مشاركة البطاقة', style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
