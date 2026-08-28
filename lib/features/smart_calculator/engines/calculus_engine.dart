import 'package:math_expressions/math_expressions.dart';

class CalculusEngine {
  /// Computes the first derivative of [expression] with respect to [variable].
  static String differentiate(String expression, String variable) {
    try {
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(_normalize(expression));
      Expression derivative = exp.derive(variable);
      return derivative.toString();
    } catch (e) {
      throw Exception('لا يمكن حساب المشتقة: يرجى التحقق من صحة الدالة.');
    }
  }

  /// Evaluates the definite integral of [expression] with respect to [variable] 
  /// from [lowerBound] to [upperBound] using Simpson's 1/3 rule.
  static double integrate(String expression, String variable, double lowerBound, double upperBound, {int intervals = 1000}) {
    if (intervals % 2 != 0) intervals++; // Simpson's rule requires an even number of intervals
    
    try {
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(_normalize(expression));
      ContextModel cm = ContextModel();

      double h = (upperBound - lowerBound) / intervals;
      double sum = _evaluateAt(exp, cm, variable, lowerBound) + _evaluateAt(exp, cm, variable, upperBound);

      for (int i = 1; i < intervals; i++) {
        double x = lowerBound + i * h;
        double val = _evaluateAt(exp, cm, variable, x);
        if (i % 2 == 0) {
          sum += 2 * val;
        } else {
          sum += 4 * val;
        }
      }

      return (h / 3) * sum;
    } catch (e) {
      throw Exception('لا يمكن حساب التكامل: تأكد من صحة الدالة ونطاق التكامل.');
    }
  }

  static double _evaluateAt(Expression exp, ContextModel cm, String variable, double value) {
    cm.bindVariable(Variable(variable), Number(value));
    return RealEvaluator(cm).evaluate(exp).toDouble();
  }

  static String _normalize(String exp) {
    return exp.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('π', 'pi');
  }
}
