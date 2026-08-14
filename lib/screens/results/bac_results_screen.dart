import 'package:flutter/material.dart';
import '../../services/results_service.dart';
import 'results_list_screen.dart';

class BacResultsScreen extends StatelessWidget {
  final String csvUrl;
  final String title;

  const BacResultsScreen({
    super.key,
    required this.csvUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return ResultsListScreen(
      title: title,
      csvUrl: csvUrl,
      examType: ExamType.bac,
      gradient: const LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFB45309)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🎓',
      passScore: 10,
      maxScore: 20,
      scoreLabel: 'المعدل',
      showBranch: true,
    );
  }
}
