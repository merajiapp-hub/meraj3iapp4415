import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/books_data.dart';
import '../models/book.dart';
import '../theme/app_theme.dart';
import '../widgets/geometric_sliver_app_bar.dart';
import 'pdf_viewer_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Book> _searchResults = [];
  bool _isSearching = false;
  String _activeFilter = 'الكل';

  static const List<String> _filters = ['الكل', 'ابتدائي', 'إعدادي', 'ثانوي'];
  static const List<String> _quickSearches = [
    'رياضيات',
    'لغة عربية',
    'علوم',
    'لغة فرنسية',
    'تاريخ',
    'فيزياء',
    'كيمياء',
  ];
  final List<String> _searchHistory = [];

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
      _searchResults = BooksData.allBooks.where((book) {
        // Filter by section
        if (_activeFilter != 'الكل') {
          if (_activeFilter == 'ابتدائي' && !book.section.contains('الابتدائي')) {
            return false;
          }
          if (_activeFilter == 'إعدادي' && !book.section.contains('الإعدادي')) {
            return false;
          }
          if (_activeFilter == 'ثانوي' && !book.section.contains('الثانو')) {
            return false;
          }
        }
        return book.title.toLowerCase().contains(searchLower) ||
            book.section.toLowerCase().contains(searchLower) ||
            book.grade.toLowerCase().contains(searchLower) ||
            book.category.toLowerCase().contains(searchLower);
      }).toList();
    });
  }

  void _setFilter(String filter) {
    setState(() => _activeFilter = filter);
    _onSearchChanged(_searchController.text);
  }

  void _applyQuickSearch(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
    if (!_searchHistory.contains(query)) {
      setState(() => _searchHistory.insert(0, query));
      if (_searchHistory.length > 8) _searchHistory.removeLast();
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            const GeometricSliverAppBar(
              title: 'البحث',
              icon: Icons.search_rounded,
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.tajawal(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن كتاب، مادة، مرحلة...',
                    hintStyle: GoogleFonts.tajawal(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isActive = _activeFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: GoogleFonts.tajawal(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          selected: isActive,
                          onSelected: (_) => _setFilter(filter),
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.08,
                          ),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                            color: isActive
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Results count
            if (_isSearching)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'تم العثور على ${_searchResults.length} نتيجة',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            // Results / Empty states
            if (!_isSearching && _searchController.text.isEmpty)
              SliverToBoxAdapter(child: _buildInitialState())
            else if (_searchResults.isEmpty && _isSearching)
              SliverFillRemaining(child: _buildNoResultsState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildResultCard(
                      context,
                      _searchResults[index],
                      isDark,
                    ),
                    childCount: _searchResults.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick suggestions
          Text(
            'اقتراحات سريعة',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickSearches
                .map(
                  (q) => GestureDetector(
                    onTap: () => _applyQuickSearch(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            q,
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          // Search history
          if (_searchHistory.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'عمليات البحث الأخيرة',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _searchHistory.clear()),
                  child: Text(
                    'مسح الكل',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._searchHistory.map(
              (h) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.history_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
                title: Text(h, style: GoogleFonts.tajawal(fontSize: 14)),
                trailing: Icon(
                  Icons.north_west_rounded,
                  size: 14,
                  color: Colors.grey[400],
                ),
                onTap: () => _applyQuickSearch(h),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Top books
          Text(
            'الأكثر بحثاً',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          ...BooksData.allBooks
              .take(5)
              .map(
                (b) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.15
                              : 0.04,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      b.title,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        b.grade,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerScreen(
                          pdfUrl: b.url,
                          title: b.title,
                          book: b,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب كلمات مختلفة أو غيّر الفلتر',
            style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Book book, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            title: Text(
              book.title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      book.grade,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.section,
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    pdfUrl: book.url,
                    title: book.title,
                    stageName: book.section,
                    sectionName: book.category,
                    book: book,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
