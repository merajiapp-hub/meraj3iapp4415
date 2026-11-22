import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/experiment_model.dart';
import '../widgets/lab_webview/lab_webview.dart';
import 'experiment_quiz_page.dart';

class ExperimentViewerPage extends StatefulWidget {
  final ExperimentModel experiment;

  const ExperimentViewerPage({
    super.key,
    required this.experiment,
  });

  @override
  State<ExperimentViewerPage> createState() => _ExperimentViewerPageState();
}

class _ExperimentViewerPageState extends State<ExperimentViewerPage> {
  int _currentStepIndex = 0;
  bool _isStepsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final exp = widget.experiment;
    final steps = exp.steps;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1424),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exp.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'محاكاة ثلاثية الأبعاد تفاعلية نشطة',
                  style: GoogleFonts.tajawal(fontSize: 10.5, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Steps modal trigger
          if (steps.isNotEmpty)
            IconButton(
              tooltip: 'دليل الخطوات',
              icon: const Icon(Icons.format_list_numbered_rtl_rounded, color: Colors.white),
              onPressed: () => _openStepsBottomSheet(context),
            ),

          // Conclusion dialog
          IconButton(
            tooltip: 'الاستنتاج العلمي',
            icon: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF38BDF8)),
            onPressed: () => _showConclusionDialog(context),
          ),

          // Assessment quiz button
          if (exp.quizQuestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ExperimentQuizPage(experiment: exp),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.quiz_rounded, size: 16),
                label: Text(
                  'الاختبار التقييمي',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            // ── Fullscreen 3D Lab Simulation Canvas ─────────────────────────
            Positioned.fill(
              child: buildLabWebView(
                htmlPath: exp.htmlAssetPath,
                viewId: exp.id,
                onMessageReceived: (msg) {
                  debugPrint('[VirtualLab] Message: $msg');
                },
              ),
            ),

            // ── Floating Step Indicator Overlay ─────────────────────────────
            if (steps.isNotEmpty)
              Positioned(
                top: 16,
                right: 16,
                left: 16,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: exp.subjectColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'خطوة ${_currentStepIndex + 1} من ${steps.length}',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: exp.subjectColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          steps[_currentStepIndex].instruction,
                          maxLines: _isStepsExpanded ? 4 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 11.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isStepsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() => _isStepsExpanded = !_isStepsExpanded);
                        },
                      ),
                      if (_currentStepIndex < steps.length - 1)
                        IconButton(
                          tooltip: 'الخطوة التالية',
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF38BDF8), size: 16),
                          onPressed: () {
                            setState(() {
                              if (_currentStepIndex < steps.length - 1) _currentStepIndex++;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

            // ── Floating Action Button at Bottom Left (Quiz) ─────────────────
            if (exp.quizQuestions.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ExperimentQuizPage(experiment: exp),
                      ),
                    );
                  },
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  icon: const Icon(Icons.verified_rounded, size: 20),
                  label: Text(
                    'التقييم وإنهاء التجربة',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openStepsBottomSheet(BuildContext context) {
    final steps = widget.experiment.steps;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مراحل التجربة المخبرية',
                    style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final s = steps[idx];
                    final isCurrent = idx == _currentStepIndex;
                    return InkWell(
                      onTap: () {
                        setState(() => _currentStepIndex = idx);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF1E293B) : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF38BDF8) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: isCurrent ? const Color(0xFF38BDF8) : Colors.white24,
                              child: Text(
                                '${s.number}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.instruction,
                                    style: GoogleFonts.tajawal(fontSize: 11.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConclusionDialog(BuildContext context) {
    final exp = widget.experiment;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 24),
              const SizedBox(width: 8),
              Text(
                'الاستنتاج العلمي والقانون الفيزيائي',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exp.chemicalFormula != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      exp.chemicalFormula!,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                exp.conclusion.isNotEmpty
                    ? exp.conclusion
                    : 'خلال هذه التجربة الافتراضية، تم إثبات المفاهيم العلمية والقوانين الفيزيائية والكيميائية بدقة وتفاعل حي.',
                style: GoogleFonts.tajawal(fontSize: 13, color: Colors.white.withValues(alpha: 0.87), height: 1.55),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('حسناً، فهمت'),
            ),
          ],
        ),
      ),
    );
  }
}
