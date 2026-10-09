import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/exam_selection_utils.dart';
import '../data/quiz_models.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';
import 'exam_taking_screen.dart';
import 'my_exams_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  الشاشة الرئيسية: اختيار المسابقة → الشعبة → المادة → الفصل → الاختبار
// ─────────────────────────────────────────────────────────────────────────────

class PublishedExamsScreen extends StatefulWidget {
  const PublishedExamsScreen({super.key});

  @override
  State<PublishedExamsScreen> createState() => _PublishedExamsScreenState();
}

class _PublishedExamsScreenState extends State<PublishedExamsScreen> {
  String? _competition; // Concours | Brevet | Baccalauréat
  String? _stream; // 7D | 7C | 7LM | 7LO  (للبكالوريا فقط)
  String? _subject;

  static const _competitions = ExamSelectionUtils.competitions;
  static const _bacStreams = ExamSelectionUtils.bacStreams;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.watch<AuthProvider>().user?.uid;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          CurvedHeader(
            title: 'الاختبارات',
            subtitle: 'اختر المسابقة ثم المادة للبدء',
            gradient: AppTheme.primaryGradient,
            trailing: IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyExamsScreen()),
              ),
            ),
          ),
          Expanded(child: _buildBody(isDark, uid)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, String? uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('quizzes')
          .where('kind', isEqualTo: 'quiz')
          .where('status', isEqualTo: 'published')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString(), isDark);
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs
            .map((d) => {...d.data(), '_id': d.id})
            .toList();

        // استخراج المواد والفصول حسب الاختيارات
        final subjects = ExamSelectionUtils.subjectsFromDocs(
          docs,
          competition: _competition,
          stream: _competition == 'Baccalauréat' ? _stream : null,
        );

        // إعادة ضبط الاختيارات التابعة إذا لم تعد صالحة
        if (_subject != null && !subjects.contains(_subject)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _subject = null;
              });
            }
          });
        }

        // الاختبارات المطابقة للمادة والشابيتر المختارَين
        final allSubjectExams = _subject != null && _subject!.isNotEmpty
            ? docs.where((doc) {
                final comp = ExamSelectionUtils.normalizeCompetition(
                  (doc['competition'] ?? doc['examType'] ?? '').toString(),
                );
                if (_competition != null && comp != _competition) return false;
                if (_competition == 'Baccalauréat' && _stream != null) {
                  final docStream =
                      (doc['stream'] ?? doc['division'] ?? doc['section'] ?? '')
                          .toString()
                          .trim();
                  if (docStream != _stream) return false;
                }
                final docSubject = (doc['subject'] ?? doc['subjectId'] ?? '')
                    .toString()
                    .trim();
                if (docSubject != _subject) return false;
                return true;
              }).toList()
            : <Map<String, dynamic>>[];

        allSubjectExams.sort((a, b) {
          final orderComparison = _quizOrder(
            a['order'],
          ).compareTo(_quizOrder(b['order']));
          if (orderComparison != 0) return orderComparison;

          final titleComparison = (a['title'] ?? '').toString().compareTo(
            (b['title'] ?? '').toString(),
          );
          if (titleComparison != 0) return titleComparison;
          return (a['_id'] ?? '').toString().compareTo(
            (b['_id'] ?? '').toString(),
          );
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── اختيار المسابقة ──
            _CompetitionSelector(
              selected: _competition,
              competitions: _competitions,
              isDark: isDark,
              onChanged: (value) => setState(() {
                _competition = value;
                _stream = null;
                _subject = null;
              }),
            ),
            const SizedBox(height: 14),

            // ── اختيار الشعبة (للبكالوريا فقط) ──
            if (_competition == 'Baccalauréat') ...[
              _StreamSelector(
                selected: _stream,
                streams: _bacStreams,
                isDark: isDark,
                onChanged: (value) => setState(() {
                  _stream = value;
                  _subject = null;
                }),
              ),
              const SizedBox(height: 14),
            ],

            // ── اختيار المادة ──
            if (_competition != null &&
                (_competition != 'Baccalauréat' || _stream != null)) ...[
              _SubjectSelector(
                subjects: subjects,
                selected: _subject,
                isDark: isDark,
                onChanged: (value) => setState(() {
                  _subject = value;
                }),
              ),
              const SizedBox(height: 14),
            ],

            // ── قائمة الاختبارات (الشابيترات) ──
            if (_competition == null)
              _buildHint(
                'اختر نوع المسابقة للبدء',
                Icons.school_rounded,
                isDark,
              )
            else if (_competition == 'Baccalauréat' && _stream == null)
              _buildHint('اختر الشعبة', Icons.account_tree_rounded, isDark)
            else if (_subject == null)
              _buildHint(
                'اختر المادة لعرض الاختبارات',
                Icons.menu_book_rounded,
                isDark,
              )
            else if (allSubjectExams.isEmpty)
              _buildHint(
                'لا توجد شابيترات منشورة لهذه المادة حتى الآن',
                Icons.quiz_rounded,
                isDark,
              )
            else
              ...allSubjectExams.map(
                (data) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ExamCard(
                    data: data,
                    quizId: data['_id'].toString(),
                    isDark: isDark,
                    uid: uid,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  int _quizOrder(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 999999;
  }

  Widget _buildHint(String text, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 56, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white54 : Colors.black38,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل الاختبارات',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  اختيار المسابقة
// ─────────────────────────────────────────────────────────────────────────────

class _CompetitionSelector extends StatelessWidget {
  final String? selected;
  final List<String> competitions;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CompetitionSelector({
    required this.selected,
    required this.competitions,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.emoji_events_rounded,
      title: 'المسابقة',
      child: Column(
        children: competitions.map((comp) {
          final isSelected = comp == selected;
          return _CompTile(
            label: comp,
            subtitle: _subtitle(comp),
            icon: _icon(comp),
            color: _color(comp),
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => onChanged(comp),
          );
        }).toList(),
      ),
    );
  }

  String _subtitle(String comp) {
    switch (comp) {
      case 'Concours':
        return 'مسابقة دخول الإعدادية';
      case 'Brevet':
        return 'شهادة ختم الدروس الإعدادية';
      case 'Baccalauréat':
        return 'شهادة البكالوريا';
      default:
        return comp;
    }
  }

  IconData _icon(String comp) {
    switch (comp) {
      case 'Concours':
        return Icons.emoji_events_rounded;
      case 'Brevet':
        return Icons.menu_book_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  Color _color(String comp) {
    switch (comp) {
      case 'Concours':
        return AppTheme.primaryColor;
      case 'Brevet':
        return AppTheme.accentColor;
      default:
        return AppTheme.secondaryColor;
    }
  }
}

class _CompTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CompTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.10)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  اختيار الشعبة
// ─────────────────────────────────────────────────────────────────────────────

class _StreamSelector extends StatelessWidget {
  final String? selected;
  final List<String> streams;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _StreamSelector({
    required this.selected,
    required this.streams,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      icon: Icons.account_tree_rounded,
      title: 'الشعبة',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: streams.map((s) {
          final isSelected = s == selected;
          final color = AppTheme.accentColor;
          return GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                s,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  اختيار المادة
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectSelector extends StatelessWidget {
  final List<String> subjects;
  final String? selected;
  final bool isDark;
  final ValueChanged<String?> onChanged;

  const _SubjectSelector({
    required this.subjects,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return _SectionCard(
        isDark: isDark,
        icon: Icons.menu_book_rounded,
        title: 'المادة',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'لا توجد مواد لهذا الاختيار',
            style: GoogleFonts.cairo(color: Colors.grey),
          ),
        ),
      );
    }
    return _SectionCard(
      isDark: isDark,
      icon: Icons.menu_book_rounded,
      title: 'المادة',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: subjects.map((s) {
          final isSelected = s == selected;
          final color = AppTheme.primaryColor;
          return GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white12 : Colors.black12),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                s,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  بطاقة الاختبار
// ─────────────────────────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String quizId;
  final bool isDark;
  final String? uid;

  const _ExamCard({
    required this.data,
    required this.quizId,
    required this.isDark,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'اختبار';
    final subject = data['subject']?.toString() ?? '';
    final chapter = (data['chapter'] ?? data['chapterId'] ?? 'عام').toString();
    final totalQ = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final durationMin = (data['duration'] as num?)?.toInt() ?? 30;
    final difficulty = data['difficulty']?.toString() ?? '';
    final competition = ExamSelectionUtils.normalizeCompetition(
      (data['competition'] ?? data['examType'] ?? '').toString(),
    );
    final stream = (data['stream'] ?? data['division'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─ رأس البطاقة ─
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.12),
                  AppTheme.primaryColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.isNotEmpty ? chapter : title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge(label: competition, color: AppTheme.primaryColor),
                    if (stream.isNotEmpty && competition == 'Baccalauréat')
                      _Badge(label: stream, color: AppTheme.accentColor),
                    _Badge(label: subject, color: AppTheme.secondaryColor),
                  ],
                ),
              ],
            ),
          ),

          // ─ تفاصيل الاختبار ─
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.help_outline_rounded,
                      label: '$totalQ سؤال',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '$durationMin د',
                      isDark: isDark,
                    ),
                    if (difficulty.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _DifficultyBadge(difficulty: difficulty),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // زر الاختبار + إحصائيات المستخدم
                uid != null
                    ? _ExamActionButton(
                        quizId: quizId,
                        data: data,
                        uid: uid!,
                        isDark: isDark,
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _startExam(context, durationMin),
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          'ابدأ الاختبار',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startExam(BuildContext context, int durationMin) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .orderBy('order')
          .get();
      final questions = snap.docs
          .map((d) => QuizQuestion.fromMap(d.data(), d.id))
          .where((q) => q.question.trim().isNotEmpty && q.options.length >= 2)
          .toList();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الاختبار لا يحتوي على أسئلة مكتملة'),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamTakingScreen(
            quizId: quizId,
            quizTitle: data['title']?.toString() ?? 'اختبار',
            durationMinutes: durationMin,
            questions: questions,
            uid: uid,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الاختبار، حاول مرة أخرى')),
      );
    }
  }
}

// زر الاختبار مع إحصائيات من Firestore
class _ExamActionButton extends StatelessWidget {
  final String quizId;
  final Map<String, dynamic> data;
  final String uid;
  final bool isDark;

  const _ExamActionButton({
    required this.quizId,
    required this.data,
    required this.uid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('exam_attempts')
          .where('userId', isEqualTo: uid)
          .where('quizId', isEqualTo: quizId)
          .snapshots(),
      builder: (context, snap) {
        final attempts = snap.hasData
            ? snap.data!.docs
            : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        // أفضل نتيجة وآخر نتيجة
        int bestScore = 0;
        int lastScore = 0;
        int attemptCount = attempts.length;
        bool hasIncomplete = false;
        String? incompleteAttemptId;

        for (final doc in attempts) {
          final d = doc.data();
          final s = (d['score'] as num?)?.toInt() ?? 0;
          if (s > bestScore) bestScore = s;
          final status = d['status']?.toString() ?? 'completed';
          if (status == 'in_progress') {
            hasIncomplete = true;
            incompleteAttemptId = doc.id;
          }
        }
        if (attempts.isNotEmpty) {
          final last = attempts.last.data();
          lastScore = (last['score'] as num?)?.toInt() ?? 0;
        }

        final stars = ExamSelectionUtils.starsForScore(bestScore);
        final durationMin = (data['duration'] as num?)?.toInt() ?? 30;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // إحصائيات سابقة
            if (attemptCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(
                      label: 'المحاولات',
                      value: '$attemptCount',
                      isDark: isDark,
                    ),
                    _StatCol(
                      label: 'أفضل نتيجة',
                      value: '$bestScore%',
                      isDark: isDark,
                    ),
                    _StatCol(
                      label: 'آخر نتيجة',
                      value: '$lastScore%',
                      isDark: isDark,
                    ),
                    _StarsWidget(stars: stars),
                  ],
                ),
              ),
            ],

            // زر استكمال أو بدء
            if (hasIncomplete)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openExam(
                        context,
                        durationMin,
                        resumeAttemptId: incompleteAttemptId,
                      ),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(
                        'استكمال',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openExam(context, durationMin),
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        'إعادة',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () => _openExam(context, durationMin),
                icon: Icon(
                  attemptCount > 0
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  attemptCount > 0 ? 'إعادة الاختبار' : 'ابدأ الاختبار',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _openExam(
    BuildContext context,
    int durationMin, {
    String? resumeAttemptId,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .orderBy('order')
          .get();
      final questions = snap.docs
          .map((d) => QuizQuestion.fromMap(d.data(), d.id))
          .where((q) => q.question.trim().isNotEmpty && q.options.length >= 2)
          .toList();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذا الاختبار لا يحتوي على أسئلة مكتملة'),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExamTakingScreen(
            quizId: quizId,
            quizTitle: data['title']?.toString() ?? 'اختبار',
            durationMinutes: durationMin,
            questions: questions,
            uid: uid,
            resumeAttemptId: resumeAttemptId,
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الاختبار، حاول مرة أخرى')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets مساعدة
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white54 : Colors.black38,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case 'سهل':
        color = const Color(0xFF10B981);
        break;
      case 'صعب':
        color = Colors.orange;
        break;
      case 'متقدم':
        color = Colors.redAccent;
        break;
      default:
        color = const Color(0xFF0EA5E9);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatCol({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

class _StarsWidget extends StatelessWidget {
  final int stars;

  const _StarsWidget({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < stars ? Colors.amber : Colors.grey.shade400,
          size: 16,
        ),
      ),
    );
  }
}
