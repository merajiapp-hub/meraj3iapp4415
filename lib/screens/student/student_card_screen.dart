import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';

class StudentCardScreen extends StatefulWidget {
  const StudentCardScreen({super.key});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    setState(() => _isSharing = true);
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File(
          '${directory.path}/student_card.png',
        ).create();
        await imagePath.writeAsBytes(image);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath.path)],
            text: 'بطاقتي الرقمية في تطبيق مراجعي 🎓',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء المشاركة.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>().profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'البطاقة الرقمية',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded),
            onPressed: _isSharing ? null : _shareCard,
            tooltip: 'مشاركة البطاقة',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Screenshot(
                controller: _screenshotController,
                child: _buildDigitalCard(student, isDark),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareCard,
                icon: const Icon(Icons.share_rounded),
                label: Text(
                  'مشاركة البطاقة كصورة',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalCard(StudentProfile student, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header (Logo + Title)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    Text(
                      'STUDENT CARD',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Avatar + Name
                Row(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                        image: DecorationImage(
                          image: student.avatarPath != null
                              ? FileImage(File(student.avatarPath!))
                                    as ImageProvider
                              : const AssetImage(
                                  'assets/images/avatar_placeholder.png',
                                ),
                          fit: BoxFit.cover,
                          onError: (_, _) {},
                        ),
                      ),
                      child: student.avatarPath == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: GoogleFonts.tajawal(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.grade,
                              style: GoogleFonts.tajawal(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Info Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.science_rounded,
                        'الشعبة',
                        student.department,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.account_balance_rounded,
                        'المؤسسة',
                        student.school,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 24),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('الكتب', '${student.booksRead}'),
                    _buildStatItem('الاختبارات', '${student.quizzesTaken}'),
                    _buildStatItem(
                      'التقدم',
                      '${(student.progressLevel * 100).toInt()}%',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.tajawal(fontSize: 11, color: Colors.white54),
              ),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(fontSize: 13, color: Colors.white54),
        ),
      ],
    );
  }
}
