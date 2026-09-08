import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meraj3i/models/book.dart';
import 'package:meraj3i/providers/reading_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('switching accounts clears previous user reading sessions', () async {
    final provider = ReadingProvider();
    final book = const Book(
      id: 'book-1',
      title: 'كتاب تجريبي',
      section: 'الابتدائية',
      grade: 'السادس',
      category: 'كتب',
      subject: 'رياضيات',
      url: 'https://example.com/book.pdf',
    );

    await provider.updateUid('user-1');
    await provider.markAsCompleted(book);
    expect(provider.isRead(book.uniqueKey), isTrue);

    await provider.updateUid('user-2');

    expect(
      provider.sessions.any((s) => s.bookKey == book.uniqueKey),
      isFalse,
      reason: 'Sessions from a previous user should be cleared when the active account changes.',
    );
  });
}
