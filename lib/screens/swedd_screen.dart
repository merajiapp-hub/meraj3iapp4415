import 'package:flutter/material.dart';

import '../data/books_data.dart';
import 'managed_book_sections_screen.dart';

class SweddScreen extends StatelessWidget {
  const SweddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagedBookSectionsScreen(
      section: BooksData.sSwedd,
      title: 'مشروع SWEDD',
      subtitle: 'اختر المستوى أو القسم لعرض كتبه فقط',
      icon: Icons.health_and_safety_rounded,
      stageName: 'SWEDD',
      formatGrade: _formatGrade,
    );
  }

  String _formatGrade(String grade) {
    switch (grade) {
      case 'الكل':
        return 'دليل عام للجميع';
      case '2':
        return 'السنة الثانية إعدادية';
      case '3':
        return 'السنة الثالثة إعدادية';
      case '4':
        return 'السنة الرابعة إعدادية';
      case '5':
        return 'السنة الخامسة ثانوية';
      case '6':
        return 'السنة السادسة ثانوية';
      case '7':
        return 'السنة السابعة ثانوية (الباكالوريا)';
      default:
        return grade;
    }
  }
}
