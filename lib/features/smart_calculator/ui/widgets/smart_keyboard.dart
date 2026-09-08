import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../smart_calculator_provider.dart';
import '../../../../theme/app_theme.dart';

class SmartKeyboard extends StatefulWidget {
  const SmartKeyboard({super.key});

  @override
  State<SmartKeyboard> createState() => _SmartKeyboardState();
}

class _SmartKeyboardState extends State<SmartKeyboard> {
  bool _isAdvanced = false;

  void _onPressed(String key, SmartCalculatorProvider provider) {
    provider.onKeyPressed(key);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartCalculatorProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppTheme.surfaceDark : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              // Toggle Advanced Mode
              GestureDetector(
                onTap: () => setState(() => _isAdvanced = !_isAdvanced),
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              if (_isAdvanced) ...[
                // Advanced Scientific Buttons
                SizedBox(
                  height: 150,
                  child: GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildBtn('sin(', 'sin', isDark, provider, color: Colors.blueAccent),
                      _buildBtn('cos(', 'cos', isDark, provider, color: Colors.blueAccent),
                      _buildBtn('tan(', 'tan', isDark, provider, color: Colors.blueAccent),
                      _buildBtn('asin(', 'sin⁻¹', isDark, provider, color: Colors.blueAccent),
                      _buildBtn('acos(', 'cos⁻¹', isDark, provider, color: Colors.blueAccent),
                      
                      _buildBtn('ln(', 'ln', isDark, provider, color: Colors.orangeAccent),
                      _buildBtn('log(', 'log', isDark, provider, color: Colors.orangeAccent),
                      _buildBtn('e', 'e', isDark, provider, color: Colors.purpleAccent),
                      _buildBtn('π', 'π', isDark, provider, color: Colors.purpleAccent),
                      _buildBtn('atan(', 'tan⁻¹', isDark, provider, color: Colors.blueAccent),
                      
                      _buildBtn('√(', '√', isDark, provider, color: Colors.teal),
                      _buildBtn('x^', 'xʸ', isDark, provider, color: Colors.teal),
                      _buildBtn('x^2', 'x²', isDark, provider, color: Colors.teal),
                      _buildBtn('!', 'x!', isDark, provider, color: Colors.teal),
                      _buildBtn('abs(', '|x|', isDark, provider, color: Colors.teal),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Basic Keypad
                Column(
                  children: [
                    SizedBox(height: 52, child: _buildRow(['AC', 'DEL', '(', ')'], isDark, provider)),
                    const SizedBox(height: 8),
                    SizedBox(height: 52, child: _buildRow(['7', '8', '9', '÷'], isDark, provider)),
                    const SizedBox(height: 8),
                    SizedBox(height: 52, child: _buildRow(['4', '5', '6', '×'], isDark, provider)),
                    const SizedBox(height: 8),
                    SizedBox(height: 52, child: _buildRow(['1', '2', '3', '-'], isDark, provider)),
                    const SizedBox(height: 8),
                    SizedBox(height: 52, child: _buildRow(['0', '.', '=', '+'], isDark, provider)),
                  ],
                ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(List<String> keys, bool isDark, SmartCalculatorProvider provider) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildBtn(
              key, 
              key, 
              isDark, 
              provider,
              isLarge: true,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBtn(
    String value, 
    String label, 
    bool isDark, 
    SmartCalculatorProvider provider, {
    Color? color,
    bool isLarge = false,
  }) {
    // Styling logic based on the key
    Color btnColor = isDark ? Colors.white10 : Colors.grey.shade100;
    Color txtColor = isDark ? Colors.white : Colors.black87;
    
    if (color != null) {
      txtColor = color;
      btnColor = color.withValues(alpha: 0.1);
    } else if (['÷', '×', '-', '+', '='].contains(label)) {
      btnColor = AppTheme.primaryColor;
      txtColor = Colors.white;
    } else if (['AC', 'DEL'].contains(label)) {
      btnColor = Colors.redAccent.withValues(alpha: 0.1);
      txtColor = Colors.redAccent;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onPressed(value, provider),
            borderRadius: BorderRadius.circular(isLarge ? 20 : 12),
            child: Ink(
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(isLarge ? 20 : 12),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.tajawal(
                      fontSize: isLarge ? 24 : 18,
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
    );
  }
}
