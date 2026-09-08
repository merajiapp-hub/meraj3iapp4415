import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import 'scientific_calculator_screen.dart';
import 'graphing_screen.dart';
import 'equation_solver_screen.dart';
import 'matrix_editor_screen.dart';
import 'conversions_screen.dart';
import 'advanced_math_lab_screen.dart';

class SmartCalculatorScreen extends StatefulWidget {
  const SmartCalculatorScreen({super.key});

  @override
  State<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends State<SmartCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundDark
          : AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          'Calculatrice avancée',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Calculatrice'),
            Tab(text: 'Équations'),
            Tab(text: 'Graphique'),
            Tab(text: 'Matrices'),
            Tab(text: 'Conversions'),
            Tab(text: 'مختبر الرياضيات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swipe to avoid conflicting with graph/matrix gestures
        children: [
          const ScientificCalculatorScreen(), // Tab 1: الحاسبة
          const EquationSolverScreen(), // Tab 2: المعادلات
          const GraphingScreen(), // Tab 3: الرسم البياني
          const MatrixEditorScreen(), // Tab 4: المصفوفات
          const ConversionsScreen(), // Tab 5: التحويلات (To be implemented or replaced)
          const AdvancedMathLabScreen(),
        ],
      ),
    );
  }
}
