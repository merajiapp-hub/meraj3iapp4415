import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/student_provider.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_notification.dart';

class StudentCardScreen extends StatefulWidget {
  const StudentCardScreen({super.key});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _wilayaCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _phoneCtrl;

  String _selectedGrade = 'السنة الثالثة ثانوي';
  String _selectedDepartment = 'علوم تجريبية';

  final List<String> _grades = [
    'السنة الأولى',
    'السنة الثانية',
    'السنة الثالثة',
    'السنة الرابعة',
    'السنة الخامسة',
    'السنة السادسة',
    'السنة الأولى إعدادي',
    'السنة الثانية إعدادي',
    'السنة الثالثة إعدادي',
    'السنة الرابعة إعدادي',
    'السنة الأولى ثانوي',
    'السنة الثانية ثانوي',
    'السنة الثالثة ثانوي',
  ];

  final List<String> _departments = [
    'عام',
    'علوم تجريبية',
    'رياضيات',
    'آداب عصرية',
    'آداب أصلية',
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<StudentProvider>().profile;
    _nameCtrl = TextEditingController(text: profile.name);
    _schoolCtrl = TextEditingController(text: profile.school);
    _wilayaCtrl = TextEditingController(text: profile.wilaya ?? '');
    _cityCtrl = TextEditingController(text: profile.city ?? '');
    _phoneCtrl = TextEditingController(text: profile.phoneNumber ?? '');
    
    if (_grades.contains(profile.grade)) {
      _selectedGrade = profile.grade;
    }
    if (_departments.contains(profile.department)) {
      _selectedDepartment = profile.department;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    _wilayaCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

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
        AppNotification.show(context, 'حدث خطأ أثناء المشاركة.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      await context.read<StudentProvider>().updateField('avatarPath', pickedFile.path);
      if (mounted) AppNotification.show(context, 'تم تحديث الصورة الشخصية');
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = context.read<StudentProvider>();
      final currentProfile = provider.profile;

      final updatedProfile = StudentProfile(
        name: _nameCtrl.text.trim(),
        grade: _selectedGrade,
        department: _selectedDepartment,
        school: _schoolCtrl.text.trim(),
        avatarPath: currentProfile.avatarPath,
        wilaya: _wilayaCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        studentId: currentProfile.studentId,
        phoneNumber: _phoneCtrl.text.trim(),
        bio: currentProfile.bio,
        email: currentProfile.email,
        cardCreatedAt: currentProfile.cardCreatedAt,
        booksRead: currentProfile.booksRead,
        quizzesTaken: currentProfile.quizzesTaken,
        progressLevel: currentProfile.progressLevel,
        achievements: currentProfile.achievements,
      );

      await provider.updateProfile(updatedProfile);
      if (mounted) {
        AppNotification.show(context, 'تم حفظ المعلومات وتحديث البطاقة');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── البطاقة الرقمية ──
            Screenshot(
              controller: _screenshotController,
              child: _buildDigitalCard(student, isDark),
            ),
            
            const SizedBox(height: 32),
            Divider(color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            
            Text(
              'تحديث بيانات الطالب',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // ── نموذج تعديل البيانات ──
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'الاسم الكامل',
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _schoolCtrl,
                    label: 'المؤسسة التعليمية',
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'المرحلة / السنة',
                          value: _selectedGrade,
                          items: _grades,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGrade = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdown(
                          label: 'الشعبة',
                          value: _selectedDepartment,
                          items: _departments,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDepartment = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _wilayaCtrl,
                          label: 'الولاية',
                          icon: Icons.map_rounded,
                          required: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _cityCtrl,
                          label: 'المدينة / المقاطعة',
                          icon: Icons.location_city_rounded,
                          required: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'رقم الهاتف',
                    icon: Icons.phone_rounded,
                    isPhone: true,
                    required: false,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      'حفظ التعديلات',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
    bool isPhone = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl,
      style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: Colors.grey),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
      dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
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
                                Icons.add_a_photo_rounded,
                                size: 30,
                                color: Colors.white70,
                              )
                            : null,
                      ),
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
                if ((student.wilaya?.isNotEmpty ?? false) || (student.city?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (student.wilaya?.isNotEmpty ?? false)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.map_rounded,
                            'الولاية',
                            student.wilaya!,
                          ),
                        ),
                      if (student.city?.isNotEmpty ?? false)
                        Expanded(
                          child: _buildInfoItem(
                            Icons.location_city_rounded,
                            'المدينة',
                            student.city!,
                          ),
                        ),
                    ],
                  ),
                ],
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
