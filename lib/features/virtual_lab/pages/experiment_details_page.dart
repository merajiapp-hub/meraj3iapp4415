import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/experiment_model.dart';
import 'experiment_viewer_page.dart';

class ExperimentDetailsPage extends StatelessWidget {
  final ExperimentModel experiment;
  final bool isUserPro;

  const ExperimentDetailsPage({
    super.key,
    required this.experiment,
    this.isUserPro = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF090E17) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final isLocked = experiment.isPro && !isUserPro;

    return Scaffold(
      backgroundColor: bg,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Sliver App Bar with Gradient Header ──────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF090E17) : const Color(0xFF1E293B),
              leading: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: experiment.isChemistry
                          ? [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF0F766E)]
                          : [const Color(0xFF1E3A8A), const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -20,
                        bottom: -20,
                        child: Icon(
                          experiment.subjectIcon,
                          size: 180,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black38,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'المختبر الافتراضي • ${experiment.subjectArabicName}',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.view_in_ar_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          'محاكاة تفاعلية 3D',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                experiment.title,
                                style: GoogleFonts.tajawal(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              if (experiment.titleFr.isNotEmpty)
                                Text(
                                  experiment.titleFr,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Content Sections ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview stats bar
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('المدة التقديرية', '${experiment.durationMinutes} دقيقة', Icons.timer_rounded, isDark),
                          _buildStatItem('المستوى التعليمي', experiment.gradeLevels.first, Icons.school_rounded, isDark),
                          _buildStatItem('درجة الصعوبة', experiment.difficultyArabic, Icons.speed_rounded, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Chemical formula / Law equation banner
                    if (experiment.chemicalFormula != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: experiment.subjectColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المعادلة الكيميائية / القانون العلمي:',
                              style: GoogleFonts.tajawal(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                experiment.chemicalFormula!,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: experiment.subjectColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    _buildSectionHeader('نظرة عامة على التجربة', Icons.info_outline_rounded, isDark),
                    const SizedBox(height: 8),
                    Text(
                      experiment.description,
                      style: GoogleFonts.tajawal(
                        fontSize: 13.5,
                        height: 1.6,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Pedagogical Objectives
                    if (experiment.objectives.isNotEmpty) ...[
                      _buildSectionHeader('الأهداف التعليمية والبيداغوجية', Icons.track_changes_rounded, isDark),
                      const SizedBox(height: 10),
                      ...experiment.objectives.map(
                        (obj) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  obj,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 13,
                                    color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Required Equipment
                    if (experiment.equipment.isNotEmpty) ...[
                      _buildSectionHeader('الأجهزة والأدوات المخبرية 3D', Icons.science_rounded, isDark),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: experiment.equipment
                              .map(
                                (eq) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: experiment.subjectColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          eq,
                                          style: GoogleFonts.tajawal(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // Safety Tips
                    if (experiment.safetyTips.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: isDark ? 0.1 : 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'إرشادات السلامة والوقاية المخبرية:',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...experiment.safetyTips.map(
                              (tip) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  '• $tip',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Start Simulation Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isLocked) {
                            _showProRequiredDialog(context);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => ExperimentViewerPage(
                                  experiment: experiment,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLocked ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: (isLocked ? const Color(0xFFF59E0B) : const Color(0xFF2563EB))
                              .withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isLocked ? 'فتح التجربة عبر اشتراك Pro' : 'بدء المحاكاة التفاعلية 3D',
                              style: GoogleFonts.tajawal(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: experiment.subjectColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: experiment.subjectColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 10.5,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showProRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 26),
            const SizedBox(width: 8),
            Text('عضوية Pro مطلوبة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هذه التجربة ثلاثية الأبعاد المتقدمة مخصصة لمشتركي باقة مراجعي Pro. اشترك الآن للاستمتاع بجميع التجارب المخبرية دون قيود!',
          style: GoogleFonts.tajawal(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقاً')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/pro');
            },
            child: const Text('ترقية إلى Pro'),
          ),
        ],
      ),
    );
  }
}
