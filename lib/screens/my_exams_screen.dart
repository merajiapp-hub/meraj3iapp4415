import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

class MyExamsScreen extends StatelessWidget {
  const MyExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          const CurvedHeader(
            title: 'اختباراتي',
            gradient: AppTheme.brandGradient,
            leadingIcon: Icons.history_rounded,
          ),
          Expanded(
            child: uid == null
                ? _buildLoginRequired(isDark)
                : _buildAttemptsList(uid, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 72, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'يجب تسجيل الدخول أولاً',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsList(String uid, bool isDark) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('exam_attempts')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}',
                style: GoogleFonts.cairo(color: Colors.red)),
          );
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aTime = (a.data()['submittedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['submittedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
        if (docs.isEmpty) {
          return _buildEmpty(isDark);
        }

        // Summary stats
        final attempts = docs.map((d) => d.data()).toList();
        final avgScore = attempts.isEmpty
            ? 0
            : (attempts.fold<int>(
                    0, (acc, a) => acc + ((a['score'] as num?)?.toInt() ?? 0)) /
                attempts.length)
            .round();
        final bestScore = attempts.isEmpty
            ? 0
            : attempts.fold<int>(
                0,
                (best, a) =>
                    ((a['score'] as num?)?.toInt() ?? 0) > best
                        ? (a['score'] as num).toInt()
                        : best);

        return Column(
          children: [
            // Summary bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    label: 'إجمالي المحاولات',
                    value: '${attempts.length}',
                    icon: Icons.assignment_turned_in_rounded,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _SummaryItem(
                    label: 'متوسط النتيجة',
                    value: '$avgScore%',
                    icon: Icons.bar_chart_rounded,
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _SummaryItem(
                    label: 'أفضل نتيجة',
                    value: '$bestScore%',
                    icon: Icons.emoji_events_rounded,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  return _buildAttemptCard(data, isDark);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAttemptCard(Map<String, dynamic> data, bool isDark) {
    final score = (data['score'] as num?)?.toInt() ?? 0;
    final correct = (data['correctAnswers'] as num?)?.toInt() ?? 0;
    final wrong = (data['wrongAnswers'] as num?)?.toInt() ?? 0;
    final total = (data['totalQuestions'] as num?)?.toInt() ?? 0;
    final timeSecs = (data['timeTakenSeconds'] as num?)?.toInt() ?? 0;
    final title = data['quizTitle']?.toString() ?? 'اختبار';

    final m = (timeSecs ~/ 60).toString().padLeft(2, '0');
    final s = (timeSecs % 60).toString().padLeft(2, '0');
    final timeStr = '$m:$s';

    final submittedAt = data['submittedAt'];
    String dateStr = '';
    if (submittedAt is Timestamp) {
      final dt = submittedAt.toDate();
      dateStr =
          '${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }

    Color scoreColor;
    if (score >= 80) {
      scoreColor = const Color(0xFF10B981);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFF59E0B);
    } else {
      scoreColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.1),
              border: Border.all(color: scoreColor, width: 2),
            ),
            child: Center(
              child: Text(
                '$score%',
                style: GoogleFonts.outfit(
                  color: scoreColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
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
                  title,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  children: [
                    _MiniChip(
                      label: '✓ $correct',
                      color: const Color(0xFF10B981),
                    ),
                    _MiniChip(
                      label: '✗ $wrong',
                      color: const Color(0xFFEF4444),
                    ),
                    _MiniChip(
                      label: 'من $total',
                      color: const Color(0xFF6366F1),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 12, color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined,
                          size: 11,
                          color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 3),
                      Text(
                        dateStr,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined,
              size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'لم تخض أي اختبار بعد',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ اختبارك الأول من صفحة الاختبارات',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

