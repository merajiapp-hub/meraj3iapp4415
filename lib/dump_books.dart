// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'data/books_data.dart';

void main() {
  final books = BooksData.allBooks.map((b) => {
    'title': b.title,
    'subject': b.subject,
    'section': b.section,
    'stage': b.section,
    'grade': b.grade,
    'year': b.grade,
    'category': b.category,
    'type': b.category,
    'url': b.url,
    'pdfUrl': b.url,
    'driveUrl': b.url,
  }).toList();
  
  final jsonStr = jsonEncode(books);
  File('books_dump.json').writeAsStringSync(jsonStr);
  print('Dumped ${books.length} books to books_dump.json');
}
