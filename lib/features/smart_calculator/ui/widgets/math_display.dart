import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathDisplay extends StatelessWidget {
  final String expression;
  final double fontSize;
  final Color? color;

  const MathDisplay({
    super.key,
    required this.expression,
    this.fontSize = 32,
    this.color,
  });

  String _convertToLatex(String exp) {
    // Basic conversion for visual LaTeX display
    String latex = exp
        .replaceAll('*', r'\times ')
        .replaceAll('×', r'\times ')
        .replaceAll('÷', r'\div ')
        .replaceAll('pi', r'\pi')
        .replaceAll('π', r'\pi');
    
    // Convert a/b to \frac{a}{b} (basic approach)
    if (latex.contains('/')) {
      var parts = latex.split('/');
      if (parts.length == 2) {
        latex = r'\frac{' + parts[0] + r'}{' + parts[1] + r'}';
      }
    }
    
    return latex;
  }

  @override
  Widget build(BuildContext context) {
    if (expression.isEmpty) return Text('0', style: TextStyle(fontSize: fontSize));

    return Math.tex(
      _convertToLatex(expression),
      textStyle: TextStyle(fontSize: fontSize, color: color ?? Colors.black),
      mathStyle: MathStyle.display,
    );
  }
}
