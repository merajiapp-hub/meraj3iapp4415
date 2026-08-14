import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/books_data.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import 'books_library_screen.dart';

class SelectStageScreen extends StatelessWidget {
  const SelectStageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      BooksData.sPrimary,
      BooksData.sMiddle,
      BooksData.sHighSc,
      BooksData.sHighMath,
      BooksData.sHighLit,
      BooksData.sHighOrig,
      BooksData.sCompetitions,
      BooksData.sSwedd,
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'اختيار المرحلة الدراسية',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          final stage = stages[index];
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
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
                List<Book> filteredBooks = BooksData.allBooks
                    .where((b) => b.section == stage)
                    .toList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BooksLibraryScreen(stage: stage, books: filteredBooks),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
