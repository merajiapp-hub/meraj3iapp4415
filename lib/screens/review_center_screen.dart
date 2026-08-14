import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/books_data.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'books_list_screen.dart';
import 'exam_generator_screen.dart';

class ReviewCenterScreen extends StatefulWidget {
  const ReviewCenterScreen({super.key});

  @override
  State<ReviewCenterScreen> createState() => _ReviewCenterScreenState();
}

class _ReviewCenterScreenState extends State<ReviewCenterScreen> {
  String? _selectedStage;
  String? _selectedSection;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userData = auth.userData;
      if (userData != null) {
        setState(() {
          _selectedStage = userData['stage'];
          _selectedSection = userData['section'];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('مركز المراجعة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectionCard(isDark),
            const SizedBox(height: 24),
            if (_selectedStage != null && _selectedSection != null) ...[
              Text(
                'محتوى المراجعة الشامل',
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildCategoryGrid(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(bool isDark) {
    // Collect unique stages from BooksData
    final stages = BooksData.allBooks.map((e) => e.section).toSet().toList();
    final subjects = [
      'اللغة العربية', 'الرياضيات', 'العلوم الطبيعية', 'الفيزياء', 'التربية الإسلامية', 'التاريخ والجغرافيا', 'الفلسفة', 'الفرنسية', 'الإنجليزية'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedStage != null && stages.contains(_selectedStage) ? _selectedStage : null,
            decoration: InputDecoration(
              labelText: 'المرحلة الدراسية',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.cairo()))).toList(),
            onChanged: (val) => setState(() => _selectedStage = val),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedSubject != null && subjects.contains(_selectedSubject) ? _selectedSubject : null,
            decoration: InputDecoration(
              labelText: 'المادة',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.cairo()))).toList(),
            onChanged: (val) => setState(() => _selectedSubject = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCategoryCard(
          title: 'الكتب والدروس',
          icon: Icons.menu_book_rounded,
          color: Colors.blue,
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BooksListScreen(
                  stageTitle: _selectedStage ?? 'المراجعة',
                  section: _selectedSection ?? 'الكل',
                  categoryFilter: 'كتب مدرسية',
                  gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlue]),
                ),
              ),
            );
          },
        ),
        _buildCategoryCard(
          title: 'التمارين والملخصات',
          icon: Icons.edit_document,
          color: Colors.orange,
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BooksListScreen(
                  stageTitle: _selectedStage ?? 'المراجعة',
                  section: _selectedSection ?? 'الكل',
                  categoryFilter: 'ملخصات',
                  gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                ),
              ),
            );
          },
        ),
        _buildCategoryCard(
          title: 'الامتحانات السابقة',
          icon: Icons.history_edu,
          color: Colors.purple,
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BooksListScreen(
                  stageTitle: _selectedStage ?? 'المراجعة',
                  section: _selectedSection ?? 'الكل',
                  categoryFilter: 'امتحانات سابقة',
                  gradient: const LinearGradient(colors: [Colors.purple, Colors.deepPurple]),
                ),
              ),
            );
          },
        ),
        _buildCategoryCard(
          title: 'اختبارات ذكية',
          icon: Icons.quiz_rounded,
          color: Colors.teal,
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExamGeneratorScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
