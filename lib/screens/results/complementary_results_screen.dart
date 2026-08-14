import 'package:flutter/material.dart';
import '../../services/results_service.dart';
import 'results_list_screen.dart';

class ComplementaryResultsScreen extends StatelessWidget {
  final String csvUrl;
  final String title;

  const ComplementaryResultsScreen({
    super.key,
    required this.csvUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ResultsListScreen(
      title: title,
      csvUrl: csvUrl,
      examType: ExamType.complementary,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🔄',
      passScore: 10,
      maxScore: 20,
      scoreLabel: 'المعدل',
      showBranch: true,
    );
  }
}
