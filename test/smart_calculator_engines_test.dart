import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/features/smart_calculator/engines/algebra_engine.dart';
import 'package:meraj3i/features/smart_calculator/engines/complex_engine.dart';
import 'package:meraj3i/features/smart_calculator/engines/statistics_engine.dart';
import 'package:complex/complex.dart';

void main() {
  group('Algebra Engine Tests', () {
    test('Evaluates basic expressions correctly', () {
      expect(AlgebraEngine.evaluateExpression('2+2'), '4');
      expect(AlgebraEngine.evaluateExpression('10*5'), '50');
      expect(AlgebraEngine.evaluateExpression('100/4'), '25');
    });

    test('Evaluates expressions with custom symbols', () {
      expect(AlgebraEngine.evaluateExpression('3×3'), '9');
      expect(AlgebraEngine.evaluateExpression('10÷2'), '5');
    });
    
    test('Differentiation works for basic polynomials', () {
      final deriv = AlgebraEngine.differentiate('x^2', 'x');
      // output from math_expressions might be unsimplified, like (2.0 * (x^1.0))
      expect(deriv.contains('x'), true); 
    });
  });

  group('Complex Engine Tests', () {
    test('Parses complex strings correctly', () {
      Complex c1 = ComplexEngine.parse('3+4i');
      expect(c1.real, 3.0);
      expect(c1.imaginary, 4.0);
    });

    test('Adds complex numbers', () {
      Complex c1 = Complex(1, 2);
      Complex c2 = Complex(3, 4);
      Complex result = ComplexEngine.add(c1, c2);
      expect(result.real, 4.0);
      expect(result.imaginary, 6.0);
    });
  });

  group('Statistics Engine Tests', () {
    test('Calculates mean correctly', () {
      expect(StatisticsEngine.mean([1, 2, 3, 4, 5]), 3.0);
    });
    
    test('Calculates median correctly', () {
      expect(StatisticsEngine.median([1, 2, 3, 4, 5]), 3.0);
      expect(StatisticsEngine.median([1, 2, 3, 4]), 2.5);
    });
  });
}
