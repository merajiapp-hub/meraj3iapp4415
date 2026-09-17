import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/exam_selection_utils.dart';
import '../data/quiz_models.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import 'exam_taking_screen.dart';
import 'my_exams_screen.dart';

class PublishedExamsScreen extends StatefulWidget {
  const PublishedExamsScreen({super.key});

  @override
  State<PublishedExamsScreen> createState() => _PublishedExamsScreenState();
}

class _PublishedExamsScreenState extends State<PublishedExamsScreen> {
  String? _subject;
  String? _chapter;
  int _duration = 30;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          CurvedHeader(
            title: 'الاختبارات',
            subtitle: 'اختر المادة والشابيتر والمدة قبل البدء',
            gradient: AppTheme.primaryGradient,
            trailing: IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyExamsScreen()),
              ),
            ),
          ),
          Expanded(child: _buildSelection(isDark)),
        ],
      ),
    );
  }

  Widget _buildSelection(bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where('kind', isEqualTo: 'quiz')
          .where('status', isEqualTo: 'published')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('تعذر تحميل الاختبارات', style: GoogleFonts.cairo(color: Colors.red)));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = [...snapshot.data!.docs]
          ..sort((a, b) => ((a.data()['order'] ?? 0) as num).compareTo((b.data()['order'] ?? 0) as num));

        final docMaps = docs.map((doc) => doc.data()).toList();
        final subjects = ExamSelectionUtils.subjectsFromDocs(docMaps);

        final subjectDocs = _subject == null || _subject!.trim().isEmpty
            ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
            : docs.where((doc) => (doc.data()['subject'] ?? '').toString() == _subject).toList();

        final chapters = _subject == null || _subject!.trim().isEmpty
            ? <String>[]
            : ExamSelectionUtils.chaptersForSubject(docMaps, _subject!);

        if (_subject != null && _subject!.isNotEmpty && !subjects.contains(_subject)) {
          _subject = null;
        }

        if (_subject != null && _subject!.isNotEmpty && _chapter != null && !chapters.contains(_chapter)) {
          _chapter = null;
        }

        final selectedDocs = (_subject == null || _subject!.isEmpty || _chapter == null || _chapter!.isEmpty)
            ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
            : subjectDocs.where((doc) => ((doc.data()['chapter'] ?? doc.data()['section'] ?? 'عام') ?? '').toString() == _chapter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _SelectionPanel(
              isDark: isDark,
              subjects: subjects,
              chapters: chapters,
              subject: _subject,
              chapter: _chapter,
              duration: _duration,
              onSubjectChanged: (value) => setState(() {
                _subject = value;
                _chapter = null;
              }),
              onChapterChanged: (value) => setState(() => _chapter = value),
              onDurationChanged: (value) => setState(() => _duration = value),
            ),
            const SizedBox(height: 18),
            if (_subject == null || _subject!.isEmpty || _chapter == null || _chapter!.isEmpty)
              const _SelectionHint(text: 'اختر المادة ثم الشابيتر لعرض الاختبارات المتاحة.')
            else if (selectedDocs.isEmpty)
              const _SelectionHint(text: 'لا توجد اختبارات منشورة لهذا الاختيار.')
            else
              ...selectedDocs.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExamCard(data: {...doc.data(), 'selectedDuration': _duration}, quizId: doc.id, isDark: isDark),
                  )),
          ],
        );
      },
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  final bool isDark;
  final List<String> subjects;
  final List<String> chapters;
  final String? subject;
  final String? chapter;
  final int duration;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onChapterChanged;
  final ValueChanged<int> onDurationChanged;

  const _SelectionPanel({required this.isDark, required this.subjects, required this.chapters, required this.subject, required this.chapter, required this.duration, required this.onSubjectChanged, required this.onChapterChanged, required this.onDurationChanged});

  @override
  Widget build(BuildContext context) {
    final chapterItems = chapters.map((value) => DropdownMenuItem(value: value, child: Text(value, overflow: TextOverflow.ellipsis))).toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('اختر الاختبار', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: subject,
          isExpanded: true,
          itemHeight: 48,
          menuMaxHeight: 216,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          decoration: const InputDecoration(labelText: 'المادة', prefixIcon: Icon(Icons.menu_book_rounded)),
          items: subjects.map((value) => DropdownMenuItem(value: value, child: Text(value, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, maxLines: 1))).toList(),
          onChanged: onSubjectChanged,
          hint: const Text('اختر المادة'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: chapter,
          isExpanded: true,
          itemHeight: 48,
          menuMaxHeight: 216,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          decoration: const InputDecoration(labelText: 'الشابيتر / الفصل', prefixIcon: Icon(Icons.folder_open_rounded)),
          items: chapterItems,
          onChanged: (subject == null || subject!.trim().isEmpty) ? null : onChapterChanged,
          hint: const Text('اختر الشابيتر'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: duration,
          isExpanded: true,
          itemHeight: 48,
          menuMaxHeight: 216,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          decoration: const InputDecoration(labelText: 'مدة الاختبار بالدقائق', prefixIcon: Icon(Icons.timer_outlined)),
          items: [5, 10, 15, 20, 30, 45, 60].map((value) => DropdownMenuItem(value: value, child: Text('$value دقيقة', textAlign: TextAlign.right))).toList(),
          onChanged: (value) {
            if (value != null) onDurationChanged(value);
          },
        ),
        if (subject != null && subject!.isNotEmpty && chapter != null && chapter!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('المادة: $subject  •  الشابيتر: $chapter  •  المدة: $duration دقيقة', textAlign: TextAlign.center, style: GoogleFonts.cairo(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  final String text;
  const _SelectionHint({required this.text});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(28), child: Center(child: Text(text, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: Colors.grey))));
}

class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String quizId;
  final bool isDark;

  const _ExamCard({required this.data, required this.quizId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'اختبار';
    final subject = data['subject']?.toString() ?? '';
    final chapter = (data['chapter'] ?? data['section'] ?? 'عام').toString();
    final totalQ = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final duration = (data['selectedDuration'] as num?)?.toInt() ?? (data['duration'] as num?)?.toInt() ?? 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text('$subject  •  $chapter  •  $totalQ سؤال  •  $duration دقيقة', textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () => _openExam(context, duration),
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: Text('ابدأ الاختبار', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ]),
    );
  }

  Future<void> _openExam(BuildContext context, int duration) async {
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final snapshot = await FirebaseFirestore.instance.collection('quizzes').doc(quizId).collection('questions').orderBy('order').get();
      final questions = snapshot.docs.map((doc) => QuizQuestion.fromMap(doc.data(), doc.id)).where((q) => q.question.trim().isNotEmpty && q.options.length >= 2).toList();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الاختبار لا يحتوي على أسئلة مكتملة')));
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => ExamTakingScreen(quizId: quizId, quizTitle: data['title']?.toString() ?? 'اختبار', durationMinutes: duration, questions: questions)));
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الاختبار، حاول مرة أخرى')));
    }
  }
}
