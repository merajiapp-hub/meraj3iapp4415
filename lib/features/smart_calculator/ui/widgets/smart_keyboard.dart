import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../smart_calculator_provider.dart';
import '../theme/smart_calculator_theme.dart';

class SmartKeyboard extends StatelessWidget {
  const SmartKeyboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartCalculatorProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final theme = SmartCalculatorTheme.getTheme(provider.themeStyle);
            return Container(
              color: theme.backgroundColor,
              child: Column(
                children: [
                  _buildRow(context, provider, theme, ['AC', 'DEL', '%', '÷'], isTop: true),
                  _buildRow(context, provider, theme, ['7', '8', '9', '×']),
                  _buildRow(context, provider, theme, ['4', '5', '6', '-']),
                  _buildRow(context, provider, theme, ['1', '2', '3', '+']),
                  _buildRow(context, provider, theme, ['0', '.', 'Ans', '=']),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, SmartCalculatorProvider provider, SmartCalculatorTheme theme, List<String> buttons, {bool isTop = false}) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((btn) => _buildButton(context, provider, theme, btn, isTop)).toList(),
      ),
    );
  }

  Widget _buildButton(BuildContext context, SmartCalculatorProvider provider, SmartCalculatorTheme theme, String label, bool isTop) {
    bool isOperator = ['÷', '×', '-', '+', '='].contains(label);
    
    Color bgColor = isOperator ? theme.operatorColor : (isTop ? theme.functionColor : theme.numberColor);
    Color txtColor = isOperator ? Colors.white : theme.textColor;
    
    if (label == 'AC') {
      bgColor = theme.actionColor;
      txtColor = Colors.white;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () => provider.onKeyPressed(label),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: txtColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
