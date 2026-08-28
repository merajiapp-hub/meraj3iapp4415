import 'package:flutter/material.dart';
import 'engines/algebra_engine.dart';
import 'ui/theme/smart_calculator_theme.dart';

enum CalculatorMode {
  basic,
  scientific,
  advanced,
  matrix,
  statistics,
  equationSolver,
  graphing,
  unitConverter,
  physics,
  chemistry
}

enum AngleMode {
  degree,
  radian,
  gradian
}

class SmartCalculatorProvider extends ChangeNotifier {
  CalculatorMode _currentMode = CalculatorMode.basic;
  CalculatorMode get currentMode => _currentMode;

  AngleMode _angleMode = AngleMode.degree;
  AngleMode get angleMode => _angleMode;

  SmartCalculatorThemeStyle _themeStyle = SmartCalculatorThemeStyle.modernDark;
  SmartCalculatorThemeStyle get themeStyle => _themeStyle;

  String _expression = '';
  String get expression => _expression;

  String _result = '';
  String get result => _result;
  
  bool _isError = false;
  bool get isError => _isError;

  void setMode(CalculatorMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void setAngleMode(AngleMode mode) {
    _angleMode = mode;
    notifyListeners();
  }

  void setThemeStyle(SmartCalculatorThemeStyle style) {
    _themeStyle = style;
    notifyListeners();
  }

  void onKeyPressed(String key) {
    if (key == 'AC') {
      _expression = '';
      _result = '';
      _isError = false;
    } else if (key == 'DEL') {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    } else if (key == '=') {
      _evaluate();
    } else if (key == 'Ans') {
      if (_result.isNotEmpty && !_isError) {
        _expression += _result;
      }
    } else {
      _expression += key;
    }
    notifyListeners();
  }

  void _evaluate() {
    if (_expression.trim().isEmpty) return;
    
    try {
      // Use AlgebraEngine to evaluate
      _result = AlgebraEngine.evaluateExpression(_expression, angleMode: _angleMode.name);
      _isError = false;
    } catch (e) {
      _result = 'خطأ';
      _isError = true;
    }
    notifyListeners();
  }
}
