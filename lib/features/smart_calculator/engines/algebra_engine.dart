import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';

class AlgebraEngine {
  /// Evaluates a standard mathematical expression string.
  /// Returns a formatted String result.
  static String evaluateExpression(String expressionStr, {String angleMode = 'degree'}) {
    try {
      // Replace custom symbols to match standard math_expressions symbols
      String normalized = expressionStr
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('√', 'sqrt')
          .replaceAll('^', '^');

      // Handle factorial manually before parsing
      normalized = _expandFactorials(normalized);

      // Handle DEG conversion wrappers for trig functions
      if (angleMode == 'degree') {
        normalized = normalized
            .replaceAll('sin(', '_sindeg(')
            .replaceAll('cos(', '_cosdeg(')
            .replaceAll('tan(', '_tandeg(')
            .replaceAll('asin(', '_asindeg(')
            .replaceAll('acos(', '_acosdeg(')
            .replaceAll('atan(', '_atandeg(');
      }

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(normalized);

      ContextModel cm = ContextModel();

      double eval = RealEvaluator(cm).evaluate(exp).toDouble();
      return _formatResult(eval);
    } catch (_) {
      // Fallback — try dart:math directly for simple single-function expressions
      return _dartFallback(expressionStr, angleMode);
    }
  }

  /// Fallback evaluator using dart:math for simple expressions
  static String _dartFallback(String expr, String angleMode) {
    final deg = angleMode == 'degree';
    final toRad = math.pi / 180;

    // sin, cos, tan
    final sinMatch = RegExp(r'^sin\(([^)]+)\)$').firstMatch(expr.trim());
    if (sinMatch != null) {
      final val = double.tryParse(sinMatch.group(1)!.replaceAll('π', '${math.pi}'));
      if (val != null) return _formatResult(math.sin(deg ? val * toRad : val));
    }
    final cosMatch = RegExp(r'^cos\(([^)]+)\)$').firstMatch(expr.trim());
    if (cosMatch != null) {
      final val = double.tryParse(cosMatch.group(1)!.replaceAll('π', '${math.pi}'));
      if (val != null) return _formatResult(math.cos(deg ? val * toRad : val));
    }
    final tanMatch = RegExp(r'^tan\(([^)]+)\)$').firstMatch(expr.trim());
    if (tanMatch != null) {
      final val = double.tryParse(tanMatch.group(1)!.replaceAll('π', '${math.pi}'));
      if (val != null) return _formatResult(math.tan(deg ? val * toRad : val));
    }
    final logMatch = RegExp(r'^log\(([^)]+)\)$').firstMatch(expr.trim());
    if (logMatch != null) {
      final val = double.tryParse(logMatch.group(1)!);
      if (val != null) return _formatResult(math.log(val) / math.ln10);
    }
    final lnMatch = RegExp(r'^ln\(([^)]+)\)$').firstMatch(expr.trim());
    if (lnMatch != null) {
      final val = double.tryParse(lnMatch.group(1)!);
      if (val != null) return _formatResult(math.log(val));
    }
    final sqrtMatch = RegExp(r'^sqrt\(([^)]+)\)$').firstMatch(expr.trim());
    if (sqrtMatch != null) {
      final val = double.tryParse(sqrtMatch.group(1)!);
      if (val != null) return _formatResult(math.sqrt(val));
    }
    throw Exception('Invalid Expression');
  }

  static String _expandFactorials(String expr) {
    // Replace patterns like "n!" where n is a number
    return expr.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
      int n = int.parse(m.group(1)!);
      int result = 1;
      for (int i = 2; i <= n; i++) {
        result *= i;
      }
      return result.toString();
    });
  }

  static String _formatResult(double eval) {
    if (eval.isNaN) return 'غير معرف';
    if (eval.isInfinite) return eval > 0 ? '∞' : '-∞';
    if ((eval - eval.roundToDouble()).abs() < 1e-10) {
      return eval.round().toString();
    }
    return eval.toStringAsFixed(10)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  /// Differentiate an expression with respect to a variable (e.g., 'x')
  static String differentiate(String expressionStr, String variable) {
    try {
      String normalized = expressionStr
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(normalized);
      Expression derivative = exp.derive(variable);

      return derivative.toString();
    } catch (e) {
      throw Exception('Cannot differentiate expression');
    }
  }
}
