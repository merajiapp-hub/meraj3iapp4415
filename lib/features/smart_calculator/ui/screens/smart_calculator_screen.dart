import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../theme/app_theme.dart';
import 'scientific_calculator_screen.dart';
import 'graphing_screen.dart';
import 'equation_solver_screen.dart';
import 'matrix_editor_screen.dart';

class SmartCalculatorScreen extends StatefulWidget {
  const SmartCalculatorScreen({super.key});

  @override
  State<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends State<SmartCalculatorScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, right: 48, bottom: 16),
              title: Text(
                'الحاسبة الذكية',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Icon(Icons.calculate_rounded, size: 140, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر الأداة المناسبة',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _calculatorFeatures.length,
                    itemBuilder: (context, index) {
                      final feature = _calculatorFeatures[index];
                      return _buildFeatureCard(feature, isDark);
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_CalcFeature feature, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (feature.page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => feature.page!));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('سيتم تفعيل ميزة "${feature.title}" قريباً!')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: feature.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(feature.icon, color: feature.color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              feature.title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              feature.description,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget? page;

  _CalcFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.page,
  });
}

final List<_CalcFeature> _calculatorFeatures = [
  _CalcFeature(
    title: 'الحاسبة العلمية',
    description: 'عمليات حسابية، دوال مثلثية، أسس، وجذور.',
    icon: Icons.calculate_rounded,
    color: const Color(0xFF3B82F6),
    page: const ScientificCalculatorScreen(),
  ),
  _CalcFeature(
    title: 'الرسم البياني',
    description: 'رسم الدوال والمعادلات وتحليلها بيانياً.',
    icon: Icons.auto_graph_rounded,
    color: const Color(0xFF10B981),
    page: const GraphingScreen(),
  ),
  _CalcFeature(
    title: 'حل المعادلات والتفاضل',
    description: 'حل المعادلات الخطية والتربيعية، والمشتقات والتكامل خطوة بخطوة.',
    icon: Icons.functions_rounded,
    color: const Color(0xFF8B5CF6),
    page: const EquationSolverScreen(),
  ),
  // _CalcFeature(
  //   title: 'التفاضل والتكامل',
  //   description: 'مشتقات، تكامل محدد وغير محدد، نهايات.',
  //   icon: Icons.integration_instructions_rounded,
  //   color: const Color(0xFFF59E0B),
  //   page: null,
  // ),
  _CalcFeature(
    title: 'الإحصاء',
    description: 'متوسط، تباين، انحراف معياري، وتوزيعات.',
    icon: Icons.query_stats_rounded,
    color: const Color(0xFFEC4899),
    page: const EquationSolverScreen(
      title: 'الإحصاء الذكي',
      hintText: 'أدخل القيم أو التوزيع...',
    ),
  ),
  _CalcFeature(
    title: 'المصفوفات',
    description: 'جمع، ضرب، محدد، ومعكوس المصفوفات.',
    icon: Icons.grid_on_rounded,
    color: const Color(0xFF14B8A6),
    page: const MatrixEditorScreen(),
  ),
  _CalcFeature(
    title: 'الأعداد المركبة',
    description: 'عمليات الأعداد التخيلية والصيغ القطبية.',
    icon: Icons.data_object_rounded,
    color: const Color(0xFFEF4444),
    page: const EquationSolverScreen(
      title: 'الأعداد المركبة',
      hintText: 'أدخل العملية (مثال: (2+3i)*(4-i))...',
    ),
  ),
  _CalcFeature(
    title: 'حل بالكاميرا',
    description: 'صور المسألة الرياضية ودع الذكاء الاصطناعي يحلها.',
    icon: Icons.camera_alt_rounded,
    color: const Color(0xFF6366F1),
    page: null,
  ),
  _CalcFeature(
    title: 'السجل والمفضلة',
    description: 'راجع عملياتك السابقة والمسائل المفضلة.',
    icon: Icons.history_rounded,
    color: const Color(0xFF64748B),
    page: null,
  ),
];
