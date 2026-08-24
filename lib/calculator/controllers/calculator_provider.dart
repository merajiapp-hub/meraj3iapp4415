import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/evaluator.dart';
import '../theme/calculator_theme.dart';

enum AngleMode { degree, radian, gradian }

class CalculatorProvider with ChangeNotifier {
  String _expression = '';
  String _result = '';
  bool _isShiftDown = false;
  bool _isAlphaDown = false;
  AngleMode _angleMode = AngleMode.degree;
  CalculatorThemeStyle _themeStyle = CalculatorThemeStyle.modernDark;
  
  final List<Map<String, String>> _history = [];
  
  // Variables A, B, C, D, X, Y, M
  final Map<String, double> _variables = {};

  final CalculatorEvaluator _evaluator = CalculatorEvaluator();

  // Getters
  String get expression => _expression;
  String get result => _result;
  bool get isShiftDown => _isShiftDown;
  bool get isAlphaDown => _isAlphaDown;
  AngleMode get angleMode => _angleMode;
  CalculatorThemeStyle get themeStyle => _themeStyle;
  Map<String, double> get variables => _variables;
  List<Map<String, String>> get history => _history;

  CalculatorProvider() {
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int modeIndex = prefs.getInt('angle_mode') ?? 0;
    _angleMode = AngleMode.values[modeIndex];
    int themeIndex = prefs.getInt('calculator_theme') ?? 0;
    _themeStyle = CalculatorThemeStyle.values[themeIndex];
    notifyListeners();
  }

  void saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('angle_mode', _angleMode.index);
    prefs.setInt('calculator_theme', _themeStyle.index);
  }

  void setAngleMode(AngleMode mode) {
    _angleMode = mode;
    saveSettings();
    _evaluate(); // Re-evaluate result if angle mode changes
    notifyListeners();
  }
  
  void setThemeStyle(CalculatorThemeStyle style) {
    _themeStyle = style;
    saveSettings();
    notifyListeners();
  }

  void toggleShift() {
    _isShiftDown = !_isShiftDown;
    if (_isShiftDown) _isAlphaDown = false;
    notifyListeners();
  }

  void toggleAlpha() {
    _isAlphaDown = !_isAlphaDown;
    if (_isAlphaDown) _isShiftDown = false;
    notifyListeners();
  }
  
  void clearShiftAlpha() {
    bool changed = false;
    if (_isShiftDown) {
      _isShiftDown = false;
      changed = true;
    }
    if (_isAlphaDown) {
      _isAlphaDown = false;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void onKeyPress(String value) {
    // Handle specific inputs
    if (value == 'AC') {
      _expression = '';
      _result = '';
      clearShiftAlpha();
    } else if (value == 'DEL') {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    } else if (value == '=') {
      if (_result.isNotEmpty && _result != 'Error') {
        // Add to history before replacing
        _addToHistory(_expression, _result);
        
        // Keep the result as the new expression
        _expression = _result;
        _result = '';
      }
    } else {
      _expression += value;
    }
    
    // Auto-evaluate when typing
    _evaluate();
    
    // Clear shift/alpha state after pressing a button (except if it was SHIFT/ALPHA themselves, handled elsewhere)
    clearShiftAlpha(); 
    
    notifyListeners();
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      _result = '';
      return;
    }
    
    try {
      _result = _evaluator.evaluate(_expression, angleMode: _angleMode, variables: _variables);
    } catch (e) {
      // Don't show error immediately while typing unless it's a serious syntax error,
      // but usually we can just show nothing or a subtle indicator.
      _result = ''; 
    }
  }
  
  void setVariable(String name, double value) {
    _variables[name] = value;
    _evaluate();
    notifyListeners();
  }
  
  void removeVariable(String name) {
    _variables.remove(name);
    _evaluate();
    notifyListeners();
  }
  
  void _addToHistory(String expr, String res) {
    _history.insert(0, {'expression': expr, 'result': res});
    if (_history.length > 50) _history.removeLast(); // Keep latest 50
  }
  
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
  
  void useHistoryItem(String expr) {
    _expression = expr;
    _evaluate();
    notifyListeners();
  }
}
