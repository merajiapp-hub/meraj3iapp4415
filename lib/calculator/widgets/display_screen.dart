import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/calculator_provider.dart';
import '../theme/calculator_theme.dart';

class CalculatorDisplay extends StatelessWidget {
  const CalculatorDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalculatorProvider>(context);
    final theme = CalculatorTheme.getTheme(provider.themeStyle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.displayColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Status bar (SHIFT, ALPHA, Angle Mode)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (provider.isShiftDown)
                    const Text('S', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  if (provider.isAlphaDown)
                    const Text(' A', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                ],
              ),
              Text(
                provider.angleMode.name.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Expression display
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  provider.expression.isEmpty ? '0' : provider.expression,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w400, color: theme.operatorTextColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          
          // Result display
          const SizedBox(height: 8),
          Text(
            provider.result,
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w600, 
              color: theme.operatorTextColor.withValues(alpha: 0.8)
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
