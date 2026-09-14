import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reference_category.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';
import '../widgets/curved_header.dart';

class CategoryDetailScreen extends StatelessWidget {
  final ReferenceCategory category;
  final List<ReferenceCategory> breadcrumbs;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.breadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPath = [...breadcrumbs, category];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurvedHeader(
            title: category.name,
            gradient: AppTheme.brandGradient,
          ),
          _buildBreadcrumbs(context, currentPath, isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubCategories(isDark),
                  const SizedBox(height: 16),
                  _buildBooks(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, List<ReferenceCategory> path, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == '/references'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home_rounded, size: 18, color: isDark ? Colors.blue[300] : AppTheme.primaryColor),
              ),
            ),
            ...path.map((cat) {
              final isLast = cat.id == category.id;
              return Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_left_rounded, size: 16, color: Colors.grey),
                  ),
                  InkWell(
                    onTap: isLast
                        ? null
                        : () {
                            int pops = path.length - path.indexOf(cat) - 1;
                            for (int i = 0; i < pops; i++) {
                              Navigator.pop(context);
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLast 
                            ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(12),
                        border: isLast ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)) : null,
                      ),
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          color: isLast
                              ? AppTheme.primaryColor
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategories(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reference_categories')
          .where('parentId', isEqualTo: category.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aOrder = (a.data() as Map<String, dynamic>)['order'] as num? ?? 0;
            final bOrder = (b.data() as Map<String, dynamic>)['order'] as num? ?? 0;
            return aOrder.compareTo(bOrder);
          });
        if (docs.isEmpty) return const SizedBox.shrink();

        final cats = docs.map((d) => ReferenceCategory.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text('الفئات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cats.length,
              itemBuilder: (context, index) {
                final cat = cats[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailScreen(
                          category: cat,
                          breadcrumbs: [...breadcrumbs, category],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.folder, color: AppTheme.primaryColor, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBooks(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('categoryIds', arrayContains: category.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        final books = docs.map((d) => Book.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text('المراجع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return BookCard(
                  book: books[index],
                  gradient: AppTheme.primaryGradient,
                  isDark: isDark,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
