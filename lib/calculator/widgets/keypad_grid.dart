import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calculator_provider.dart';
import '../theme/calculator_theme.dart';

class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CalculatorTheme.getTheme(context.watch<CalculatorProvider>().themeStyle);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Top function row (SHIFT, ALPHA, etc)
            _buildFunctionRow(context, theme),
            const SizedBox(height: 12),
            // Scientific functions
            _buildScientificRow(context, theme, ['x²', 'x³', 'x⁻¹', 'sin', 'cos', 'tan']),
            _buildScientificRow(context, theme, ['√', '∛', 'log', 'ln', '(', ')']),
            // Main numpad and basic ops
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildNumpadRow(context, theme, ['7', '8', '9']),
                        _buildNumpadRow(context, theme, ['4', '5', '6']),
                        _buildNumpadRow(context, theme, ['1', '2', '3']),
                        _buildNumpadRow(context, theme, ['0', '.', 'EXP']),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildOpButton(context, theme, 'DEL', color: Colors.redAccent),
                        _buildOpButton(context, theme, 'AC', color: Colors.redAccent),
                        _buildOpButton(context, theme, '×'),
                        _buildOpButton(context, theme, '÷'),
                        _buildOpButton(context, theme, '+'),
                        _buildOpButton(context, theme, '-'),
                        _buildOpButton(context, theme, '=', color: theme.equalsColor, textColor: theme.equalsTextColor),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFunctionRow(BuildContext context, CalculatorTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFuncButton(context, 'SHIFT', theme.shiftColor, () => context.read<CalculatorProvider>().toggleShift()),
        _buildFuncButton(context, 'ALPHA', theme.alphaColor, () => context.read<CalculatorProvider>().toggleAlpha()),
        _buildFuncButton(context, 'MODE', theme.functionTextColor, () {}),
        _buildFuncButton(context, 'ON', theme.functionTextColor, () {}),
      ],
    );
  }

  Widget _buildScientificRow(BuildContext context, CalculatorTheme theme, List<String> labels) {
    return Row(
      children: labels.map((label) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.functionColor,
              foregroundColor: theme.functionTextColor,
              shape: theme.buttonShape,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 40),
              elevation: 0,
            ),
            onPressed: () => context.read<CalculatorProvider>().onKeyPress(label == 'x²' ? '^2' : label == 'x³' ? '^3' : label == 'x⁻¹' ? '^-1' : '$label('),
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildNumpadRow(BuildContext context, CalculatorTheme theme, List<String> labels) {
    return Expanded(
      child: Row(
        children: labels.map((label) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.numpadColor,
                foregroundColor: theme.numpadTextColor,
                shape: theme.buttonShape,
                elevation: 1,
              ),
              onPressed: () => context.read<CalculatorProvider>().onKeyPress(label),
              child: Text(label, style: const TextStyle(fontSize: 24)),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildOpButton(BuildContext context, CalculatorTheme theme, String label, {Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.operatorColor,
            foregroundColor: textColor ?? theme.operatorTextColor,
            shape: theme.buttonShape,
            elevation: 1,
          ),
          onPressed: () => context.read<CalculatorProvider>().onKeyPress(label),
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  Widget _buildFuncButton(BuildContext context, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
