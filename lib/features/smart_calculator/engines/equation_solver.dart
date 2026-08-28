import 'package:equations/equations.dart';

class EquationSolverEngine {
  /// Solves a linear equation of the form ax + b = 0
  static List<Complex> solveLinear(double a, double b) {
    final equation = Algebraic.fromReal([a, b]);
    return equation.solutions();
  }

  /// Solves a quadratic equation of the form ax^2 + bx + c = 0
  static List<Complex> solveQuadratic(double a, double b, double c) {
    final equation = Algebraic.fromReal([a, b, c]);
    return equation.solutions();
  }

  /// Solves a cubic equation of the form ax^3 + bx^2 + cx + d = 0
  static List<Complex> solveCubic(double a, double b, double c, double d) {
    final equation = Algebraic.fromReal([a, b, c, d]);
    return equation.solutions();
  }

  /// Evaluates an algebraic equation at a specific point
  static Complex evaluatePolynomial(List<double> coefficients, Complex x) {
    final equation = Algebraic.fromReal(coefficients);
    return equation.realEvaluateOn(x.real); // Simplified evaluation for real parts
  }
}
