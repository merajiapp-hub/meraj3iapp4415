import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../widgets/app_notification.dart';
import '../providers/statistics_provider.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _subjectController = TextEditingController();
  
  String _selectedStage = 'الابتدائية';
  final String _selectedGrade = 'السنة الأولى';
  String _selectedCategory = 'كتب مدرسية';
  
  bool _isLoading = false;

  final List<String> _stages = [
    'الابتدائية',
    'الإعدادية',
    'الثانوية',
    'الوطنية',
    'SWEDD',
    'كتب أخرى'
  ];

  final List<String> _categories = [
    'كتب مدرسية',
    'مراجع خارجية',
    'ملخصات',
    'امتحانات وحلول'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  String _processUrl(String url) {
    if (url.contains('drive.google.com/file/d/')) {
      try {
        final id = url.split('/d/')[1].split('/')[0].split('?')[0];
        return 'https://drive.google.com/uc?export=download&id=$id&confirm=t';
      } catch (e) {
        return url;
      }
    }
    return url;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppNotification.show(context, 'يجب تسجيل الدخول لإضافة كتاب', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final processedUrl = _processUrl(_urlController.text.trim());
      
      final bookData = {
        'title': _titleController.text.trim(),
        'subject': _subjectController.text.trim(),
        'section': _selectedStage,
        'grade': _selectedGrade,
        'category': _selectedCategory,
        'url': processedUrl,
        'uploaderId': user.uid,
        'uploadDate': FieldValue.serverTimestamp(),
        'openCount': 0,
      };

      await FirebaseFirestore.instance.collection('uploaded_books').add(bookData);

      if (mounted) {
        final stats = Provider.of<StatisticsProvider>(context, listen: false);
        stats.incrementUserStat('addedBooks');
        
        AppNotification.show(context, 'تمت إضافة الكتاب بنجاح! شكراً لمساهمتك.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.show(context, 'حدث خطأ أثناء الإضافة', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isUrl = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: isUrl ? TextInputType.url : TextInputType.text,
      textDirection: isUrl ? TextDirection.ltr : TextDirection.rtl,
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
        if (value == null || value.trim().isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        if (isUrl && (!value.startsWith('http') && !value.startsWith('https'))) {
          return 'يرجى إدخال رابط صحيح يبدأ بـ http أو https';
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
      style: GoogleFonts.cairo(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'إضافة كتاب جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ساهم في إثراء المحتوى التعليمي. الكتب المضافة ستظهر لجميع الطلاب بعد المراجعة.',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildTextField(
                controller: _titleController,
                label: 'عنوان الكتاب',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _subjectController,
                label: 'المادة (اختياري)',
                icon: Icons.subject_rounded,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'المرحلة',
                      value: _selectedStage,
                      items: _stages,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStage = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: TextEditingController(text: _selectedGrade),
                      label: 'السنة',
                      icon: Icons.school_rounded,
                    ), // ملاحظة: يمكن تغييره ليصبح Dropdown ديناميكي حسب المرحلة
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildDropdown(
                label: 'التصنيف',
                value: _selectedCategory,
                items: _categories,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _urlController,
                label: 'رابط الكتاب (Google Drive المباشر)',
                icon: Icons.link_rounded,
                isUrl: true,
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ).copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.grey;
                    }
                    return null; // سيتم استخدام الـ Ink تحته
                  }),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: _isLoading ? null : AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    constraints: const BoxConstraints(minHeight: 50),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'إضافة الكتاب',
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
