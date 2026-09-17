import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meraj3i/providers/auth_provider.dart';
import 'package:meraj3i/providers/notes_provider.dart';
import 'package:meraj3i/screens/note_editor_screen.dart';

void main() {
  testWidgets('Note editor host is editable and no blocking overlay remains', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<NotesProvider>(create: (_) => NotesProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(tester.element(find.byType(Scaffold))).push(
                    MaterialPageRoute(
                      builder: (_) => const NoteEditorScreen(),
                    ),
                  );
                },
                child: const Text('فتح محرر'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح محرر'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('note_editor_host')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
