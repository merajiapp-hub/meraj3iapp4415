import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/books_data.dart';
import '../widgets/geometric_sliver_app_bar.dart';
import 'stage_detail_screen.dart';

class StagesScreen extends StatelessWidget {
  const StagesScreen({super.key});

  static const List<Map<String, dynamic>> _stages = [
    {
      'title': 'المرحلة الابتدائية',
      'subtitle': 'السنوات 1 إلى 6',
      'icon': Icons.child_care_rounded,
      'section': BooksData.sPrimary,
      'colors': [Color(0xFF14B8A6), Color(0xFF0D9488)],
    },
    {
      'title': 'المرحلة الإعدادية',
      'subtitle': 'السنوات 1 إلى 4',
      'icon': Icons.school_rounded,
      'section': BooksData.sMiddle,
      'colors': [Color(0xFFF59E0B), Color(0xFFD97706)],
    },
    {
      'title': 'الثانوية - العلوم',
      'subtitle': 'السنوات 5 و 6 و 7',
      'icon': Icons.science_rounded,
      'section': BooksData.sHighSc,
      'colors': [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    },
    {
      'title': 'الثانوية - رياضيات',
      'subtitle': 'السنة 7',
      'icon': Icons.calculate_rounded,
      'section': BooksData.sHighMath,
      'colors': [Color(0xFF10B981), Color(0xFF059669)],
    },
    {
      'title': 'الثانوية - آداب عصرية',
      'subtitle': 'السنوات 5 و 6 و 7',
      'icon': Icons.menu_book_rounded,
      'section': BooksData.sHighLit,
      'colors': [Color(0xFFEF4444), Color(0xFFB91C1C)],
    },
    {
      'title': 'الثانوية - آداب أصلية',
      'subtitle': 'السنوات 5 و 6 و 7',
      'icon': Icons.history_edu_rounded,
      'section': BooksData.sHighOrig,
      'colors': [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const GeometricSliverAppBar(
            title: 'المراحل الدراسية',
            icon: Icons.layers_rounded,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final stage = _stages[index];
                final colors = stage['colors'] as List<Color>;
                final gradient = LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                );

                return _StageCard(
                  title: stage['title'],
                  subtitle: stage['subtitle'],
                  icon: stage['icon'],
                  gradient: gradient,
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StageDetailScreen(
                          stageTitle: stage['title'],
                          section: stage['section'],
                          gradient: gradient,
                          isActivated: true,
                          stageCode: '',
                        ),
                      ),
                    );
                  },
                );
              }, childCount: _stages.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final bool isDark;
  final VoidCallback onTap;

  const _StageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _hoverController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) {
          _hoverController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _hoverController.reverse(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFF1F5F9),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.colors.first.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.gradient.colors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: widget.gradient.colors.first,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
