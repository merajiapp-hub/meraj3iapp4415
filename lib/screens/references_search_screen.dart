import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';
import '../widgets/geometric_sliver_app_bar.dart';

class ReferencesSearchScreen extends StatefulWidget {
  const ReferencesSearchScreen({super.key});

  @override
  State<ReferencesSearchScreen> createState() => _ReferencesSearchScreenState();
}

class _ReferencesSearchScreenState extends State<ReferencesSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<Book> _allBooks = [];
  List<Book> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    
    _fetchAllBooks();
  }
  
  Future<void> _fetchAllBooks() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('books').get();
      if (mounted) {
        setState(() {
          _allBooks = snapshot.docs.map((d) => Book.fromMap(d.data(), d.id)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final searchLower = query.toLowerCase();
    setState(() {
      _isSearching = true;
      _searchResults = _allBooks.where((book) {
        return book.title.toLowerCase().contains(searchLower) ||
               book.category.toLowerCase().contains(searchLower) ||
               (book.subtitle?.toLowerCase().contains(searchLower) ?? false) ||
               book.subject.toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          GeometricSliverAppBar(
            title: 'البحث في المراجع',
            gradient: AppTheme.brandGradient,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildSearchBar(isDark),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_isSearching && _searchResults.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(isDark),
            )
          else if (_isSearching && _searchResults.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = _searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BookCard(
                        book: book,
                        gradient: AppTheme.primaryGradient,
                        isDark: isDark,
                      ),
                    );
                  },
                  childCount: _searchResults.length,
                ),
              ),
            )
          else
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 80,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ابحث عن الكتب في قسم المراجع...',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        style: GoogleFonts.tajawal(
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث بعنوان الكتاب، المؤلف، أو القسم...',
          hintStyle: GoogleFonts.tajawal(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لم يتم العثور على نتائج',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب البحث بكلمات مختلفة',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
