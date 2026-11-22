import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/video_lesson_models.dart';

class VideoLessonCard extends StatelessWidget {
  final VideoLesson lesson;
  final String subjectName;
  final String? unitName;
  final bool isCompleted;
  final bool isFavorite;
  final bool isProUser;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const VideoLessonCard({
    super.key,
    required this.lesson,
    required this.subjectName,
    this.unitName,
    this.isCompleted = false,
    this.isFavorite = false,
    this.isProUser = false,
    required this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumb = lesson.effectiveThumbnailUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : lesson.isPro
                  ? const Color(0xFF0051D5).withValues(alpha: isDark ? 0.3 : 0.15)
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: isCompleted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. الصورة المصغرة والشارات
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (ctx, url, err) =>
                            _buildPlaceholderGraphic(isDark),
                      )
                    else
                      _buildPlaceholderGraphic(isDark),

                    // تدرج داكن خفيف فوق الصورة
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // زر التشغيل المركزي
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00236F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00236F).withValues(alpha: 0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    // شارة PRO أو مجاني في الزاوية اليمنى العليا
                    Positioned(
                      top: 10,
                      right: 10,
                      child: lesson.isPro
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003120),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF4AC08F).withValues(alpha: 0.4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 13,
                                    color: Color(0xFF85F8C4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PRO',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004A32),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: Color(0xFF85F8C4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'مجاني',
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // زر المفضلة في الزاوية اليسرى العليا
                    if (onFavoriteToggle != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onFavoriteToggle,
                            child: Padding(
                              padding: const EdgeInsets.all(7.5),
                              child: Icon(
                                isFavorite
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: isFavorite ? const Color(0xFF0051D5) : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // مدة الفيديو في الزاوية اليسرى السفلى
                    if (lesson.duration.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            lesson.duration,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                    // شارة مكتمل
                    if (isCompleted)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'مكتمل',
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. تفاصيل الدرس والبيانات التعليمية
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // التصنيف وعدد المشاهدات
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCE1FF).withValues(alpha: isDark ? 0.2 : 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subjectName,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF00236F),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: isDark ? Colors.white54 : const Color(0xFF757682),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lesson.viewsCount > 1000 ? '${(lesson.viewsCount / 1000).toStringAsFixed(1)}k' : lesson.viewsCount} مشاهدة',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : const Color(0xFF757682),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // عنوان الدرس
                    Text(
                      lesson.title,
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF191C1E),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 12),

                    // صف الأستاذ مع زر الإجراء
                    Row(
                      children: [
                        // صورة الأستاذ
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00236F).withValues(alpha: 0.1),
                            border: Border.all(
                              color: const Color(0xFF0051D5).withValues(alpha: 0.2),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: lesson.teacherPhotoUrl != null &&
                                  lesson.teacherPhotoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: lesson.teacherPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (ctx, url, err) => const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF00236F),
                                    size: 20,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF00236F),
                                  size: 20,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.teacherName ?? 'أستاذ مراجعي',
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF191C1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'خبير المادة',
                                style: GoogleFonts.cairo(
                                  fontSize: 10.5,
                                  color: isDark ? Colors.white54 : const Color(0xFF757682),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // زر الإجراء: ترقية Pro أو مشاهدة
                        if (lesson.isPro && !isProUser)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0051D5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ترقية Pro',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 15,
                                  color: Color(0xFF00236F),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'مشاهدة',
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFF00236F),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderGraphic(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF00236F),
            Color(0xFF1E3A8A),
            Color(0xFF0051D5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          size: 50,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
