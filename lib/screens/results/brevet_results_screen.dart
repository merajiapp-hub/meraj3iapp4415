import 'package:flutter/material.dart';
import '../../services/results_service.dart';
import 'results_list_screen.dart';

class BrevetResultsScreen extends StatelessWidget {
  final String csvUrl;
  final String title;
  final Gradient? overrideGradient;
  final String? overrideEmoji;

  const BrevetResultsScreen({
    super.key,
    required this.csvUrl,
    required this.title,
    this.overrideGradient,
    this.overrideEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return ResultsListScreen(
      title: title,
      csvUrl: csvUrl,
      examType: ExamType.brevet,
      gradient: overrideGradient ??
          const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      emoji: overrideEmoji ?? '📚',
      passScore: 10,
      maxScore: 20,
      scoreLabel: 'المعدل',
    );
  }
}
