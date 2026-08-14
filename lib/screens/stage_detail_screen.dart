import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../data/books_data.dart';
import 'books_list_screen.dart';

class StageDetailScreen extends StatefulWidget {
  final String stageTitle;
  final String section;
  final Gradient gradient;
  final bool isActivated;
  final String stageCode;

  const StageDetailScreen({
    super.key,
    required this.stageTitle,
    required this.section,
    required this.gradient,
    required this.isActivated,
    required this.stageCode,
  });

  @override
  State<StageDetailScreen> createState() => _StageDetailScreenState();
}

class _StageDetailScreenState extends State<StageDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = (widget.gradient as LinearGradient).colors.first;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define sections based on stage type
    final List<Map<String, dynamic>> sections;

    if (widget.stageTitle.contains('الابتدائية')) {
      // المرحلة الابتدائية: زرّان فقط — الكتب المدرسية والدروس (التمارين داخل الدروس)
      sections = [
        {
          'title': 'الكتب المدرسية',
          'subtitle': 'الكتب الرسمية المعتمدة',
          'icon': Icons.menu_book_rounded,
          'category': 'الكتب المدرسية',
        },
        {
          'title': 'الدروس',
          'subtitle': 'دروس وتمارين محلولة',
          'icon': Icons.play_lesson_rounded,
          'category': 'الدروس',
        },
      ];
    } else {
      // باقي المراحل: الكتب المدرسية فقط
      sections = [
        {
          'title': 'الكتب المدرسية',
          'subtitle': 'الكتب الرسمية المعتمدة',
          'icon': Icons.menu_book_rounded,
          'category': 'الكتب المدرسية',
        },
      ];
    }

    return Scaffold(
      body: Column(
        children: [
          // ── الرأس بالتدرج ──
          Container(
            decoration: BoxDecoration(gradient: widget.gradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // شريط العودة والعنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.stageTitle,
                            style: GoogleFonts.tajawal(
                              fontSize: screenWidth < 360 ? 17 : 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // إحصائيات الملفات
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.folder_rounded,
                          label:
                              '${BooksData.allBooks.where((b) => b.section == widget.section).length} ملف',
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.layers_rounded,
                          label: '${sections.length} أقسام',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── شبكة البطاقات ──
          Expanded(
            child: AnimationLimiter(
              child: _buildSectionsGrid(sections, isDark, accentColor, screenWidth),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid(
    List<Map<String, dynamic>> sections,
    bool isDark,
    Color accentColor,
    double screenWidth,
  ) {
    // إذا كان قسم واحد فقط، نعرضه كبطاقة عريضة
    if (sections.length == 1) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: AnimationConfiguration.staggeredList(
          position: 0,
          duration: const Duration(milliseconds: 400),
          child: SlideAnimation(
            verticalOffset: 30,
            child: FadeInAnimation(
              child: _SectionCard(
                title: sections[0]['title'],
                subtitle: sections[0]['subtitle'],
                icon: sections[0]['icon'],
                category: sections[0]['category'],
                gradient: widget.gradient,
                isDark: isDark,
                isFull: true,
                onTap: () => _navigate(sections[0]['category']),
              ),
            ),
          ),
        ),
      );
    }

    // بطاقتان أو أكثر
    return GridView.builder(
      padding: EdgeInsets.all(screenWidth < 360 ? 14 : 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: screenWidth < 360 ? 0.85 : 0.9,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 400),
          columnCount: 2,
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: _SectionCard(
                title: sections[index]['title'],
                subtitle: sections[index]['subtitle'],
                icon: sections[index]['icon'],
                category: sections[index]['category'],
                gradient: widget.gradient,
                isDark: isDark,
                isFull: false,
                onTap: () => _navigate(sections[index]['category']),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigate(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BooksListScreen(
          stageTitle: widget.stageTitle,
          section: widget.section,
          categoryFilter: category,
          gradient: widget.gradient,
        ),
      ),
    );
  }
}

// ── شريحة إحصائية صغيرة ──
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.tajawal(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── بطاقة القسم ──
class _SectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final Gradient gradient;
  final bool isDark;
  final bool isFull;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.gradient,
    required this.isDark,
    required this.isFull,
    required this.onTap,
  });

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = (widget.gradient as LinearGradient).colors.first;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(
                    alpha: widget.isDark ? 0.18 : 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : accentColor.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة مع تدرج
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 14),

              // العنوان
              Text(
                widget.title,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // العنوان الفرعي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),

              // سهم "اضغط للدخول"
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                      alpha: widget.isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      'اضغط للدخول',
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
