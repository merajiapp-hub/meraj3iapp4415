import 'package:math_expressions/math_expressions.dart';
import '../controllers/calculator_provider.dart';
import 'dart:math' as math;
import 'numerical_methods.dart';

class CalculatorEvaluator {
  final GrammarParser _parser = GrammarParser();

  String evaluate(String expression, {required AngleMode angleMode, required Map<String, double> variables}) {
    if (expression.isEmpty) return '';

    try {
      // 0. Process Numerical Integration and Differentiation first
      String processedExpression = _processCalculus(expression, variables, angleMode);
      
      // 1. Preprocess expression (replace symbols like ×, ÷ with *, /)
      processedExpression = _preprocess(processedExpression);

      // 2. Handle Angle Modes: wrap trig functions for DEG/GRAD
      String trigProcessed = _processTrigonometry(processedExpression, angleMode);

      // 3. Parse to AST
      Expression finalExp = _parser.parse(trigProcessed);

      // 4. Create context and bind variables
      ContextModel cm = ContextModel();
      variables.forEach((key, value) {
        cm.bindVariable(Variable(key), Number(value));
      });

      // 5. Evaluate using RealEvaluator
      final evaluator = RealEvaluator(cm);
      double evalResult = evaluator.evaluate(finalExp).toDouble();
      
      // 6. Format result
      return _formatResult(evalResult);

    } catch (e) {
      return 'Error';
    }
  }

  String _preprocess(String expr) {
    String result = expr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', math.pi.toString())
        .replaceAll('e', math.e.toString());
    
    // Convert implicit multiplication like 2(3) to 2*(3)
    result = result.replaceAllMapped(RegExp(r'(\d)\('), (match) => '${match.group(1)}*(');
    
    return result;
  }

  String _processTrigonometry(String expr, AngleMode mode) {
    if (mode == AngleMode.radian) return expr;
    
    double factor = 1.0;
    if (mode == AngleMode.degree) {
      factor = math.pi / 180.0;
    } else if (mode == AngleMode.gradian) {
      factor = math.pi / 200.0;
    }
    
    String result = expr;
    List<String> trigs = ['sin', 'cos', 'tan', 'asin', 'acos', 'atan'];
    for (String trig in trigs) {
      result = result.replaceAllMapped(RegExp('$trig\\(([^)]+)\\)'), (match) {
        String inner = match.group(1)!;
        return '$trig(($inner)*$factor)';
      });
    }
    
    return result;
  }

  String _processCalculus(String expr, Map<String, double> variables, AngleMode angleMode) {
    String result = expr;
    
    // Pattern for Integration: ∫(expr, lower, upper)
    final intRegex = RegExp(r'∫\(([^,]+),([^,]+),([^)]+)\)');
    result = result.replaceAllMapped(intRegex, (match) {
      String innerExp = match.group(1)!;
      double a = double.tryParse(match.group(2)!) ?? 0;
      double b = double.tryParse(match.group(3)!) ?? 0;
      double val = NumericalMethods.integrate(innerExp, a, b, variables: variables, angleMode: angleMode);
      return val.toString();
    });

    // Pattern for Differentiation: d/dx(expr, x_value)
    final diffRegex = RegExp(r'd/dx\(([^,]+),([^)]+)\)');
    result = result.replaceAllMapped(diffRegex, (match) {
      String innerExp = match.group(1)!;
      double xVal = double.tryParse(match.group(2)!) ?? 0;
      double val = NumericalMethods.differentiate(innerExp, xVal, variables: variables, angleMode: angleMode);
      return val.toString();
    });

    return result;
  }

  String _formatResult(double result) {
    if (result.isNaN || result.isInfinite) {
      return 'Error';
    }
    
    // Handle very small precision errors e.g., sin(180) != 0
    if (result.abs() < 1e-10) {
      return '0';
    }
    
    String resString = result.toString();
    if (resString.endsWith('.0')) {
      return resString.substring(0, resString.length - 2);
    }
    
    return resString;
  }
}
