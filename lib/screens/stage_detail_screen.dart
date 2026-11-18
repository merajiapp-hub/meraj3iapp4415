import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/book.dart';
import '../services/content_service.dart';
import '../widgets/book_card.dart';
import 'books_list_screen.dart';
import '../widgets/curved_header.dart';
import '../theme/responsive.dart';
import '../theme/app_theme.dart';

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

Stream<List<dynamic>> _booksCountStream(String section) {
  return FirebaseFirestore.instance
      .collection('books')
      .where('section', isEqualTo: section)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs);
}

class _StageDetailScreenState extends State<StageDetailScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final Stream<List<Book>> _stageBooksStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _stageBooksStream = ContentService.watchBooksBySection(widget.section);
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
          CurvedHeader(
            title: widget.stageTitle,
            gradient: widget.gradient,
            leadingIcon: Icons.school_rounded,
          ),

          // ── شريط بحث مخصص للمرحلة لعرض كتبها فقط ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ابحث في كتب ${widget.stageTitle}...',
                  hintStyle: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          if (_searchQuery.isNotEmpty)
            // ── عرض نتائج بحث كتب هذه المرحلة فقط ──
            Expanded(
              child: StreamBuilder<List<Book>>(
                stream: _stageBooksStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allBooks = snapshot.data ?? [];
                  final results = allBooks.where((b) {
                    final t = b.title.toLowerCase();
                    final s = b.subject.toLowerCase();
                    final g = b.grade.toLowerCase();
                    return t.contains(_searchQuery) ||
                        s.contains(_searchQuery) ||
                        g.contains(_searchQuery);
                  }).toList();

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد كتب مطابقة لبحثك في ${widget.stageTitle}',
                            style: GoogleFonts.tajawal(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return BookCard(
                        book: results[index],
                        gradient: widget.gradient,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: StreamBuilder<List<dynamic>>(
                stream: _booksCountStream(widget.section),
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  return Row(
                    children: [
                      _StatChip(icon: Icons.folder_rounded, label: '$count ملف'),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.layers_rounded,
                        label: '${sections.length} أقسام',
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── شبكة البطاقات ──
            Expanded(
              child: AnimationLimiter(
                child: _buildSectionsGrid(
                  sections,
                  isDark,
                  accentColor,
                  screenWidth,
                ),
              ),
            ),
          ],
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
    return GridView.builder(
      padding: EdgeInsets.all(screenWidth < 360 ? 14 : 20),
      gridDelegate: ResponsiveHelper.gridDelegate(
        maxExtent: 220,
        childAspectRatio: screenWidth < 360 ? 1.1 : 1.25,
        spacing: 14,
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
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = (widget.gradient as LinearGradient).colors.first;

    // البطاقة الكاملة (قسم واحد): عرض أفقي مضغوط
    if (widget.isFull) {
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
            height: 90,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(
                    alpha: widget.isDark ? 0.18 : 0.12,
                  ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      widget.icon,
                      color: widget.isDark ? Colors.white : accentColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // البطاقات في الـ Grid: عمودية مضغوطة
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
                  alpha: widget.isDark ? 0.18 : 0.12,
                ),
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
              // أيقونة القسم بدون بطاقة أو حواف
              SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  widget.icon,
                  color: widget.isDark ? Colors.white : accentColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: 10),

              // العنوان
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  widget.title,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark
                        ? Colors.white
                        : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 3),

              // العنوان الفرعي
              Text(
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
            ],
          ),
        ),
      ),
    );
  }
}
