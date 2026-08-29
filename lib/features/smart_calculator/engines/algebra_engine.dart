import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;

class AlgebraEngine {
  static final ContextModel _cm = ContextModel();

  static void setVariable(String name, double value) {
    _cm.bindVariable(Variable(name), Number(value));
  }
  
  static double getVariable(String name) {
    try {
      // ignore: deprecated_member_use
      return _cm.getExpression(name).evaluate(EvaluationType.REAL, _cm);
    } catch (_) {
      return 0.0;
    }
  }

  static void clearVariables() {
    _cm.bindVariable(Variable('x'), Number(0.0));
    _cm.bindVariable(Variable('y'), Number(0.0));
  }

  static String evaluateExpression(String expressionStr, {String angleMode = 'degree'}) {
    try {
      if (expressionStr.trim().isEmpty) return '';
      final normalized = _normalize(expressionStr, angleMode);
      final p = GrammarParser();
      final exp = p.parse(normalized);
      // ignore: deprecated_member_use
      final eval = exp.evaluate(EvaluationType.REAL, _cm).toDouble();
      return _formatResult(eval);
    } catch (_) {
      return _dartFallback(expressionStr, angleMode);
    }
  }

  static String differentiate(String expressionStr, String variable) {
    try {
      final normalized = expressionStr
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '${math.pi}')
          .replaceAll('e', '${math.e}');
      final p = GrammarParser();
      final exp = p.parse(normalized);
      return exp.derive(variable).toString();
    } catch (_) {
      throw Exception('Cannot differentiate');
    }
  }

  static String _normalize(String expressionStr, String angleMode) {
    String n = expressionStr
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', '(${math.pi})')
        .replaceAll('e', '(${math.e})')
        .replaceAll('√(', 'sqrt(')
        .replaceAll('√', 'sqrt(')
        .replaceAll('|x|', 'abs(x)')
        .replaceAll('abs(', 'abs(')
        .replaceAll('e^(', 'exp(');

    n = _expandFactorials(n);

    if (angleMode == 'degree') {
      n = _degToRadTrig(n);
    } else if (angleMode == 'gradian') {
      n = _gradToRadTrig(n);
    }

    n = n.replaceAllMapped(RegExp(r'(\d+|\)|\w)\s*\('), (m) {
      if (['sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'log', 'ln', 'sqrt', 'abs', 'exp'].contains(m.group(1))) {
        return m.group(0)!;
      }
      return '${m.group(1)}*(';
    });
    n = n.replaceAllMapped(RegExp(r'\)\s*(\d+|\w)'), (m) => ')*${m.group(1)}');
    n = n.replaceAll('log(', '(1/ln(10))*ln(');
    
    // Convert 2x to 2*x
    n = n.replaceAllMapped(RegExp(r'(\d+)([a-zA-Z])'), (m) {
      if (['sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'log', 'ln', 'sqrt', 'abs', 'exp', 'pi'].any((f) => m.group(2)!.startsWith(f))) {
        return m.group(0)!; // exclude functions
      }
      return '${m.group(1)}*${m.group(2)}';
    });

    return n;
  }

  static String _degToRadTrig(String expr) {
    const toRad = math.pi / 180;
    expr = _wrapTrigWithMultiplier(expr, 'sin', toRad);
    expr = _wrapTrigWithMultiplier(expr, 'cos', toRad);
    expr = _wrapTrigWithMultiplier(expr, 'tan', toRad);
    return expr;
  }

  static String _gradToRadTrig(String expr) {
    const toRad = math.pi / 200;
    expr = _wrapTrigWithMultiplier(expr, 'sin', toRad);
    expr = _wrapTrigWithMultiplier(expr, 'cos', toRad);
    expr = _wrapTrigWithMultiplier(expr, 'tan', toRad);
    return expr;
  }

  static String _wrapTrigWithMultiplier(String expr, String funcName, double mult) {
    final buf = StringBuffer();
    int i = 0;
    while (i < expr.length) {
      if (i + funcName.length < expr.length &&
          expr.substring(i, i + funcName.length) == funcName &&
          (i == 0 || !RegExp(r'[a-zA-Z]').hasMatch(expr[i - 1])) &&
          expr.length > i + funcName.length &&
          expr[i + funcName.length] == '(') {
        
        buf.write(funcName);
        buf.write('(');
        i += funcName.length + 1;
        int depth = 1;
        int start = i;
        while (i < expr.length && depth > 0) {
          if (expr[i] == '(') depth++;
          if (expr[i] == ')') depth--;
          if (depth > 0) i++;
        }
        final inner = expr.substring(start, i);
        buf.write('($inner)*($mult)');
        buf.write(')');
        i++;
      } else {
        buf.write(expr[i]);
        i++;
      }
    }
    return buf.toString();
  }

  static String _dartFallback(String expr, String angleMode) {
    final deg = angleMode == 'degree';
    final grad = angleMode == 'gradian';
    final toRad = deg ? math.pi / 180 : (grad ? math.pi / 200 : 1.0);
    final fromRad = deg ? 180 / math.pi : (grad ? 200 / math.pi : 1.0);
    
    final e = expr.trim().replaceAll('π', '${math.pi}').replaceAll('e', '${math.e}');
    
    final num = double.tryParse(e);
    if (num != null) return _formatResult(num);

    final patterns = <String, double Function(double)>{
      'sin': (v) => math.sin(v * toRad),
      'cos': (v) => math.cos(v * toRad),
      'tan': (v) => math.tan(v * toRad),
      'asin': (v) => math.asin(v) * fromRad,
      'acos': (v) => math.acos(v) * fromRad,
      'atan': (v) => math.atan(v) * fromRad,
      'log': (v) => math.log(v) / math.ln10,
      'ln': (v) => math.log(v),
      'sqrt': (v) => math.sqrt(v),
      'abs': (v) => v.abs(),
      'exp': (v) => math.exp(v),
    };

    for (final entry in patterns.entries) {
      final m = RegExp('^${entry.key}\\((.+)\\)\$').firstMatch(e);
      if (m != null) {
        final val = double.tryParse(m.group(1)!);
        if (val != null) return _formatResult(entry.value(val));
      }
    }

    throw Exception('Invalid Expression');
  }

  static String _expandFactorials(String expr) {
    return expr.replaceAllMapped(RegExp(r'(\d+|\([^)]+\))!'), (m) {
      try {
        final valStr = m.group(1)!;
        int n;
        if (valStr.startsWith('(')) {
           n = double.parse(evaluateExpression(valStr.substring(1, valStr.length - 1))).toInt();
        } else {
           n = int.parse(valStr);
        }
        if (n < 0 || n > 170) return m.group(0)!; // 170! is the max for double
        double result = 1.0;
        for (int i = 2; i <= n; i++) { result *= i; }
        return _formatResult(result);
      } catch (_) {
        return m.group(0)!;
      }
    });
  }

  static String _formatResult(double eval) {
    if (eval.isNaN) return 'غير معرف';
    if (eval.isInfinite) return eval > 0 ? '∞' : '-∞';
    if ((eval - eval.roundToDouble()).abs() < 1e-10) {
      return eval.round().toString();
    }
    String str = eval.toStringAsFixed(10);
    str = str.replaceAll(RegExp(r'0+$'), '');
    str = str.replaceAll(RegExp(r'\.$'), '');
    return str;
  }
}
