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
import '../widgets/banner_ad_widget.dart';
import 'exam_taking_screen.dart';
import 'my_exams_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  الشاشة الرئيسية: أزرار المسابقات المستقلة (Concours / Brevet / Baccalauréat)
// ─────────────────────────────────────────────────────────────────────────────

class PublishedExamsScreen extends StatelessWidget {
  const PublishedExamsScreen({super.key});

  static const _competitions = [
    _CompetitionData(
      key: 'Concours',
      title: 'مسابقة Concours',
      subtitle: 'مسابقة دخول الإعدادية',
      description: 'شابيترات واختبارات السنة السادسة ابتدائي',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF0B6B58),
      gradient: LinearGradient(
        colors: [Color(0xFF0B6B58), Color(0xFF14A085)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    _CompetitionData(
      key: 'Brevet',
      title: 'مسابقة Brevet',
      subtitle: 'شهادة ختم الدروس الإعدادية',
      description: 'شابيترات واختبارات السنة الرابعة إعدادية',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF0D7A66),
      gradient: LinearGradient(
        colors: [Color(0xFF0D7A66), Color(0xFF18B294)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    _CompetitionData(
      key: 'Baccalauréat',
      title: 'مسابقة البكالوريا',
      subtitle: 'شهادة البكالوريا',
      description: 'شابيترات واختبارات جميع الشعب العلمية والأدبية',
      icon: Icons.school_rounded,
      color: Color(0xFF083D2F),
      gradient: LinearGradient(
        colors: [Color(0xFF083D2F), Color(0xFF0B6B58)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          CurvedHeader(
            title: 'الاختبارات',
            subtitle: 'اختر المسابقة لإجراء الاختبارات',
            gradient: AppTheme.primaryGradient,
            showBackButton: Navigator.canPop(context),
            trailing: IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              tooltip: 'سجل اختباراتي',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyExamsScreen()),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('quizzes')
                  .where('kind', isEqualTo: 'quiz')
                  .where('status', isEqualTo: 'published')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.hasData
                    ? snapshot.data!.docs.map((d) => d.data()).toList()
                    : <Map<String, dynamic>>[];
                final totalQuizzes = docs.length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 4),
                      child: Text(
                        'المسابقات الوطنية المتاحة',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    ..._competitions.map((comp) {
                      final count = docs.where((d) {
                        final docComp = ExamSelectionUtils.normalizeCompetition(
                          (d['competition'] ?? d['examType'] ?? '').toString(),
                        );
                        return docComp == comp.key;
                      }).length;

                      return _CompetitionCard(
                        data: comp,
                        quizCount: count,
                        isDark: isDark,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompetitionChaptersScreen(
                                competition: comp.key,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                    const BannerAdWidget(),
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

// ─────────────────────────────────────────────────────────────────────────────
//  صفحة شابيترات واختبارات المسابقة المستقلة
// ─────────────────────────────────────────────────────────────────────────────

class CompetitionChaptersScreen extends StatefulWidget {
  final String competition;

  const CompetitionChaptersScreen({
    super.key,
    required this.competition,
  });

  @override
  State<CompetitionChaptersScreen> createState() =>
      _CompetitionChaptersScreenState();
}

class _CompetitionChaptersScreenState
    extends State<CompetitionChaptersScreen> {
  String? _stream; // للبكالوريا فقط: 7D | 7C | 7LM | 7LO
  String? _subject; // null أو 'الكل' يعني كل المواد
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const _bacStreams = ExamSelectionUtils.bacStreams;

  @override
  void initState() {
    super.initState();
    if (widget.competition == 'Baccalauréat') {
      _stream = '7D';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getSubtitle() {
    switch (widget.competition) {
      case 'Concours':
        return 'مسابقة دخول الإعدادية';
      case 'Brevet':
        return 'شهادة ختم الدروس الإعدادية';
      case 'Baccalauréat':
        return 'شهادة البكالوريا';
      default:
        return widget.competition;
    }
  }

  String _getTitle() {
    switch (widget.competition) {
      case 'Concours':
        return 'مسابقة Concours';
      case 'Brevet':
        return 'مسابقة Brevet';
      case 'Baccalauréat':
        return 'مسابقة البكالوريا';
      default:
        return 'مسابقة ${widget.competition}';
    }
  }

  Color _getAccentColor() {
    switch (widget.competition) {
      case 'Concours':
        return AppTheme.primaryColor;
      case 'Brevet':
        return const Color(0xFF0D7A66);
      default:
        return const Color(0xFF08483B);
    }
  }

  Gradient _getGradient() {
    switch (widget.competition) {
      case 'Concours':
        return const LinearGradient(
          colors: [Color(0xFF0B6B58), Color(0xFF14A085)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      case 'Brevet':
        return const LinearGradient(
          colors: [Color(0xFF0D7A66), Color(0xFF18B294)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF08483B), Color(0xFF0B6B58)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        );
    }
  }

  int _quizOrder(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 999999;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = context.watch<AuthProvider>().user?.uid;
    final accentColor = _getAccentColor();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF0F4F8),
      body: Column(
        children: [
          CurvedHeader(
            title: _getTitle(),
            subtitle: _getSubtitle(),
            gradient: _getGradient(),
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.history_rounded, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyExamsScreen()),
              ),
            ),
          ),
          Expanded(child: _buildBody(isDark, uid, accentColor)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, String? uid, Color accentColor) {
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

        // تصفية الاختبارات الخاصة بهذه المسابقة
        final compDocs = docs.where((doc) {
          final comp = ExamSelectionUtils.normalizeCompetition(
            (doc['competition'] ?? doc['examType'] ?? '').toString(),
          );
          return comp == widget.competition;
        }).toList();

        // إذا كانت المسابقة لا تحتوي على أي شابيترات أو أسئلة إطلاقاً
        if (compDocs.isEmpty) {
          return _buildEmptyState(
            title: 'لا توجد أسئلة أو اختبارات',
            message: 'لم يتم إضافة أي شابيترات أو أسئلة لمسابقة ${_getSubtitle()} حتى الآن.',
            color: accentColor,
            isDark: isDark,
          );
        }

        // استخراج المواد المتوفرة حسب المسابقة والشعبة
        final subjects = ExamSelectionUtils.subjectsFromDocs(
          compDocs,
          competition: widget.competition,
          stream: widget.competition == 'Baccalauréat' ? _stream : null,
        );

        // إعادة ضبط المادة إذا لم تعد موجودة في القائمة
        if (_subject != null && _subject != 'الكل' && !subjects.contains(_subject)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _subject = null;
              });
            }
          });
        }

        // تصفية الاختبارات حسب الشعبة والمادة والبحث
        final query = _searchQuery.trim().toLowerCase();
        final filteredExams = compDocs.where((doc) {
          if (widget.competition == 'Baccalauréat' && _stream != null) {
            final docStream =
                (doc['stream'] ?? doc['division'] ?? doc['section'] ?? '')
                    .toString()
                    .trim();
            if (docStream != _stream) return false;
          }
          if (_subject != null && _subject != 'الكل') {
            final docSubject = (doc['subject'] ?? doc['subjectId'] ?? '')
                .toString()
                .trim();
            if (docSubject != _subject) return false;
          }
          if (query.isNotEmpty) {
            final title = (doc['title'] ?? '').toString().toLowerCase();
            final chapter = (doc['chapter'] ?? doc['chapterId'] ?? '').toString().toLowerCase();
            final subject = (doc['subject'] ?? '').toString().toLowerCase();
            if (!title.contains(query) && !chapter.contains(query) && !subject.contains(query)) {
              return false;
            }
          }
          return true;
        }).toList();

        filteredExams.sort((a, b) {
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
            // ── اختيار الشعبة (للبكالوريا فقط) ──
            if (widget.competition == 'Baccalauréat') ...[
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

            // ── اختيار المادة (مع خيار الكل) ──
            if (subjects.isNotEmpty) ...[
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

            // ── حقل البحث في الشابيترات ──
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'ابحث عن اسم شابيتر أو درس...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // ── قائمة الشابيترات ──
            if (filteredExams.isEmpty)
              _buildEmptyState(
                title: 'لا توجد شابيترات متاحة',
                message: query.isNotEmpty
                    ? 'لا توجد نتائج تطابق بحثك "$_searchQuery".'
                    : 'لا توجد شابيترات أو أسئلة منشورة لهذا الاختيار حالياً.',
                color: accentColor,
                isDark: isDark,
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 4),
                child: Row(
                  children: [
                    Text(
                      'الشابيترات المتاحة (${filteredExams.length})',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              ...filteredExams.map(
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
          ],
        );
      },
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required Color color,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.quiz_outlined,
                size: 42,
                color: color,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
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
//  بيانات وبطاقة المسابقة المستقلة
// ─────────────────────────────────────────────────────────────────────────────

class _CompetitionData {
  final String key;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final Gradient gradient;

  const _CompetitionData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

class _CompetitionCard extends StatelessWidget {
  final _CompetitionData data;
  final int quizCount;
  final bool isDark;
  final VoidCallback onTap;

  const _CompetitionCard({
    required this.data,
    required this.quizCount,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : data.color.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: data.color.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: data.gradient,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            data.title,
                            style: GoogleFonts.cairo(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: data.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              quizCount > 0
                                  ? '$quizCount ${quizCount == 1 ? 'شابيتر' : 'شابيترات'}'
                                  : 'لا توجد أسئلة بعد',
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: data.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        data.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: data.color,
                        ),
                      ),
                      Text(
                        data.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
    final displayList = subjects.length > 1 ? ['الكل', ...subjects] : subjects;
    return _SectionCard(
      isDark: isDark,
      icon: Icons.menu_book_rounded,
      title: 'المادة',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: displayList.map((s) {
          final isAll = s == 'الكل';
          final isSelected = isAll
              ? (selected == null || selected == 'الكل')
              : (selected == s);
          final color = AppTheme.primaryColor;
          return GestureDetector(
            onTap: () => onChanged(isAll ? null : s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
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
                  fontSize: 13,
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─ رأس البطاقة ─
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.10),
                  AppTheme.primaryColor.withValues(alpha: 0.03),
                ],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.isNotEmpty ? chapter : title,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 5,
                  runSpacing: 3,
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
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.help_outline_rounded,
                      label: '$totalQ سؤال',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 5),
                    _InfoChip(
                      icon: Icons.timer_outlined,
                      label: '$durationMin د',
                      isDark: isDark,
                    ),
                    if (difficulty.isNotEmpty) ...[
                      const SizedBox(width: 5),
                      _DifficultyBadge(difficulty: difficulty),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // زر الاختبار + إحصائيات المستخدم
                uid != null
                    ? _ExamActionButton(
                        quizId: quizId,
                        data: data,
                        uid: uid!,
                        isDark: isDark,
                      )
                    : _PrimaryExamButton(
                        onPressed: () => _startExam(context, durationMin),
                        icon: Icons.play_arrow_rounded,
                        label: 'ابدأ الاختبار',
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
                padding: const EdgeInsets.all(9),
                margin: const EdgeInsets.only(bottom: 8),
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
                    child: _ResumeExamButton(
                      onPressed: () => _openExam(
                        context,
                        durationMin,
                        resumeAttemptId: incompleteAttemptId,
                      ),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrimaryExamButton(
                      onPressed: () => _openExam(context, durationMin),
                      icon: Icons.play_arrow_rounded,
                      label: 'إعادة',
                    ),
                  ),
                ],
              )
            else
              _PrimaryExamButton(
                onPressed: () => _openExam(context, durationMin),
                icon: attemptCount > 0
                    ? Icons.replay_rounded
                    : Icons.play_arrow_rounded,
                label: attemptCount > 0 ? 'إعادة الاختبار' : 'ابدأ الاختبار',
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 9.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
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

// ─────────────────────────────────────────────────────────────────────────────
//  أزرار الاختبارات الموحدة والمستوحاة من ألوان الشعار
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryExamButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _PrimaryExamButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumeExamButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;

  const _ResumeExamButton({
    required this.onPressed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.replay_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'استكمال',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
