import 'package:flutter/material.dart';
import '../../services/results_service.dart';
import 'results_list_screen.dart';

class ConcoursResultsScreen extends StatelessWidget {
  final String csvUrl;
  final String title;

  const ConcoursResultsScreen({
    super.key,
    required this.csvUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ResultsListScreen(
      title: title,
      csvUrl: csvUrl,
      examType: ExamType.concours,
      gradient: const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🏆',
      passScore: 85,
      maxScore: 200,
      scoreLabel: 'المجموع',
    );
  }
}
