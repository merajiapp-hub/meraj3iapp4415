import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/features/smart_calculator/ui/screens/advanced_math_lab_screen.dart';

void main() {
  group('math lab number parsing', () {
    test('parses comma-separated coefficients', () {
      expect(parseMathLabNumbers('1, -3, 2'), [1, -3, 2]);
    });

    test('parses decimal commas when semicolons separate values', () {
      expect(parseMathLabNumbers('1,5; 2,5; -3,25'), [1.5, 2.5, -3.25]);
    });

    test('returns no values for empty input', () {
      expect(parseMathLabNumbers('  '), isEmpty);
    });
  });
}
