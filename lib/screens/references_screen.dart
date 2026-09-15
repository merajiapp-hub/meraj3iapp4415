import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/reference_category.dart';
import '../theme/app_theme.dart';
import 'category_detail_screen.dart';
import '../widgets/curved_header.dart';
import 'references_search_screen.dart';

class ReferencesScreen extends StatelessWidget {
  const ReferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          CurvedHeader(
            title: 'مراجع أخرى',
            gradient: AppTheme.brandGradient,
            trailing: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReferencesSearchScreen()),
                );
              },
              icon: const Icon(Icons.search_rounded, color: Colors.white),
            ),
          ),
          Expanded(child: _buildRootCategories(isDark)),
        ],
      ),
    );
  }

  Widget _buildRootCategories(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reference_categories')
          .where('parentId', isNull: true)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs.toList() ?? [];
        docs.sort((a, b) {
          final aOrder = (a.data() as Map<String, dynamic>)['order'] as num? ?? 0;
          final bOrder = (b.data() as Map<String, dynamic>)['order'] as num? ?? 0;
          return aOrder.compareTo(bOrder);
        });
        if (docs.isEmpty) {
          return _buildEmptyState(isDark);
        }

        final cats = docs.map((d) => ReferenceCategory.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cats.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cat = cats[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailScreen(
                      category: cat,
                      breadcrumbs: const [],
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.folder, color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (cat.description != null && cat.description!.isNotEmpty)
                            Text(
                              cat.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'لا توجد فئات حالياً',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

