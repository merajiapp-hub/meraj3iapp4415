import 'package:math_expressions/math_expressions.dart';
import '../controllers/calculator_provider.dart';

class NumericalMethods {
  static final GrammarParser _parser = GrammarParser();

  // Numerical Integration using Simpson's 1/3 Rule
  static double integrate(String expression, double a, double b, {int n = 100, required Map<String, double> variables, required AngleMode angleMode}) {
    if (n % 2 != 0) n++;
    
    double h = (b - a) / n;
    double sum = _evaluateAt(expression, a, variables) + _evaluateAt(expression, b, variables);
    
    for (int i = 1; i < n; i++) {
      double x = a + i * h;
      double fx = _evaluateAt(expression, x, variables);
      if (i % 2 == 0) {
        sum += 2 * fx;
      } else {
        sum += 4 * fx;
      }
    }
    
    return (h / 3) * sum;
  }

  // Numerical Differentiation using Central Difference
  static double differentiate(String expression, double x, {required Map<String, double> variables, required AngleMode angleMode}) {
    double h = 1e-5;
    
    double f1 = _evaluateAt(expression, x + h, variables);
    double f2 = _evaluateAt(expression, x - h, variables);
    
    return (f1 - f2) / (2 * h);
  }

  static double _evaluateAt(String expression, double xValue, Map<String, double> variables) {
    try {
      Expression exp = _parser.parse(expression);
      ContextModel cm = ContextModel();
      cm.bindVariable(Variable('x'), Number(xValue));
      
      variables.forEach((key, value) {
        if (key.toLowerCase() != 'x') {
          cm.bindVariable(Variable(key), Number(value));
        }
      });
      
      final evaluator = RealEvaluator(cm);
      return evaluator.evaluate(exp).toDouble();
    } catch (e) {
      return double.nan;
    }
  }
}
