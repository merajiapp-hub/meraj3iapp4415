import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';

class GraphPoint {
  final double x;
  final double y;
  GraphPoint(this.x, this.y);
}

class GraphEngine {
  /// Generates a list of (x, y) points for a given equation y = f(x).
  static List<GraphPoint> generatePoints(String expression,
      {double minX = -10, double maxX = 10, int steps = 400}) {
    List<GraphPoint> points = [];
    try {
      String normalized = _normalize(expression);
      GrammarParser p = GrammarParser();
      Expression exp = p.parse(normalized);
      ContextModel cm = ContextModel();

      double stepSize = (maxX - minX) / steps;

      double? prevY;
      for (int i = 0; i <= steps; i++) {
        double x = minX + (i * stepSize);
        cm.bindVariable(Variable('x'), Number(x));
        try {
          double y = RealEvaluator(cm).evaluate(exp).toDouble();
          if (y.isFinite && !y.isNaN) {
            // Detect asymptote (large jump) — break the line
            if (prevY != null && (y - prevY).abs() > 50) {
              points.add(GraphPoint(x, double.nan));
            }
            points.add(GraphPoint(x, y.clamp(-1000, 1000)));
            prevY = y;
          } else {
            prevY = null;
          }
        } catch (_) {
          prevY = null;
        }
      }
    } catch (e) {
      throw Exception('تعذر رسم الدالة، يرجى التأكد من صحة الصيغة الرياضية.');
    }
    return points;
  }

  static String _normalize(String expression) {
    String n = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('π', '(${math.pi})')
        .replaceAll('e', '(${math.e})')
        .replaceAll('√', 'sqrt')
        .replaceAll('|', 'abs');

    // Implicit multiplication: 2x → 2*x, x(... → x*(..., )(... → )*(
    n = n.replaceAllMapped(RegExp(r'(\d+)\s*(x|sin|cos|tan|log|ln|sqrt|abs)'), (m) {
      return '${m.group(1)}*${m.group(2)}';
    });
    n = n.replaceAllMapped(RegExp(r'(x|\d+|\))\s*\('), (m) {
      return '${m.group(1)}*(';
    });
    n = n.replaceAllMapped(RegExp(r'\)\s*(\d+|x)'), (m) {
      return ')*${m.group(1)}';
    });

    // log base 10 conversion: log(x) → (1/ln(10))*ln(x)
    n = n.replaceAll('log(', '(1/ln(10))*ln(');

    return n;
  }
}
