import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../theme/app_theme.dart';
import '../../managers/gemini_math_assistant.dart';

class EquationSolverScreen extends StatefulWidget {
  final String title;
  final String hintText;

  const EquationSolverScreen({
    super.key,
    this.title = 'حل المعادلات والتفاضل',
    this.hintText = 'أدخل المعادلة...',
  });

  @override
  State<EquationSolverScreen> createState() => _EquationSolverScreenState();
}

class _EquationSolverScreenState extends State<EquationSolverScreen>
    with SingleTickerProviderStateMixin {
  String _input = '';
  List<_SolutionStep> _steps = [];
  bool _isLoading = false;
  int _mode = 0;
  late AnimationController _animCtrl;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'AC') {
        _input = '';
        _steps = [];
      } else if (key == 'DEL') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else {
        _input += key;
      }
    });
  }

  Future<void> _solve() async {
    if (_input.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _steps = [];
    });
    _animCtrl.reset();

    if (_mode == 1) {
      final expansion = _expandExpression(_input);
      setState(() {
        _steps = expansion ?? [
          _SolutionStep('❌', 'اكتب حاصل ضرب قوسين مثل: (x + 2)(x + 3)', StepType.error),
        ];
        _isLoading = false;
      });
      _animCtrl.forward();
      return;
    }

    final localSolution = _solvePolynomialLocally(_input);
    if (localSolution != null) {
      setState(() {
        _steps = localSolution;
        _isLoading = false;
      });
      _animCtrl.forward();
      return;
    }

    try {
      final prompt = '''
أنت مساعد رياضي متخصص. المستخدم يريد حل: "$_input"

قدّم الحل بالطريقة التالية بدقة تامة:
- اكتب خطوة واحدة في كل سطر
- ابدأ كل خطوة بأحد هذه البادئات:
  "📌 " لتوضيح المعطيات أو التعريف
  "▶ "  لكل خطوة حسابية
  "✅ " للنتيجة النهائية
  "📝 " للملاحظات والشرح النظري

التزم بالعربية تمامًا في الشرح، واكتب المعادلات بالأرقام والرموز الرياضية.
''';
      final res = await GeminiMathAssistant.askMathQuestion(prompt);
      setState(() {
        _steps = _parseSteps(res);
      });
      _animCtrl.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut);
        }
      });
    } catch (_) {
      setState(() {
        _steps = [
          _SolutionStep('❌', 'تعذر الاتصال بالمساعد الذكي.', StepType.error)
        ];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<_SolutionStep>? _solvePolynomialLocally(String raw) {
    final expression = raw.replaceAll('×', '*').replaceAll(' ', '');
    final linear = RegExp(r'^([+-]?(?:\d+(?:\.\d+)?)?)x([+-]\d+(?:\.\d+)?)?=0$').firstMatch(expression);
    if (linear != null) {
      final a = _coefficient(linear.group(1));
      final b = double.tryParse(linear.group(2) ?? '0');
      if (a == null || b == null || a == 0) return null;
      final x = -b / a;
      return [
        _SolutionStep('📌', 'المعادلة الخطية: $expression', StepType.info),
        _SolutionStep('▶', '${_formatNumber(a)}x = ${_formatNumber(-b)}', StepType.step),
        _SolutionStep('▶', 'نقسم الطرفين على ${_formatNumber(a)}.', StepType.step),
        _SolutionStep('✅', 'x = ${_formatNumber(x)}', StepType.result),
      ];
    }

    final quadratic = RegExp(r'^([+-]?(?:\d+(?:\.\d+)?)?)x\^2([+-]\d+(?:\.\d+)?)x([+-]\d+(?:\.\d+)?)=0$').firstMatch(expression);
    if (quadratic == null) return null;
    final a = _coefficient(quadratic.group(1));
    final b = double.tryParse(quadratic.group(2)!);
    final c = double.tryParse(quadratic.group(3)!);
    if (a == null || b == null || c == null || a == 0) return null;
    final discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
      return [
        _SolutionStep('📌', 'المعادلة التربيعية: $expression', StepType.info),
        _SolutionStep('▶', 'نحسب المميز Δ = b² − 4ac = ${_formatNumber(discriminant)}.', StepType.step),
        _SolutionStep('📝', 'بما أن Δ أصغر من صفر، فلا توجد حلول حقيقية.', StepType.note),
      ];
    }
    final root = math.sqrt(discriminant);
    final x1 = (-b + root) / (2 * a);
    final x2 = (-b - root) / (2 * a);
    return [
      _SolutionStep('📌', 'المعادلة التربيعية: $expression', StepType.info),
      _SolutionStep('▶', 'نحدد a = ${_formatNumber(a)}، b = ${_formatNumber(b)}، c = ${_formatNumber(c)}.', StepType.step),
      _SolutionStep('▶', 'نحسب المميز Δ = b² − 4ac = ${_formatNumber(discriminant)}.', StepType.step),
      _SolutionStep('▶', 'نطبق x = (−b ± √Δ) ÷ 2a.', StepType.step),
      _SolutionStep('✅', 'x₁ = ${_formatNumber(x1)}\nx₂ = ${_formatNumber(x2)}', StepType.result),
    ];
  }

  double? _coefficient(String? value) {
    if (value == null || value.isEmpty || value == '+') return 1;
    if (value == '-') return -1;
    return double.tryParse(value);
  }

  List<_SolutionStep>? _expandExpression(String raw) {
    final expression = raw.replaceAll('×', '*').replaceAll(' ', '');
    final product = RegExp(r'^\(([^()]+)\)(?:\*|)\(([^()]+)\)$').firstMatch(expression);
    final power = RegExp(r'^\(([^()]+)\)\^([23])$').firstMatch(expression);
    final left = product?.group(1) ?? power?.group(1);
    final right = product?.group(2);
    final exponent = power == null ? null : int.tryParse(power.group(2)!);
    if (left == null) return null;

    final first = _parseLinear(left);
    final second = right == null ? first : _parseLinear(right);
    if (first == null || second == null) return null;
    final a = first.$1;
    final b = first.$2;
    final c = second.$1;
    final d = second.$2;
    final result = <int, double>{};
    void add(int degree, double value) => result[degree] = (result[degree] ?? 0) + value;
    if (exponent == 3) {
      add(3, a * a * a);
      add(2, 3 * a * a * b);
      add(1, 3 * a * b * b);
      add(0, b * b * b);
    } else {
      add(2, a * c);
      add(1, a * d + b * c);
      add(0, b * d);
    }
    final expanded = _formatPolynomial(result);
    final original = product != null ? '($left) × ($right)' : '($left)^$exponent';
    return [
      _SolutionStep('📌', 'نوسع التعبير: $original', StepType.info),
      _SolutionStep('▶', product != null ? 'نضرب كل حد في القوس الأول بكل حد في القوس الثاني.' : 'نستخدم متطابقة القوة للتعبير ذي الحدين.', StepType.step),
      _SolutionStep('▶', 'نجمع الحدود المتشابهة.', StepType.step),
      _SolutionStep('✅', '$original = $expanded', StepType.result),
    ];
  }

  (double, double)? _parseLinear(String value) {
    final match = RegExp(r'^([+-]?(?:\d+(?:\.\d+)?)?)x([+-]\d+(?:\.\d+)?)?$').firstMatch(value);
    if (match == null) return null;
    final coefficient = match.group(1);
    final a = coefficient == null || coefficient.isEmpty || coefficient == '+'
        ? 1.0
        : coefficient == '-' ? -1.0 : double.tryParse(coefficient);
    final b = match.group(2) == null ? 0.0 : double.tryParse(match.group(2)!);
    if (a == null || b == null) return null;
    return (a, b);
  }

  String _formatPolynomial(Map<int, double> terms) {
    final entries = terms.entries.where((entry) => entry.value.abs() > 1e-10).toList()..sort((a, b) => b.key.compareTo(a.key));
    if (entries.isEmpty) return '0';
    final output = StringBuffer();
    for (final entry in entries) {
      final value = entry.value;
      final sign = value < 0 ? '-' : (output.length == 0 ? '' : '+');
      final magnitude = value.abs();
      final coefficient = (magnitude - 1).abs() < 1e-10 && entry.key > 0 ? '' : _formatNumber(magnitude);
      final variable = entry.key == 0 ? '' : entry.key == 1 ? 'x' : 'x^${entry.key}';
      output.write('$sign$coefficient$variable');
    }
    return output.toString();
  }

  String _formatNumber(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _input = 'صورة ملتقطة بالكاميرا 📷';
      _isLoading = true;
      _steps = [];
    });
    _animCtrl.reset();

    try {
      final file = File(xFile.path);
      final res = await GeminiMathAssistant.solveMathFromImage(file);
      setState(() {
        _steps = _parseSteps(res);
      });
      _animCtrl.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut);
        }
      });
    } catch (_) {
      setState(() {
        _steps = [
          _SolutionStep('❌', 'تعذر الاتصال أو فهم الصورة.', StepType.error)
        ];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<_SolutionStep> _parseSteps(String raw) {
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    List<_SolutionStep> steps = [];
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('📌')) {
        steps.add(_SolutionStep(
            '📌', t.replaceFirst('📌', '').trim(), StepType.info));
      } else if (t.startsWith('▶')) {
        steps.add(_SolutionStep(
            '▶', t.replaceFirst('▶', '').trim(), StepType.step));
      } else if (t.startsWith('✅')) {
        steps.add(_SolutionStep(
            '✅', t.replaceFirst('✅', '').trim(), StepType.result));
      } else if (t.startsWith('📝')) {
        steps.add(_SolutionStep(
            '📝', t.replaceFirst('📝', '').trim(), StepType.note));
      } else {
        if (steps.isNotEmpty) {
          final last = steps.removeLast();
          steps.add(_SolutionStep(last.icon, '${last.text}\n$t', last.type));
        } else {
          steps.add(_SolutionStep('▶', t, StepType.step));
        }
      }
    }
    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.cardColor;
    final textCol = theme.colorScheme.onSurface;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textCol),
        centerTitle: true,
        title: Text(
          widget.title,
          style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold, color: textCol, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'حل بالكاميرا',
            onPressed: _takePhoto,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Display ──────────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // Input display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.15 : 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      Text('f = ',
                          style: GoogleFonts.outfit(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Text(
                            _input.isEmpty ? widget.hintText : _input,
                            textDirection: TextDirection.ltr,
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              color: _input.isEmpty
                                  ? Colors.grey.withValues(alpha: 0.4)
                                  : textCol,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('حل تفصيلي'), icon: Icon(Icons.functions_rounded)),
                    ButtonSegment(value: 1, label: Text('توسيع المعادلة'), icon: Icon(Icons.open_in_full_rounded)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (value) => setState(() {
                    _mode = value.first;
                    _steps = [];
                  }),
                ),
                const SizedBox(height: 16),

                // Solution steps
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child:
                        SpinKitThreeBounce(color: AppTheme.primaryColor, size: 28),
                  )
                else if (_steps.isNotEmpty) ...[
                  ..._steps.asMap().entries.map((entry) {
                    final i = entry.key;
                    final step = entry.value;
                    return AnimatedBuilder(
                      animation: _animCtrl,
                      builder: (ctx, child) {
                        final delay = (i * 0.12).clamp(0.0, 0.9);
                        final p = ((_animCtrl.value - delay) / (1.0 - delay))
                            .clamp(0.0, 1.0);
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - p)),
                          child: Opacity(opacity: p, child: child),
                        );
                      },
                      child: _buildStepCard(step, surface, textCol),
                    );
                  }),
                ],
              ],
            ),
          ),

          // ── Math Keyboard ─────────────────────────────────
          _buildKeyboard(isDark),
        ],
      ),
    );
  }

  Widget _buildStepCard(
      _SolutionStep step, Color surface, Color textCol) {
    Color borderColor;
    Color iconBg;
    switch (step.type) {
      case StepType.info:
        borderColor = Colors.blue.withValues(alpha: 0.4);
        iconBg = Colors.blue.withValues(alpha: 0.1);
      case StepType.step:
        borderColor = AppTheme.primaryColor.withValues(alpha: 0.3);
        iconBg = AppTheme.primaryColor.withValues(alpha: 0.08);
      case StepType.result:
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.7);
        iconBg = const Color(0xFF10B981).withValues(alpha: 0.1);
      case StepType.note:
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.4);
        iconBg = const Color(0xFFF59E0B).withValues(alpha: 0.08);
      case StepType.error:
        borderColor = Colors.redAccent.withValues(alpha: 0.4);
        iconBg = Colors.redAccent.withValues(alpha: 0.08);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Text(step.icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.text,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.tajawal(
                fontSize: step.type == StepType.result ? 17 : 15,
                color: textCol,
                height: 1.7,
                fontWeight: step.type == StepType.result
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboard(bool isDark) {
    final kbBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF);

    // format: 'display→value' or just 'value' for single
    final rows = [
      ['x', 'y', 'n', '^', '²→^(2)', '√(', 'AC', 'DEL'],
      ['sin(', 'cos(', 'tan(', '(', ')', '÷', '×', '%'],
      ['7', '8', '9', 'log(', 'ln(', 'e^(', 'π', 'e'],
      ['4', '5', '6', '∫', 'd/dx→d/dx(', 'lim(', '∞→999999', '='],
      ['1', '2', '3', 'nPr(', 'nCr(', 'n!→!', ',', '+'],
      ['0', '.', '±→(-1)×(', '⁻¹→^(-1)', 'abs(', 'حل', '-', '|→abs('],
    ];

    return Container(
      color: kbBg,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 20),
      child: Column(
        children: rows.map((row) {
          return Row(
            children: row.map((rawKey) {
              final parts = rawKey.split('→');
              final display = parts[0];
              final value = parts.length > 1 ? parts[1] : parts[0];
              return Expanded(child: _buildKey(display, value, isDark));
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String display, String value, bool isDark) {
    final isSolve = display == 'حل';
    final isDelete = display == 'DEL' || display == 'AC';
    final isNumber =
        ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']
            .contains(display);
    final isOperator =
        ['+', '-', '×', '÷', '%', '=', ','].contains(display);

    Color bg;
    Color fg;

    if (isSolve) {
      bg = const Color(0xFF6366F1);
      fg = Colors.white;
    } else if (display == 'AC') {
      bg = Colors.redAccent.withValues(alpha: 0.85);
      fg = Colors.white;
    } else if (display == 'DEL') {
      bg = Colors.orange.withValues(alpha: 0.85);
      fg = Colors.white;
    } else if (isNumber) {
      bg = isDark ? const Color(0xFF334155) : Colors.white;
      fg = isDark ? Colors.white : Colors.black87;
    } else if (isOperator) {
      bg = isDark ? const Color(0xFF475569) : const Color(0xFFE0E7FF);
      fg = const Color(0xFF6366F1);
    } else {
      bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFDDE3FF);
      fg = isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA);
    }

    final label = display.length > 4 ? display.substring(0, 4) : display;

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () {
            if (isSolve) {
              _solve();
            } else if (display == 'AC') {
              _onKey('AC');
            } else if (display == 'DEL') {
              _onKey('DEL');
            } else {
              _onKey(value);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: isSolve ? 14 : (display.length > 3 ? 11 : 15),
                fontWeight: isSolve || isDelete
                    ? FontWeight.bold
                    : FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum StepType { info, step, result, note, error }

class _SolutionStep {
  final String icon;
  final String text;
  final StepType type;
  _SolutionStep(this.icon, this.text, this.type);
}
