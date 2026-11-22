import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/experiment_model.dart';
import '../pages/experiment_details_page.dart';

class ExperimentCard extends StatelessWidget {
  final ExperimentModel experiment;
  final bool isCompleted;
  final int? score;
  final bool isUserPro;

  const ExperimentCard({
    super.key,
    required this.experiment,
    this.isCompleted = false,
    this.score,
    this.isUserPro = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = experiment.isPro && !isUserPro;
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final borderCol = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ExperimentDetailsPage(
              experiment: experiment,
              isUserPro: isUserPro,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isLocked ? const Color(0xFFF59E0B).withValues(alpha: 0.5) : borderCol),
            width: isCompleted ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Graphic / Banner ──────────────────────────────────
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: experiment.isChemistry
                        ? [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF0F766E)]
                        : [const Color(0xFF1E3A8A), const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    // Watermark 3D Flask Icon in background
                    Positioned(
                      left: -15,
                      bottom: -20,
                      child: Icon(
                        experiment.subjectIcon,
                        size: 110,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),

                    // Top Row: Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Grade level badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            experiment.gradeLevels.join(' • '),
                            style: GoogleFonts.tajawal(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // 3D Simulation Badge & Pro Tag
                        Row(
                          children: [
                            if (experiment.isPro) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'PRO',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.view_in_ar_rounded, size: 13, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    '3D',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Completed status checkmark
                    if (isCompleted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                score != null ? 'مكتمل ($score%)' : 'مكتمل ✅',
                                style: GoogleFonts.tajawal(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Details Body ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Arabic Title
                    Text(
                      experiment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // French Subtitle
                    if (experiment.titleFr.isNotEmpty)
                      Text(
                        experiment.titleFr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Formula pill
                    if (experiment.chemicalFormula != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          experiment.chemicalFormula!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: experiment.subjectColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Bottom info: duration & difficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${experiment.durationMinutes} دقيقة',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            experiment.difficultyArabic,
                            style: GoogleFonts.tajawal(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
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
}
