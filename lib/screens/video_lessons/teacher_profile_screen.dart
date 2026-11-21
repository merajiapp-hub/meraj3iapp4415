import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video_lesson_models.dart';
import '../../../services/video_lesson_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/curved_header.dart';
import 'widgets/video_lesson_card.dart';
import 'video_player_screen.dart';

class TeacherProfileScreen extends StatelessWidget {
  final VideoTeacher teacher;

  const TeacherProfileScreen({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = VideoLessonService();
    final photo = teacher.effectivePhotoUrl;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // رأس الصفحة
          CurvedHeader(
            title: teacher.name,
            subtitle: teacher.specialty.isNotEmpty ? teacher.specialty : 'أستاذ محاضر',
            gradient: AppTheme.brandGradient,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة الملف التعريفي للأستاذ
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الصورة الشخصية للأستاذ
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photo.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: photo,
                                    fit: BoxFit.cover,
                                    errorWidget: (ctx, url, err) => _fallbackAvatar(),
                                  )
                                : _fallbackAvatar(),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // معلومات الأستاذ والنبذة
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                teacher.name,
                                style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              if (teacher.specialty.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    teacher.specialty,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                              if (teacher.bio.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  teacher.bio,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // عنوان قائمة الدروس
                  Row(
                    children: [
                      const Icon(Icons.video_library_rounded, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'دروس وشروحات الأستاذ',
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // بث دروس الأستاذ
                  StreamBuilder<List<VideoLesson>>(
                    stream: service.streamLessonsByTeacher(teacher.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final lessons = snapshot.data ?? [];
                      if (lessons.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'لم يتم ربط دروس بهذا الأستاذ بعد',
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = lessons[index];
                          return VideoLessonCard(
                            lesson: lesson,
                            subjectName: teacher.specialty,
                            onTap: () {
                              final dummyLevel = VideoLevel(id: lesson.levelId, title: '', code: '', description: '');
                              final dummySubject = VideoSubject(id: lesson.subjectId, levelId: '', title: teacher.specialty);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                    lesson: lesson,
                                    subject: dummySubject,
                                    level: dummyLevel,
                                    playlist: lessons,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      color: const Color(0xFF14B8A6),
      child: const Center(
        child: Icon(Icons.person_rounded, color: Colors.white, size: 40),
      ),
    );
  }
}
