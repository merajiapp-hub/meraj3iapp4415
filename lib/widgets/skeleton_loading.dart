import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable skeleton loading widgets for list items, cards, etc.
class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
      highlightColor: isDark
          ? const Color(0xFF3D4A5C)
          : const Color(0xFFF8FAFC),
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D3748) : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton for a book list tile row
class SkeletonBookTile extends StatelessWidget {
  const SkeletonBookTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
      highlightColor: isDark
          ? const Color(0xFF3D4A5C)
          : const Color(0xFFF8FAFC),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Leading icon placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 14),
            // Text placeholders
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Trailing placeholder
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a book card (horizontal scroll)
class SkeletonBookCard extends StatelessWidget {
  const SkeletonBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
      highlightColor: isDark
          ? const Color(0xFF3D4A5C)
          : const Color(0xFFF8FAFC),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(left: 12, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Cover placeholder
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
            ),
            // Title placeholder
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    height: 12,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-page skeleton loader for a list of book tiles
class SkeletonBookList extends StatelessWidget {
  final int count;
  const SkeletonBookList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, index) => const SkeletonBookTile(),
    );
  }
}
