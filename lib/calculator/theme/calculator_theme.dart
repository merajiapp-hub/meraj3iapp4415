import 'package:flutter/material.dart';

enum CalculatorThemeStyle {
  modernDark,
  classicLight,
  neonPro,
}

class CalculatorTheme {
  final Color backgroundColor;
  final Color displayColor;
  final Color numpadColor;
  final Color numpadTextColor;
  final Color operatorColor;
  final Color operatorTextColor;
  final Color functionColor;
  final Color functionTextColor;
  final Color shiftColor;
  final Color alphaColor;
  final Color equalsColor;
  final Color equalsTextColor;
  final OutlinedBorder buttonShape;

  const CalculatorTheme({
    required this.backgroundColor,
    required this.displayColor,
    required this.numpadColor,
    required this.numpadTextColor,
    required this.operatorColor,
    required this.operatorTextColor,
    required this.functionColor,
    required this.functionTextColor,
    required this.shiftColor,
    required this.alphaColor,
    required this.equalsColor,
    required this.equalsTextColor,
    required this.buttonShape,
  });

  static CalculatorTheme getTheme(CalculatorThemeStyle style) {
    switch (style) {
      case CalculatorThemeStyle.modernDark:
        return CalculatorTheme(
          backgroundColor: const Color(0xFF1E1E1E),
          displayColor: const Color(0xFF2C2C2C),
          numpadColor: const Color(0xFF333333),
          numpadTextColor: Colors.white,
          operatorColor: const Color(0xFF424242),
          operatorTextColor: Colors.white,
          functionColor: const Color(0xFF2C2C2C),
          functionTextColor: Colors.white70,
          shiftColor: Colors.orangeAccent,
          alphaColor: Colors.purpleAccent,
          equalsColor: Colors.blueAccent,
          equalsTextColor: Colors.white,
          buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      case CalculatorThemeStyle.classicLight:
        return CalculatorTheme(
          backgroundColor: const Color(0xFFF5F5F5),
          displayColor: const Color(0xFFE0E0E0),
          numpadColor: const Color(0xFFFFFFFF),
          numpadTextColor: Colors.black87,
          operatorColor: const Color(0xFFE0E0E0),
          operatorTextColor: Colors.black87,
          functionColor: const Color(0xFFEEEEEE),
          functionTextColor: Colors.black54,
          shiftColor: Colors.orange,
          alphaColor: Colors.purple,
          equalsColor: const Color(0xFF1976D2),
          equalsTextColor: Colors.white,
          buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        );
      case CalculatorThemeStyle.neonPro:
        return CalculatorTheme(
          backgroundColor: const Color(0xFF0F0F1B),
          displayColor: const Color(0xFF1A1A2E),
          numpadColor: const Color(0xFF1A1A2E),
          numpadTextColor: Colors.cyanAccent,
          operatorColor: const Color(0xFF16213E),
          operatorTextColor: Colors.pinkAccent,
          functionColor: const Color(0xFF0F3460),
          functionTextColor: Colors.lightGreenAccent,
          shiftColor: Colors.yellowAccent,
          alphaColor: Colors.redAccent,
          equalsColor: Colors.cyanAccent,
          equalsTextColor: Colors.black,
          buttonShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
    }
  }
}
