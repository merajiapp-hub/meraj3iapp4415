import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/quiz_models.dart';
import '../providers/quiz_provider.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

class PublishedExamsScreen extends StatelessWidget {
  const PublishedExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('الاختبارات المنشورة')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
          .where('kind', isEqualTo: 'quiz')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('تعذر تحميل الاختبارات: ${snapshot.error}'));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return data['status'] == 'published' && data['isActive'] == true;
          }).toList()
            ..sort((a, b) => ((a.data()['order'] ?? 0) as num).compareTo((b.data()['order'] ?? 0) as num));
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد اختبارات منشورة حالياً'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: const Icon(Icons.assignment_rounded, color: AppTheme.primaryColor),
                  ),
                  title: Text(data['title']?.toString() ?? 'اختبار'),
                  subtitle: Text('${data['subject'] ?? 'عام'}  |  ${data['difficulty'] ?? 'متوسط'}  |  ${data['totalQuestions'] ?? 0} سؤال  |  ${data['duration'] ?? 0} دقيقة'),
                  trailing: const Icon(Icons.chevron_left_rounded),
                  onTap: () => _openQuiz(context, docs[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openQuiz(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> quiz) async {
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final snapshot = await quiz.reference.collection('questions').orderBy('order').get();
      final questions = snapshot.docs
          .map((doc) => QuizQuestion.fromMap(doc.data(), doc.id))
          .where((question) => question.question.trim().isNotEmpty && question.options.length >= 2)
          .toList();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا الاختبار لا يحتوي على أسئلة مكتملة')));
        return;
      }
      context.read<QuizProvider>().startPublishedQuiz(questions);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen(examMode: true)));
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح الاختبار: $error')));
    }
  }
}
