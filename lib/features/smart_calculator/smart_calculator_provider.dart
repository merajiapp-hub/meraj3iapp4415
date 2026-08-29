import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  // History & Undo/Redo
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  
  List<Map<String, String>> _history = [];
  List<Map<String, String>> get history => _history;
  
  List<Map<String, String>> _favorites = [];
  List<Map<String, String>> get favorites => _favorites;

  SmartCalculatorProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final hist = prefs.getStringList('calc_history') ?? [];
    final fav = prefs.getStringList('calc_favorites') ?? [];
    
    _history = hist.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
    _favorites = fav.map((e) => Map<String, String>.from(jsonDecode(e))).toList();
    
    final modeIdx = prefs.getInt('calc_angleMode') ?? 0;
    _angleMode = AngleMode.values[modeIdx];
    
    notifyListeners();
  }
  
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final hist = _history.map((e) => jsonEncode(e)).toList();
    final fav = _favorites.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('calc_history', hist);
    await prefs.setStringList('calc_favorites', fav);
    await prefs.setInt('calc_angleMode', _angleMode.index);
  }

  void setMode(CalculatorMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void setAngleMode(AngleMode mode) {
    _angleMode = mode;
    _saveData();
    notifyListeners();
  }
  
  void toggleAngleMode() {
    if (_angleMode == AngleMode.degree) {
      _angleMode = AngleMode.radian;
    } else if (_angleMode == AngleMode.radian) {
      _angleMode = AngleMode.gradian;
    } else {
      _angleMode = AngleMode.degree;
    }
    _saveData();
    notifyListeners();
  }

  void setThemeStyle(SmartCalculatorThemeStyle style) {
    _themeStyle = style;
    notifyListeners();
  }
  
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_expression);
      _expression = _undoStack.removeLast();
      _evaluate(silent: true);
      notifyListeners();
    }
  }
  
  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_expression);
      _expression = _redoStack.removeLast();
      _evaluate(silent: true);
      notifyListeners();
    }
  }

  void onKeyPressed(String key) {
    _undoStack.add(_expression);
    _redoStack.clear();
    
    if (key == 'AC') {
      _expression = '';
      _result = '';
      _isError = false;
    } else if (key == 'DEL') {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
        _evaluate(silent: true);
      }
    } else if (key == '=') {
      _evaluate();
      if (!_isError && _expression.isNotEmpty) {
        _addToHistory(_expression, _result);
        // Start next expression with the result if they want to chain
        _expression = _result;
      }
    } else if (key == 'Ans') {
      if (_history.isNotEmpty) {
        _expression += _history.first['result'] ?? '';
      }
    } else {
      _expression += key;
      _evaluate(silent: true);
    }
    notifyListeners();
  }
  
  void setExpression(String expr) {
    _undoStack.add(_expression);
    _redoStack.clear();
    _expression = expr;
    _evaluate(silent: true);
    notifyListeners();
  }

  void _evaluate({bool silent = false}) {
    if (_expression.trim().isEmpty) {
      if (silent) _result = '';
      return;
    }
    
    // Check if it's an assignment (e.g., x=5)
    if (_expression.contains('=')) {
      final parts = _expression.split('=');
      if (parts.length == 2 && parts[0].trim().isNotEmpty) {
         try {
           final val = double.parse(AlgebraEngine.evaluateExpression(parts[1], angleMode: _angleMode.name));
           AlgebraEngine.setVariable(parts[0].trim(), val);
           _result = 'تم حفظ المتغير';
           _isError = false;
           return;
         } catch(e) {
           // Ignore silent errors for variable assignments in progress
         }
      }
    }
    
    try {
      _result = AlgebraEngine.evaluateExpression(_expression, angleMode: _angleMode.name);
      if (_result == 'غير معرف' || _result == 'NaN' || _result == 'Infinity') {
        if (!silent) _isError = true;
      } else {
        _isError = false;
      }
    } catch (e) {
      if (!silent) {
        _result = 'تأكد من كتابة العملية بشكل صحيح';
        _isError = true;
      }
    }
    
    if (!silent) {
      notifyListeners();
    }
  }
  
  void _addToHistory(String expr, String res) {
    _history.insert(0, {'expression': expr, 'result': res});
    if (_history.length > 50) {
      _history.removeLast();
    }
    _saveData();
  }
  
  void toggleFavorite(String expr, String res) {
    final idx = _favorites.indexWhere((e) => e['expression'] == expr);
    if (idx >= 0) {
      _favorites.removeAt(idx);
    } else {
      _favorites.insert(0, {'expression': expr, 'result': res});
    }
    _saveData();
    notifyListeners();
  }
  
  void clearHistory() {
    _history.clear();
    _saveData();
    notifyListeners();
  }
}

