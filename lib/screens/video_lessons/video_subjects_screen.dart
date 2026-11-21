import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/video_lesson_models.dart';
import '../../../services/video_lesson_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/responsive.dart';
import '../../../widgets/curved_header.dart';
import 'video_units_screen.dart';
import 'video_lessons_list_screen.dart';

class VideoSubjectsScreen extends StatelessWidget {
  final VideoLevel level;

  const VideoSubjectsScreen({super.key, required this.level});

  IconData _getSubjectIcon(String name) {
    switch (name) {
      case 'calculate':
        return Icons.calculate_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'biotech':
        return Icons.biotech_rounded;
      case 'menu_book':
        return Icons.menu_book_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'public':
        return Icons.public_rounded;
      case 'language':
        return Icons.language_rounded;
      case 'translate':
        return Icons.translate_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = VideoLessonService();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // رأس الصفحة
          CurvedHeader(
            title: level.title,
            subtitle: 'اختر المادة لمشاهدة الوحدات والدروس المصورة',
            gradient: LinearGradient(
              colors: [
                Color(level.colorHex),
                Color(level.colorHex).withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          // قائمة المواد التابعة لهذا القسم فقط
          Expanded(
            child: StreamBuilder<List<VideoSubject>>(
              stream: service.streamSubjects(level.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final subjects = snapshot.data ?? [];
                if (subjects.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.video_collection_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد مواد مضافة لهذا القسم حالياً',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يمكنك إضافة المواد وتفعيلها من لوحة الإدارة',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Text(
                              'المواد الدراسية',
                              style: GoogleFonts.tajawal(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${subjects.length} مواد متاحة',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: ResponsiveHelper.gridDelegate(
                          maxExtent: 320,
                          childAspectRatio: 1.35,
                          spacing: 14,
                        ),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return _buildSubjectCard(context, subject, isDark);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    VideoSubject subject,
    bool isDark,
  ) {
    final color = Color(subject.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // إذا كانت المادة مقسمة إلى وحدات (مثل السنة السادسة 6AF أو غيرها)
            if (subject.hasUnits) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoUnitsScreen(
                    level: level,
                    subject: subject,
                  ),
                ),
              );
            } else {
              // إذا كانت المادة تعرض الدروس مباشرة دون وحدات
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoLessonsListScreen(
                    level: level,
                    subject: subject,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSubjectIcon(subject.iconName),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subject.title,
                        style: GoogleFonts.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // شارة الوحدات أو الدروس المباشرة
                Row(
                  children: [
                    if (subject.hasUnits)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.layers_rounded, size: 13, color: color),
                            const SizedBox(width: 4),
                            Text(
                              'نظام الوحدات',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'دروس مباشرة',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_back_rounded, // RTL
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
