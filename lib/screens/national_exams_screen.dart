import 'package:flutter/material.dart';

import '../data/books_data.dart';
import 'managed_book_sections_screen.dart';

class NationalExamsScreen extends StatelessWidget {
  const NationalExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagedBookSectionsScreen(
      section: BooksData.sCompetitions,
      title: 'امتحانات المسابقات الوطنية',
      subtitle: 'اختر المسابقة لعرض الكتب التابعة لها',
      icon: Icons.emoji_events_rounded,
      stageName: 'امتحانات وطنية',
      formatGrade: _formatCompetition,
    );
  }

  String _formatCompetition(String grade) {
    final normalized = grade.toLowerCase();
    if (normalized.contains('concours')) {
      return 'كونكور ${grade.replaceFirst(RegExp(r'concours', caseSensitive: false), '').trim()}';
    }
    if (normalized.contains('brevet')) {
      return 'ابريفة ${grade.replaceFirst(RegExp(r'brevet', caseSensitive: false), '').trim()}';
    }
    if (normalized.contains('bac') || normalized.contains('baccalauréat')) {
      return 'البكالوريا ${grade.replaceFirst(RegExp(r'bac(calauréat)?', caseSensitive: false), '').trim()}';
    }
    return grade;
  }
}
