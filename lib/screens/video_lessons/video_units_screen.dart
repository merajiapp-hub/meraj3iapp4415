import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/video_lesson_models.dart';
import '../../../services/video_lesson_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/curved_header.dart';
import 'video_lessons_list_screen.dart';

class VideoUnitsScreen extends StatelessWidget {
  final VideoLevel level;
  final VideoSubject subject;

  const VideoUnitsScreen({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = VideoLessonService();
    final subjectColor = Color(subject.colorHex);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // رأس الصفحة
          CurvedHeader(
            title: '${level.code} • ${subject.title}',
            subtitle: 'الوحدات التعليمية المعتمدة للمادة',
            gradient: LinearGradient(
              colors: [
                subjectColor,
                subjectColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),

          // قائمة الوحدات
          Expanded(
            child: StreamBuilder<List<VideoUnit>>(
              stream: service.streamUnits(subject.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final units = snapshot.data ?? [];
                if (units.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.layers_clear_rounded,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لم تتم إضافة وحدات لهذه المادة بعد',
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // زر للدخول المباشر للدروس
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: subjectColor,
                            ),
                            icon: const Icon(Icons.play_circle_filled_rounded),
                            label: const Text('عرض جميع الدروس مباشرة'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoLessonsListScreen(
                                    level: level,
                                    subject: subject,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: [
                    // بطاقة الدخول السريع لجميع الدروس
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            subjectColor.withValues(alpha: 0.15),
                            subjectColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: subjectColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: subjectColor,
                          child: const Icon(Icons.all_inclusive_rounded, color: Colors.white),
                        ),
                        title: Text(
                          'جميع دروس المادة',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'مشاهدة كافة الدروس والفيديوهات دون تقسيم وحدات',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_back_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoLessonsListScreen(
                                level: level,
                                subject: subject,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Text(
                        'قائمة الوحدات (${units.length})',
                        style: GoogleFonts.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...units.map((unit) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoLessonsListScreen(
                                    level: level,
                                    subject: subject,
                                    unit: unit,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: subjectColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${unit.orderIndex}',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: subjectColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unit.title,
                                          style: GoogleFonts.tajawal(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (unit.description.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            unit.description,
                                            style: GoogleFonts.tajawal(
                                              fontSize: 12,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: subjectColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_rounded, // RTL
                                      size: 16,
                                      color: subjectColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
