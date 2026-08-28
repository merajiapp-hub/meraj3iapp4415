import 'package:flutter/material.dart';

enum SmartCalculatorThemeStyle {
  modernDark,
  modernLight,
  scientificBlue,
  amoled
}

class SmartCalculatorTheme {
  final Color backgroundColor;
  final Color displayColor;
  final Color operatorColor;
  final Color numberColor;
  final Color functionColor;
  final Color textColor;
  final Color actionColor;

  const SmartCalculatorTheme({
    required this.backgroundColor,
    required this.displayColor,
    required this.operatorColor,
    required this.numberColor,
    required this.functionColor,
    required this.textColor,
    required this.actionColor,
  });

  static SmartCalculatorTheme getTheme(SmartCalculatorThemeStyle style) {
    switch (style) {
      case SmartCalculatorThemeStyle.modernDark:
        return const SmartCalculatorTheme(
          backgroundColor: Color(0xFF1E1E1E),
          displayColor: Color(0xFF2D2D2D),
          operatorColor: Color(0xFF3B82F6),
          numberColor: Color(0xFF333333),
          functionColor: Color(0xFF424242),
          textColor: Colors.white,
          actionColor: Color(0xFFEF4444), // e.g. for AC
        );
      case SmartCalculatorThemeStyle.modernLight:
        return const SmartCalculatorTheme(
          backgroundColor: Color(0xFFF3F4F6),
          displayColor: Colors.white,
          operatorColor: Color(0xFF2563EB),
          numberColor: Colors.white,
          functionColor: Color(0xFFE5E7EB),
          textColor: Colors.black87,
          actionColor: Color(0xFFDC2626),
        );
      case SmartCalculatorThemeStyle.scientificBlue:
        return const SmartCalculatorTheme(
          backgroundColor: Color(0xFF0F172A),
          displayColor: Color(0xFF1E293B),
          operatorColor: Color(0xFF0EA5E9),
          numberColor: Color(0xFF334155),
          functionColor: Color(0xFF475569),
          textColor: Color(0xFFF8FAFC),
          actionColor: Color(0xFFF59E0B),
        );
      case SmartCalculatorThemeStyle.amoled:
        return const SmartCalculatorTheme(
          backgroundColor: Colors.black,
          displayColor: Colors.black,
          operatorColor: Color(0xFF10B981),
          numberColor: Color(0xFF111111),
          functionColor: Color(0xFF222222),
          textColor: Colors.white,
          actionColor: Color(0xFFEF4444),
        );
    }
  }
}
