import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';
import 'books_library_screen.dart';

class SelectStageScreen extends StatelessWidget {
  const SelectStageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'اختيار المرحلة الدراسية',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Book>>(
        stream: ContentService.watchBooksBySection(''),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل المراحل من الإدارة: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!;
          final stages = books.map((book) => book.section).toSet().toList()
            ..sort(_compareStages);
          if (stages.isEmpty) {
            return const Center(
              child: Text('لا توجد مراحل أو كتب متاحة حاليًا.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stages.length,
            itemBuilder: (context, index) {
              final stage = stages[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.school_rounded,
                      color: AppTheme.primaryColor,
                      size: 36,
                    ),
                  ),
                  title: Text(
                    stage,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    final stageBooks = books
                        .where((book) => book.section == stage)
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BooksLibraryScreen(stage: stage, books: stageBooks),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _compareStages(String a, String b) {
    int rank(String stage) {
      final value = stage.toLowerCase();
      if (value.contains('ابتدائي')) return 0;
      if (value.contains('إعدادي') || value.contains('اعدادي')) return 1;
      if (value.contains('ثانوي')) return 2;
      if (value.contains('امتحان') || value.contains('concours')) return 3;
      if (value.contains('swedd')) return 4;
      return 5;
    }

    final stageOrder = rank(a).compareTo(rank(b));
    return stageOrder != 0 ? stageOrder : a.compareTo(b);
  }
}
