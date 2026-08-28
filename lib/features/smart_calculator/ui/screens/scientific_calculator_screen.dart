import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../smart_calculator_provider.dart';
import '../../ui/theme/smart_calculator_theme.dart';
import 'graphing_screen.dart';
import 'matrix_editor_screen.dart';
import 'equation_solver_screen.dart';

class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  State<ScientificCalculatorScreen> createState() => _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState extends State<ScientificCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isShift = false;
  bool _isAlpha = false;
  bool _isDeg = true; // true = DEG, false = RAD

  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SmartCalculatorProvider(),
      child: Consumer<SmartCalculatorProvider>(
        builder: (context, provider, _) {
          final theme = SmartCalculatorTheme.getTheme(provider.themeStyle);
          final bg = theme.backgroundColor;

          return Scaffold(
            backgroundColor: bg,
            body: SafeArea(
              child: Column(
                children: [
                  // ─── Top Bar ───────────────────────────────────────────
                  _buildTopBar(context, provider, theme),

                  // ─── Display ───────────────────────────────────────────
                  _buildDisplay(provider, theme),

                  // ─── Mode Row (SHIFT / ALPHA / DEG / tabs) ─────────────
                  _buildModeRow(provider, theme),

                  // ─── Keyboard ──────────────────────────────────────────
                  Expanded(
                    child: _buildKeyboard(provider, theme),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Top Bar
  // ════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext context, SmartCalculatorProvider provider,
      SmartCalculatorTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: theme.backgroundColor,
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: theme.textColor, size: 20),
          ),
          const Spacer(),
          // Title
          Text(
            'الحاسبة الذكية',
            style: TextStyle(
              color: theme.textColor,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          // History button
          GestureDetector(
            onTap: () => _showHistory(context, theme),
            child: Icon(Icons.history_rounded, color: theme.textColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Theme picker
          GestureDetector(
            onTap: () => _showThemePicker(context, provider, theme),
            child: Icon(Icons.palette_outlined, color: theme.textColor, size: 22),
          ),
          const SizedBox(width: 14),
          // Menu
          GestureDetector(
            onTap: () => _showToolsMenu(context, theme),
            child: Icon(Icons.grid_view_rounded, color: theme.textColor, size: 22),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Display
  // ════════════════════════════════════════════════════
  Widget _buildDisplay(SmartCalculatorProvider provider, SmartCalculatorTheme theme) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160, maxHeight: 200),
      decoration: BoxDecoration(
        color: theme.displayColor,
        border: Border(
          top: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Expression
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              provider.expression.isEmpty ? '0' : provider.expression,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.7),
                fontSize: 22,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Result
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              provider.result.isEmpty ? '' : provider.result,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: provider.isError
                    ? Colors.redAccent
                    : const Color(0xFFFCD34D),
                fontSize: 42,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Mode Row
  // ════════════════════════════════════════════════════
  Widget _buildModeRow(
      SmartCalculatorProvider provider, SmartCalculatorTheme theme) {
    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          _modeChip('SHIFT', _isShift, const Color(0xFFF59E0B), () {
            setState(() => _isShift = !_isShift);
          }),
          const SizedBox(width: 6),
          _modeChip('ALPHA', _isAlpha, const Color(0xFF8B5CF6), () {
            setState(() => _isAlpha = !_isAlpha);
          }),
          const Spacer(),
          // Angle mode toggle
          GestureDetector(
            onTap: () => setState(() => _isDeg = !_isDeg),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: theme.operatorColor, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isDeg ? 'DEG' : 'RAD',
                style: TextStyle(
                  color: theme.operatorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Keyboard — Tab-based layout
  // ════════════════════════════════════════════════════
  Widget _buildKeyboard(
      SmartCalculatorProvider provider, SmartCalculatorTheme theme) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: theme.backgroundColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: theme.operatorColor,
            labelColor: theme.operatorColor,
            unselectedLabelColor: theme.textColor.withValues(alpha: 0.45),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: 'أساسي'),
              Tab(text: 'علمي'),
              Tab(text: 'متقدم'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildBasicKeyboard(provider, theme),
              _buildScientificKeyboard(provider, theme),
              _buildAdvancedKeyboard(provider, theme),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  Basic Keyboard
  // ════════════════════════════════════════════════════
  Widget _buildBasicKeyboard(
      SmartCalculatorProvider provider, SmartCalculatorTheme theme) {
    final rows = [
      ['AC', 'DEL', '(', ')'],
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', 'Ans', '+'],
      ['%', '='],
    ];

    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.all(6),
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Row(
              children: row.map((key) {
                final isWide = row.length == 2;
                return Expanded(
                  flex: isWide ? 1 : 1,
                  child: _buildKey(key, provider, theme),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Scientific Keyboard
  // ════════════════════════════════════════════════════
  Widget _buildScientificKeyboard(
      SmartCalculatorProvider provider, SmartCalculatorTheme theme) {
    final rows = [
      ['sin', 'cos', 'tan', 'AC', 'DEL'],
      ['sin⁻¹', 'cos⁻¹', 'tan⁻¹', '(', ')'],
      ['√x', 'x²', 'xʸ', '÷', '×'],
      ['log', 'ln', 'eˣ', '7', '8'],
      ['π', 'e', '|x|', '4', '5'],
      ['1/x', '10ˣ', '∫dx', '1', '2'],
      ['n!', 'mod', '=', '0', '.'],
    ];

    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.all(6),
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Row(
              children: row.map((key) => Expanded(
                child: _buildKey(key, provider, theme, isScientific: true),
              )).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Advanced Keyboard
  // ════════════════════════════════════════════════════
  Widget _buildAdvancedKeyboard(
      SmartCalculatorProvider provider, SmartCalculatorTheme theme) {
    final rows = [
      ['MATRIX', 'STAT', 'CMPLX', 'AC'],
      ['Σ', 'd/dx', '∫dx', 'DEL'],
      ['nPr', 'nCr', 'GCD', 'LCM'],
      ['→REC', '→POL', 'CEIL', 'FLOOR'],
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '-'],
      ['0', '.', '=', '+'],
    ];

    return Container(
      color: theme.backgroundColor,
      padding: const EdgeInsets.all(6),
      child: Column(
        children: rows.map((row) {
          return Expanded(
            child: Row(
              children: row.map((key) => Expanded(
                child: _buildKey(key, provider, theme, isAdvanced: true),
              )).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Key Builder
  // ════════════════════════════════════════════════════
  Widget _buildKey(
    String label,
    SmartCalculatorProvider provider,
    SmartCalculatorTheme theme, {
    bool isScientific = false,
    bool isAdvanced = false,
  }) {
    final bool isOp = ['÷', '×', '-', '+'].contains(label);
    final bool isEquals = label == '=';
    final bool isDelete = label == 'DEL' || label == 'AC';
    final bool isFunc = isScientific &&
        !['7','8','9','4','5','6','1','2','3','0','.','÷','×','-','+','(',')','AC','DEL'].contains(label);
    final bool isAdvFunc = isAdvanced &&
        !['7','8','9','4','5','6','1','2','3','0','.','÷','×','-','+','AC','DEL','='].contains(label);

    Color bgColor;
    Color textColor = theme.textColor;
    double fontSize = 15;

    if (isEquals) {
      bgColor = theme.operatorColor;
      textColor = Colors.white;
      fontSize = 22;
    } else if (isDelete) {
      bgColor = theme.actionColor.withValues(alpha: 0.85);
      textColor = Colors.white;
    } else if (isOp) {
      bgColor = theme.operatorColor.withValues(alpha: 0.8);
      textColor = Colors.white;
    } else if (isFunc || isAdvFunc) {
      bgColor = theme.functionColor;
      textColor = const Color(0xFFFCD34D); // Yellow for functions
      fontSize = 12;
    } else {
      bgColor = theme.numberColor;
    }

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            HapticFeedback.lightImpact();
            _handleKeyPress(label, provider);
          },
          child: Container(
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: isEquals || isOp ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Key Press Logic
  // ════════════════════════════════════════════════════
  void _handleKeyPress(String key, SmartCalculatorProvider provider) {
    switch (key) {
      case 'sin':
        provider.onKeyPressed('sin(');
        break;
      case 'cos':
        provider.onKeyPressed('cos(');
        break;
      case 'tan':
        provider.onKeyPressed('tan(');
        break;
      case 'sin⁻¹':
        provider.onKeyPressed('asin(');
        break;
      case 'cos⁻¹':
        provider.onKeyPressed('acos(');
        break;
      case 'tan⁻¹':
        provider.onKeyPressed('atan(');
        break;
      case '√x':
        provider.onKeyPressed('sqrt(');
        break;
      case 'x²':
        provider.onKeyPressed('^2');
        break;
      case 'xʸ':
        provider.onKeyPressed('^');
        break;
      case 'log':
        provider.onKeyPressed('log(');
        break;
      case 'ln':
        provider.onKeyPressed('ln(');
        break;
      case 'eˣ':
        provider.onKeyPressed('e^(');
        break;
      case '10ˣ':
        provider.onKeyPressed('10^(');
        break;
      case '1/x':
        provider.onKeyPressed('1/(');
        break;
      case '|x|':
        provider.onKeyPressed('abs(');
        break;
      case 'n!':
        provider.onKeyPressed('!');
        break;
      case 'π':
        provider.onKeyPressed('π');
        break;
      case 'e':
        provider.onKeyPressed('e');
        break;
      case '∫dx':
        provider.onKeyPressed('∫(');
        break;
      case 'd/dx':
        provider.onKeyPressed('d/dx(');
        break;
      case 'Σ':
        provider.onKeyPressed('Σ(');
        break;
      case 'MATRIX':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MatrixEditorScreen()));
        break;
      case 'mod':
        provider.onKeyPressed('%');
        break;
      case 'STAT':
      case 'CMPLX':
      case 'nPr':
      case 'nCr':
      case 'GCD':
      case 'LCM':
      case '→REC':
      case '→POL':
      case 'CEIL':
      case 'FLOOR':
        // Advanced features — show a snackbar for now
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$key — قريباً!', style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 1),
          ),
        );
        break;
      default:
        provider.onKeyPressed(key);
    }

    // Save history when = is pressed
    if (key == '=' && provider.result.isNotEmpty && !provider.isError) {
      setState(() {
        _history.insert(0, '${provider.expression} = ${provider.result}');
        if (_history.length > 30) _history.removeLast();
      });
    }
  }

  // ════════════════════════════════════════════════════
  //  History Modal
  // ════════════════════════════════════════════════════
  void _showHistory(BuildContext context, SmartCalculatorTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.displayColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('السجل',
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal')),
          const SizedBox(height: 12),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Text('لا يوجد سجل بعد',
                        style: TextStyle(
                            color: theme.textColor.withValues(alpha: 0.4),
                            fontFamily: 'Tajawal')))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(
                        _history[i],
                        style: TextStyle(
                            color: theme.textColor,
                            fontFamily: 'Tajawal',
                            fontSize: 15),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
          ),
          if (_history.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _history.clear());
                Navigator.pop(context);
              },
              child: const Text('مسح السجل',
                  style: TextStyle(
                      color: Colors.redAccent, fontFamily: 'Tajawal')),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Theme Picker
  // ════════════════════════════════════════════════════
  void _showThemePicker(BuildContext context, SmartCalculatorProvider provider,
      SmartCalculatorTheme theme) {
    final styles = [
      (SmartCalculatorThemeStyle.modernDark, 'داكن عصري', const Color(0xFF1E1E1E)),
      (SmartCalculatorThemeStyle.modernLight, 'فاتح عصري', const Color(0xFFF3F4F6)),
      (SmartCalculatorThemeStyle.scientificBlue, 'أزرق علمي', const Color(0xFF0F172A)),
      (SmartCalculatorThemeStyle.amoled, 'AMOLED أسود', Colors.black),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.displayColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اختر المظهر',
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: styles.map((s) {
                final isSelected = provider.themeStyle == s.$1;
                return GestureDetector(
                  onTap: () {
                    provider.setThemeStyle(s.$1);
                    Navigator.pop(context);
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: s.$3,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.operatorColor
                                : Colors.white24,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(s.$2,
                          style: TextStyle(
                              color: theme.textColor.withValues(alpha: 0.7),
                              fontSize: 11,
                              fontFamily: 'Tajawal')),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  Tools Menu
  // ════════════════════════════════════════════════════
  void _showToolsMenu(BuildContext context, SmartCalculatorTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.displayColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 8),
              child: Text('الأدوات الرياضية',
                  style: TextStyle(
                      color: theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal')),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                _toolItem(ctx, Icons.grid_on, 'المصفوفات', theme,
                    () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const MatrixEditorScreen()))),
                _toolItem(ctx, Icons.show_chart, 'الرسم البياني', theme,
                    () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const GraphingScreen()))),
                _toolItem(ctx, Icons.functions, 'المعادلات', theme,
                    () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const EquationSolverScreen()))),
                _toolItem(ctx, Icons.swap_horiz, 'تحويل الوحدات', theme, () {}),
                _toolItem(ctx, Icons.camera_alt_outlined, 'حل بالكاميرا', theme, () {}),
                _toolItem(ctx, Icons.bar_chart, 'الإحصاء', theme, () {}),
                _toolItem(ctx, Icons.science, 'الفيزياء', theme, () {}),
                _toolItem(ctx, Icons.biotech, 'الكيمياء', theme, () {}),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _toolItem(BuildContext ctx, IconData icon, String label,
      SmartCalculatorTheme theme, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.functionColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFCD34D), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  color: theme.textColor,
                  fontSize: 10.5,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
