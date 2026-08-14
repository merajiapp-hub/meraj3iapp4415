import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/results_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/results_skeleton.dart';
import '../../widgets/top_students_section.dart';
import 'student_detail_screen.dart';
import 'competition_stats_screen.dart';

class ResultsListScreen extends StatefulWidget {
  final String title;
  final String csvUrl;
  final ExamType examType;
  final Gradient gradient;
  final String emoji;
  final double passScore;
  final double maxScore;
  final String scoreLabel;
  final bool showBranch;
  final String? initialSearchQuery;

  const ResultsListScreen({
    super.key,
    required this.title,
    required this.csvUrl,
    required this.examType,
    required this.gradient,
    required this.emoji,
    required this.passScore,
    required this.maxScore,
    required this.scoreLabel,
    this.showBranch = false,
    this.initialSearchQuery,
  });

  @override
  State<ResultsListScreen> createState() => _ResultsListScreenState();
}

class _ResultsListScreenState extends State<ResultsListScreen> {
  List<StudentResult> _allResults = [];
  List<StudentResult> _filtered = [];
  bool _loading = true;
  bool _backgroundUpdating = false;
  bool _fromCache = false;
  String? _error;

  final _searchCtrl = TextEditingController();
  String _filterWilaya = '';
  String _filterCenter = '';
  String _filterSchool = '';
  String _filterStatus = '';
  String _filterBranch = '';

  // لتأخير البحث حتى يتوقف المستخدم عن الكتابة (debounce)
  _Debouncer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    _searchDebouncer = _Debouncer(delay: const Duration(milliseconds: 300));
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchCtrl.text = widget.initialSearchQuery!;
    }
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebouncer?.run(_applyFilter);
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = _allResults.isEmpty; // loading فقط إذا لا توجد بيانات
      _error = null;
    });

    try {
      final results = await ResultsService.fetchResults(
        widget.examType,
        widget.csvUrl,
        forceRefresh: forceRefresh,
        onUpdate: (updatedResults) {
          // استُدعي عند وجود تحديث في الخلفية
          if (mounted) {
            setState(() {
              _allResults = updatedResults;
              _backgroundUpdating = false;
              _fromCache = false;
            });
            _applyFilter();
            _showUpdateSnackBar();
          }
        },
      );

      if (mounted) {
        setState(() {
          _allResults = results;
          _loading = false;
        });
        _applyFilter();

        // تحقق إذا كانت البيانات من Cache
        final stale = await ResultsService.isCacheStale(
            widget.examType, widget.csvUrl);
        if (stale && mounted) {
          setState(() => _backgroundUpdating = true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_allResults.isEmpty) {
            _error = 'تعذر تحميل النتائج. تأكد من اتصالك بالإنترنت.';
          }
          // إذا كانت هناك بيانات من Cache، لا نُظهر الخطأ
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _load(forceRefresh: true);
  }

  void _showUpdateSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'تم تحديث النتائج',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (!mounted) return;
    setState(() {
      _filtered = _allResults.where((r) {
        final matchSearch =
            q.isEmpty ||
            r.name.toLowerCase().contains(q) ||
            r.id.toLowerCase().contains(q);
        final matchWilaya = _filterWilaya.isEmpty || r.wilaya == _filterWilaya;
        final matchCenter = _filterCenter.isEmpty || r.center == _filterCenter;
        final matchSchool = _filterSchool.isEmpty || r.school == _filterSchool;
        final matchStatus = _filterStatus.isEmpty || r.status == _filterStatus;
        final matchBranch = _filterBranch.isEmpty || r.branch == _filterBranch;
        return matchSearch &&
            matchWilaya &&
            matchCenter &&
            matchSchool &&
            matchStatus &&
            matchBranch;
      }).toList();
    });
  }

  Set<String> get _availableBranches {
    return _allResults.map((r) => r.branch).where((b) => b.isNotEmpty).toSet();
  }

  Set<String> get _availableWilayas {
    return _allResults
        .where((r) => _filterBranch.isEmpty || r.branch == _filterBranch)
        .map((r) => r.wilaya)
        .where((w) => w.isNotEmpty)
        .toSet();
  }

  Set<String> get _availableCenters {
    return _allResults
        .where((r) => _filterBranch.isEmpty || r.branch == _filterBranch)
        .where((r) => _filterWilaya.isEmpty || r.wilaya == _filterWilaya)
        .map((r) => r.center)
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  Set<String> get _availableSchools {
    return _allResults
        .where((r) => _filterBranch.isEmpty || r.branch == _filterBranch)
        .where((r) => _filterWilaya.isEmpty || r.wilaya == _filterWilaya)
        .where((r) => _filterCenter.isEmpty || r.center == _filterCenter)
        .map((r) => r.school)
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Set<String> get _availableStatuses {
    return _allResults.map((r) => r.status).where((s) {
      if (s.isEmpty) return false;
      if (widget.examType != ExamType.bac &&
          (s == 'الدورة التكميلية' || s == 'تكميلي' || s == 'مؤهل للدورة التكميلية')) {
        return false;
      }
      return true;
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: (widget.gradient as LinearGradient).colors.first,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.title,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(gradient: widget.gradient),
                ),
              ),
              actions: [
                if (_backgroundUpdating)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _onRefresh,
                  tooltip: 'تحديث النتائج',
                ),
              ],
            ),

            if (_loading)
              const SliverFillRemaining(child: ResultsSkeleton())
            else if (_error != null && _allResults.isEmpty)
              SliverFillRemaining(child: _buildError())
            else ...[
              // Cache notice إذا كانت البيانات قديمة
              if (_fromCache)
                SliverToBoxAdapter(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded,
                            color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'يتم عرض آخر نسخة محفوظة — يُحدَّث في الخلفية',
                            style: GoogleFonts.tajawal(
                                fontSize: 12, color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Stats button
              if (_allResults.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompetitionStatsScreen(
                              title: widget.title,
                              allResults: _allResults,
                              examType: widget.examType,
                              gradient: widget.gradient,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_rounded),
                      label: Text('عرض الإحصائيات التفصيلية', style: GoogleFonts.tajawal()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (widget.gradient as LinearGradient).colors.first,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),

              // Top Students Section
              if (_allResults.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: TopStudentsSection(
                      students: _allResults,
                      gradient: widget.gradient,
                      emoji: widget.emoji,
                      passScore: widget.passScore,
                      maxScore: widget.maxScore,
                      scoreLabel: widget.scoreLabel,
                      examType: widget.examType,
                    ),
                  ),
                ),

              // Search & Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSearchBar(isDark),
                      const SizedBox(height: 12),
                      _buildFilters(isDark),
                    ],
                  ),
                ),
              ),

              // Results count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${_filtered.length} نتيجة',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_filterWilaya.isNotEmpty ||
                          _filterCenter.isNotEmpty ||
                          _filterSchool.isNotEmpty ||
                          _filterStatus.isNotEmpty ||
                          _filterBranch.isNotEmpty ||
                          _searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() {
                              _filterWilaya = '';
                              _filterCenter = '';
                              _filterSchool = '';
                              _filterStatus = '';
                              _filterBranch = '';
                            });
                            _applyFilter();
                          },
                          child: Text(
                            'مسح الفلاتر',
                            style: GoogleFonts.tajawal(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // List
              if (_filtered.isEmpty)
                SliverToBoxAdapter(child: _buildEmpty())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildStudentTile(_filtered[index], isDark),
                    childCount: _filtered.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
    );
  }





  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: GoogleFonts.tajawal(),
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم، الرقم، المدرسة، المركز، الولاية...',
          hintStyle:
              GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.primaryColor,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (widget.showBranch && _availableBranches.isNotEmpty) ...[
            _FilterChip(
              label: _filterBranch.isEmpty ? 'الشعبة' : _filterBranch,
              icon: Icons.category_rounded,
              isActive: _filterBranch.isNotEmpty,
              color: Colors.orange,
              onTap: () => _showPickerSheet(
                context: context,
                title: 'اختر الشعبة',
                items: ['', ..._availableBranches.toList()..sort()],
                selected: _filterBranch,
                onSelect: (v) {
                  setState(() {
                    _filterBranch = v;
                    _filterWilaya = '';
                    _filterCenter = '';
                    _filterSchool = '';
                  });
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (_availableWilayas.isNotEmpty) ...[
            _FilterChip(
              label: _filterWilaya.isEmpty ? 'الولاية' : _filterWilaya,
              icon: Icons.location_on_rounded,
              isActive: _filterWilaya.isNotEmpty,
              color: AppTheme.primaryColor,
              onTap: () => _showPickerSheet(
                context: context,
                title: 'اختر الولاية',
                items: ['', ..._availableWilayas.toList()..sort()],
                selected: _filterWilaya,
                onSelect: (v) {
                  setState(() {
                    _filterWilaya = v;
                    _filterCenter = '';
                    _filterSchool = '';
                  });
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (_availableCenters.isNotEmpty) ...[
            _FilterChip(
              label: _filterCenter.isEmpty ? 'المركز' : _filterCenter,
              icon: Icons.store_rounded,
              isActive: _filterCenter.isNotEmpty,
              color: Colors.blue,
              onTap: () => _showPickerSheet(
                context: context,
                title: 'اختر المركز',
                items: ['', ..._availableCenters.toList()..sort()],
                selected: _filterCenter,
                onSelect: (v) {
                  setState(() {
                    _filterCenter = v;
                    _filterSchool = '';
                  });
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (_availableSchools.isNotEmpty) ...[
            _FilterChip(
              label: _filterSchool.isEmpty ? 'المدرسة' : _filterSchool,
              icon: Icons.school_rounded,
              isActive: _filterSchool.isNotEmpty,
              color: Colors.purple,
              onTap: () => _showPickerSheet(
                context: context,
                title: 'اختر المدرسة',
                items: ['', ..._availableSchools.toList()..sort()],
                selected: _filterSchool,
                onSelect: (v) {
                  setState(() => _filterSchool = v);
                  _applyFilter();
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
          _FilterChip(
            label: _filterStatus.isEmpty ? 'الحالة' : _filterStatus,
            icon: Icons.check_circle_outline_rounded,
            isActive: _filterStatus.isNotEmpty,
            color: Colors.green,
            onTap: () => _showPickerSheet(
              context: context,
              title: 'اختر الحالة',
              items: ['', ..._availableStatuses.toList()..sort()],
              selected: _filterStatus,
              onSelect: (v) {
                setState(() => _filterStatus = v);
                _applyFilter();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerSheet({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String selected,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: items.map((item) {
                return ListTile(
                  title: Text(
                    item.isEmpty ? 'الكل' : item,
                    style: GoogleFonts.tajawal(),
                  ),
                  trailing: item == selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(item);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStudentTile(StudentResult student, bool isDark) {
    final statusColor = student.isPassed
        ? const Color(0xFF16A34A)
        : student.isAbsent
            ? Colors.grey
            : student.isExpelled
                ? Colors.purple
                : student.isComplementary
                    ? Colors.orange
                    : Colors.red;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDetailScreen(
            student: student,
            gradient: widget.gradient,
            emoji: widget.emoji,
            passScore: widget.passScore,
            maxScore: widget.maxScore,
            scoreLabel: widget.scoreLabel,
            allResults: _allResults,
            examType: widget.examType,
            title: widget.title,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            // Status circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  student.isPassed
                      ? '✓'
                      : student.isAbsent
                          ? '?'
                          : student.isComplementary
                              ? '🔄'
                              : '✗',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name.isNotEmpty
                        ? student.name
                        : 'مترشح رقم ${student.id}',
                    style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (student.school.isNotEmpty)
                        Flexible(
                          child: Text(
                            student.school,
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (student.school.isNotEmpty &&
                          student.wilaya.isNotEmpty)
                        Text(' • ',
                            style: TextStyle(color: Colors.grey[400])),
                      if (student.wilaya.isNotEmpty)
                        Text(
                          student.wilaya,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Score & status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (student.score != null)
                  Text(
                    student.score!.toStringAsFixed(2),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    student.status,
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded,
                size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تعديل معايير البحث',
              style: GoogleFonts.tajawal(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 64, color: Colors.orange),
            const SizedBox(height: 20),
            Text(
              'تعذر تحميل النتائج',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? 'تأكد من اتصالك بالإنترنت وحاول مجدداً',
              style: GoogleFonts.tajawal(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Debouncer ──────────────────────────────────────────────────────────────

class _Debouncer {
  final Duration delay;
  _Debouncer({required this.delay});

  bool _cancelled = false;

  void run(VoidCallback action) {
    _cancelled = false;
    Future.delayed(delay, () {
      if (!_cancelled) action();
    });
  }

  void cancel() => _cancelled = true;
}

// ── FilterChip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? color : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
