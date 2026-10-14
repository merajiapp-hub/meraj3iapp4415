import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/features/smart_calculator/ui/screens/conversions_screen.dart';
import 'package:meraj3i/features/smart_calculator/ui/screens/equation_solver_screen.dart';
import 'package:meraj3i/features/smart_calculator/ui/screens/graphing_screen.dart';
import 'package:meraj3i/features/smart_calculator/ui/screens/matrix_editor_screen.dart';

void main() {
  testWidgets('matrix editor builds without dropdown assertion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MatrixEditorScreen())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('المصفوفة A'), findsOneWidget);
  });

  testWidgets('conversions screen builds without dropdown assertion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ConversionsScreen())),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Longueur'), findsOneWidget);
  });

  testWidgets('graphing screen builds with the French input direction', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GraphingScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('f(x) = '), findsOneWidget);
  });

  testWidgets('equation solver screen builds with the French input direction', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EquationSolverScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('f = '), findsOneWidget);
  });
}
