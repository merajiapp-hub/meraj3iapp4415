import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../engines/calculus_engine.dart';
import '../../engines/equation_solver.dart';
import '../../engines/statistics_engine.dart';

class AdvancedMathLabScreen extends StatefulWidget {
  const AdvancedMathLabScreen({super.key});

  @override
  State<AdvancedMathLabScreen> createState() => _AdvancedMathLabScreenState();
}

class _AdvancedMathLabScreenState extends State<AdvancedMathLabScreen> {
  int _tool = 0;
  final _function = TextEditingController(text: 'x^2 + 3x');
  final _variable = TextEditingController(text: 'x');
  final _lower = TextEditingController(text: '0');
  final _upper = TextEditingController(text: '1');
  final _data = TextEditingController(text: '1, 2, 3, 4, 5');
  final _coefficients = TextEditingController(text: '1, -3, 2');
  String _result = '';
  String? _error;
  TextEditingController? _activeController;

  @override
  void dispose() {
    _function.dispose();
    _variable.dispose();
    _lower.dispose();
    _upper.dispose();
    _data.dispose();
    _coefficients.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    try {
      String result = '';
      if (_tool == 0) {
        final derivative = CalculusEngine.differentiate(_function.text, _variable.text.trim());
        final integral = CalculusEngine.integrate(
          _function.text,
          _variable.text.trim(),
          double.parse(_lower.text.replaceAll(',', '.')),
          double.parse(_upper.text.replaceAll(',', '.')),
        );
        result = 'Dérivée :\n$derivative\n\nIntégrale définie :\n${_format(integral)}';
      } else if (_tool == 1) {
        final values = _numbers(_data.text);
        if (values.isEmpty) throw const FormatException('Saisissez des nombres séparés par des virgules');
        final modes = StatisticsEngine.mode(values).map(_format).join(', ');
        result = 'Moyenne : ${_format(StatisticsEngine.mean(values))}\n'
            'Médiane : ${_format(StatisticsEngine.median(values))}\n'
            'Mode : $modes\n'
            'Variance : ${_format(StatisticsEngine.variance(values))}\n'
            'Écart type : ${_format(StatisticsEngine.standardDeviation(values))}';
      } else {
        final coefficients = _numbers(_coefficients.text);
        if (coefficients.length == 2) {
          result = _complexList(EquationSolverEngine.solveLinear(coefficients[0], coefficients[1]));
        } else if (coefficients.length == 3) {
          result = _complexList(EquationSolverEngine.solveQuadratic(
              coefficients[0], coefficients[1], coefficients[2]));
        } else if (coefficients.length == 4) {
          result = _complexList(EquationSolverEngine.solveCubic(
              coefficients[0], coefficients[1], coefficients[2], coefficients[3]));
        } else {
          throw const FormatException('Saisissez les coefficients du polynôme du plus haut degré au terme constant');
        }
      }
      setState(() {
        _result = result;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _result = '';
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _insert(String value) {
    final controller = _activeController ?? (_tool == 0 ? _function : _tool == 1 ? _data : _coefficients);
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : controller.text.length;
    controller.value = controller.value.copyWith(
      text: controller.text.replaceRange(start, end, value),
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    setState(() {});
  }

  List<double> _numbers(String input) => input
      .split(RegExp(r'[,;\s]+'))
      .where((value) => value.trim().isNotEmpty)
      .map((value) => double.parse(value.replaceAll(',', '.')))
      .toList();

  String _complexList(List<dynamic> values) => values.isEmpty
      ? 'Aucune solution réelle ou complexe.'
      : values.map((value) => value.toString()).join('\n');

  String _format(double value) {
    if (!value.isFinite) return value.toString();
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).cardColor;
    final text = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Laboratoire de mathématiques', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Dérivée & Intégrale'), icon: Icon(Icons.functions)),
              ButtonSegment(value: 1, label: Text('Statistiques'), icon: Icon(Icons.bar_chart)),
              ButtonSegment(value: 2, label: Text('Équations'), icon: Icon(Icons.polyline)),
            ],
            selected: {_tool},
            onSelectionChanged: (value) => setState(() {
              _tool = value.first;
              _result = '';
              _error = null;
            }),
            ),
          ),
          const SizedBox(height: 18),
          if (_tool == 0) ...[
            _field(_function, 'Fonction f(x)', 'Exemple : sin(x) + x^2'),
            _field(_variable, 'Variable', 'x'),
            Row(children: [
              Expanded(child: _field(_lower, 'De', '0')),
              const SizedBox(width: 10),
              Expanded(child: _field(_upper, 'À', '1')),
            ]),
          ] else if (_tool == 1) ...[
            _field(_data, 'Données', '1, 2, 3, 4, 5'),
            Text('Prend en charge les virgules et espaces ; calcule la moyenne, la médiane, le mode, la variance et l’écart type.', style: TextStyle(color: text.withValues(alpha: 0.65))),
          ] else ...[
            _field(_coefficients, 'Coefficients', 'a,b,c pour le second degré ou a,b pour le premier degré'),
            Text('Exemple : 1,-3,2 signifie x² - 3x + 2 = 0', style: TextStyle(color: text.withValues(alpha: 0.65))),
          ],
          _buildMathKeyboard(),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: _calculate, icon: const Icon(Icons.auto_awesome), label: const Text('Calculer avec précision')),
          const SizedBox(height: 18),
          if (_error != null) _output(_error!, Colors.redAccent, surface, isDark),
          if (_result.isNotEmpty) _output(_result, Colors.tealAccent, surface, isDark),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        onTap: () => _activeController = controller,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildMathKeyboard() {
    final keys = _tool == 0
        ? ['x', 'y', 'π', 'e', '+', '-', '×', '÷', '(', ')', 'sin(', 'cos(', 'tan(', 'ln(', 'log(', '√(', '^', '!', 'DEL', 'AC']
        : _tool == 1
            ? ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '.', ',', ';', 'DEL', 'AC']
            : ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '.', ',', 'DEL', 'AC'];
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF172033) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: keys.map((key) {
          final destructive = key == 'AC' || key == 'DEL';
          return SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                if (key == 'AC') {
                  final controller = _activeController ?? (_tool == 0 ? _function : _tool == 1 ? _data : _coefficients);
                  controller.clear();
                  setState(() {});
                } else if (key == 'DEL') {
                  final controller = _activeController ?? (_tool == 0 ? _function : _tool == 1 ? _data : _coefficients);
                  if (controller.text.isNotEmpty) {
                    controller.text = controller.text.substring(0, controller.text.length - 1);
                    controller.selection = TextSelection.collapsed(offset: controller.text.length);
                    setState(() {});
                  }
                } else {
                  _insert(key);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: destructive ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                side: BorderSide(color: destructive ? Colors.redAccent.withValues(alpha: 0.45) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(key, textDirection: TextDirection.ltr),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _output(String value, Color accent, Color surface, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: accent.withValues(alpha: 0.45))),
      child: SelectableText(value, textDirection: TextDirection.rtl, style: GoogleFonts.tajawal(fontSize: 17, height: 1.7, color: isDark ? Colors.white : Colors.black87)),
    );
  }
}
