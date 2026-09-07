import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_theme.dart';
import '../../smart_calculator_provider.dart';
import '../widgets/smart_keyboard.dart';

class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  State<ScientificCalculatorScreen> createState() =>
      _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState
    extends State<ScientificCalculatorScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, SmartCalculatorProvider provider) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        provider.onKeyPressed('=');
      } else if (key == LogicalKeyboardKey.backspace) {
        provider.onKeyPressed('DEL');
      } else if (key == LogicalKeyboardKey.escape) {
        provider.onKeyPressed('AC');
      } else if (event.character != null) {
        final char = event.character!;
        if (RegExp(r'[0-9\.\+\-\*\/\(\)\^]').hasMatch(char)) {
          String mappedChar = char;
          if (char == '*') mappedChar = '×';
          if (char == '/') mappedChar = '÷';
          provider.onKeyPressed(mappedChar);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartCalculatorProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (event) => _handleKeyEvent(event, provider),
          child: Column(
            children: [
              // ── Display Section ──
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.backgroundDark
                        : AppTheme.backgroundLight,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Top bar for tools (History, Undo, Redo, Variables, Angle Mode)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history_rounded),
                                onPressed: () =>
                                    _showHistoryBottomSheet(context, provider),
                                color: isDark ? Colors.white54 : Colors.black54,
                                tooltip: 'Historique',
                              ),
                              IconButton(
                                icon: const Icon(Icons.undo_rounded),
                                onPressed: () => provider.undo(),
                                color: isDark ? Colors.white54 : Colors.black54,
                                tooltip: 'Annuler',
                              ),
                              IconButton(
                                icon: const Icon(Icons.redo_rounded),
                                onPressed: () => provider.redo(),
                                color: isDark ? Colors.white54 : Colors.black54,
                                tooltip: 'Rétablir',
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => provider.toggleAngleMode(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                provider.angleMode.name.toUpperCase().substring(
                                  0,
                                  3,
                                ),
                                style: GoogleFonts.tajawal(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Expression text
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Text(
                          provider.expression.isEmpty
                              ? '0'
                              : provider.expression,
                          style: GoogleFonts.tajawal(
                            fontSize: provider.expression.length > 20 ? 32 : 42,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Result text
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (provider.result.isNotEmpty && !provider.isError)
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                color: AppTheme.primaryColor,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: provider.result),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Résultat copié : ${provider.result}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Text(
                              provider.result,
                              style: GoogleFonts.tajawal(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: provider.isError
                                    ? Colors.redAccent
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Keypad Section ──
              const Expanded(flex: 7, child: SmartKeyboard()),
            ],
          ),
        );
      },
    );
  }

  void _showHistoryBottomSheet(
    BuildContext context,
    SmartCalculatorProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.surfaceDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historique',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.clearHistory();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Effacer',
                      style: GoogleFonts.tajawal(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: provider.history.length,
                itemBuilder: (context, index) {
                  final item = provider.history[index];
                  return ListTile(
                    title: Text(
                      item['expression'] ?? '',
                      textAlign: TextAlign.right,
                    ),
                    subtitle: Text(
                      '= ${item['result']}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      provider.setExpression(item['expression'] ?? '');
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
