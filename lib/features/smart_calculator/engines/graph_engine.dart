import 'package:math_expressions/math_expressions.dart';

class GraphPoint {
  final double x;
  final double y;
  GraphPoint(this.x, this.y);
}

class GraphEngine {
  /// Generates a list of (x, y) points for a given equation y = f(x).
  /// [expression] is the function string (e.g. "x^2 + 2*x")
  /// [minX] and [maxX] define the domain.
  /// [steps] determines the resolution of the graph.
  static List<GraphPoint> generatePoints(String expression, {double minX = -10, double maxX = 10, int steps = 200}) {
    List<GraphPoint> points = [];
    try {
      GrammarParser p = GrammarParser();
      String normalized = expression.replaceAll('×', '*').replaceAll('÷', '/').replaceAll('π', 'pi');
      Expression exp = p.parse(normalized);
      ContextModel cm = ContextModel();
      
      double stepSize = (maxX - minX) / steps;
      
      for (int i = 0; i <= steps; i++) {
        double x = minX + (i * stepSize);
        cm.bindVariable(Variable('x'), Number(x));
        double y = RealEvaluator(cm).evaluate(exp).toDouble();
        
        // Handle asymptotes and infinities gracefully
        if (y.isFinite) {
           points.add(GraphPoint(x, y));
        } else {
           // Skip infinite points to avoid breaking the chart
        }
      }
    } catch (e) {
      throw Exception('تعذر رسم الدالة، يرجى التأكد من صحة الصيغة الرياضية.');
    }
    return points;
  }
}
