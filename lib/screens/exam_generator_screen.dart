// screens/exam_generator_screen.dart — v5.1.0
// مولّد الاختبارات الذكي مع وضع الامتحان
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

class ExamGeneratorScreen extends StatefulWidget {
  const ExamGeneratorScreen({super.key});

  @override
  State<ExamGeneratorScreen> createState() => _ExamGeneratorScreenState();
}

class _ExamGeneratorScreenState extends State<ExamGeneratorScreen> {
  String? _selectedCategory;
  QuestionDifficulty? _selectedDifficulty;
  double _questionCount = 10;
  bool _examMode = false; // وضع الامتحان: لا تظهر الإجابة أثناء الاختبار
  int _timerSeconds = 30; // وقت كل سؤال

  static const List<String> _categories = [
    'رياضيات',
    'فيزياء',
    'كيمياء',
    'علوم طبيعية',
    'لغة عربية',
    'لغة فرنسية',
    'لغة إنجليزية',
    'تاريخ',
    'جغرافيا',
    'تربية إسلامية',
    'ثقافة عامة',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ─── AppBar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppTheme.backgroundDark : Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.quiz_rounded,
                            color: Colors.white, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'مولّد الاختبارات الذكي',
                          style: GoogleFonts.tajawal(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'خصّص اختبارك حسب المادة والصعوبة',
                          style: GoogleFonts.tajawal(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── اختيار المادة ─────────────────────────────
                  _buildSectionTitle('📚 اختر المادة', isDark),
                  const SizedBox(height: 12),
                  _buildCategoryGrid(isDark),
                  const SizedBox(height: 24),

                  // ─── مستوى الصعوبة ──────────────────────────────
                  _buildSectionTitle('⚡ مستوى الصعوبة', isDark),
                  const SizedBox(height: 12),
                  _buildDifficultyRow(isDark),
                  const SizedBox(height: 24),

                  // ─── عدد الأسئلة ────────────────────────────────
                  _buildSectionTitle('🔢 عدد الأسئلة: ${_questionCount.toInt()}', isDark),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryColor,
                      inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      thumbColor: AppTheme.primaryColor,
                      thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10),
                      overlayColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _questionCount,
                      min: 5,
                      max: 30,
                      divisions: 5,
                      onChanged: (v) => setState(() => _questionCount = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['5', '10', '15', '20', '25', '30']
                        .map((n) => Text(n,
                            style: GoogleFonts.outfit(
                                fontSize: 11, color: Colors.grey)))
                        .toList(),
                  ),
                  const SizedBox(height: 28),

                  // ─── وقت كل سؤال ──────────────────────────────
                  _buildSectionTitle('⏱ وقت كل سؤال: $_timerSeconds ثانية', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [15, 30, 45, 60, 90].map((sec) {
                      final isSelected = _timerSeconds == sec;
                      return GestureDetector(
                        onTap: () => setState(() => _timerSeconds = sec),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '$sec ث',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ─── وضع الامتحان ───────────────────────────────
                  _buildExamModeCard(isDark),
                  const SizedBox(height: 40),

                  // ─── زر البدء ───────────────────────────────────
                  _buildStartButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.tajawal(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // خيار "الكل"
        GestureDetector(
          onTap: () => setState(() => _selectedCategory = null),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedCategory == null
                  ? AppTheme.primaryColor
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCategory == null
                    ? AppTheme.primaryColor
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '🌐 كل المواد',
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: _selectedCategory == null ? Colors.white : null,
                fontSize: 13,
              ),
            ),
          ),
        ),
        ..._categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : null,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDifficultyRow(bool isDark) {
    const diffs = [
      (QuestionDifficulty.easy, 'سهل', Color(0xFF10B981)),
      (QuestionDifficulty.medium, 'متوسط', Color(0xFFF59E0B)),
      (QuestionDifficulty.hard, 'صعب', Color(0xFFEF4444)),
      (QuestionDifficulty.veryHard, 'متقدم', Color(0xFF8B5CF6)),
    ];
    return Row(
      children: [
        // "الكل"
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = null),
            child: Container(
              height: 52,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: _selectedDifficulty == null
                    ? AppTheme.primaryColor
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDifficulty == null
                      ? AppTheme.primaryColor
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  'كل المستويات',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color:
                        _selectedDifficulty == null ? Colors.white : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        ...diffs.map(((QuestionDifficulty, String, Color) d) {
          final isSelected = _selectedDifficulty == d.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDifficulty = d.$1),
              child: Container(
                height: 52,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? d.$3
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? d.$3 : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    d.$2,
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExamModeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: _examMode
            ? const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: _examMode
            ? null
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _examMode
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _examMode ? Colors.white.withValues(alpha: 0.15) : AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              color: _examMode ? Colors.white : AppTheme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وضع الامتحان 🎓',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _examMode ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لا تظهر الإجابة الصحيحة أثناء الاختبار. فقط اختر وانتقل!',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: _examMode ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _examMode,
            onChanged: (v) => setState(() => _examMode = v),
            activeThumbColor: _examMode ? Colors.white : AppTheme.primaryColor,
            activeTrackColor:
                _examMode ? Colors.white38 : AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final provider = Provider.of<QuizProvider>(context, listen: false);
        provider.generateNewQuiz(
          count: _questionCount.toInt(),
          category: _selectedCategory,
          difficulty: _selectedDifficulty,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(
              examMode: _examMode,
              timerSeconds: _examMode 
                  ? (_timerSeconds * _questionCount.toInt())
                  : _timerSeconds,
            ),
          ),
        );
      },
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_circle_filled_rounded,
                  color: Colors.white, size: 26),
              const SizedBox(width: 10),
              Text(
                _examMode ? 'ابدأ الامتحان الآن 🎓' : 'ابدأ الاختبار الآن',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

