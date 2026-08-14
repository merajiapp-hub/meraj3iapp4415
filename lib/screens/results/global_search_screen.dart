import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/competition_model.dart';
import '../../providers/favorite_results_provider.dart';
import '../../services/results_service.dart';
import '../../theme/app_theme.dart';
import 'student_detail_screen.dart';

// ─── Helpers (duplicated from results_home_screen to avoid circular imports) ──

Gradient _gradientFor(CompetitionType type) {
  switch (type) {
    case CompetitionType.concours:
      return AppTheme.deepBlueGradient;
    case CompetitionType.brevet:
      return AppTheme.greenGradient;
    case CompetitionType.bac:
      return AppTheme.secondaryGradient;
    case CompetitionType.complementary:
      return AppTheme.purpleGradient;
    case CompetitionType.excellence:
      return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]);
    case CompetitionType.generic:
      return const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]);
  }
}

ExamType _examFor(CompetitionType t) {
  switch (t) {
    case CompetitionType.concours: return ExamType.concours;
    case CompetitionType.brevet: return ExamType.brevet;
    case CompetitionType.bac: return ExamType.bac;
    case CompetitionType.complementary: return ExamType.complementary;
    case CompetitionType.excellence: return ExamType.excellence;
    case CompetitionType.generic: return ExamType.bac;
  }
}

double _passFor(CompetitionType t) => t == CompetitionType.concours ? 85.0 : 10.0;
double _maxFor(CompetitionType t) => t == CompetitionType.concours ? 200.0 : 20.0;
String _labelFor(CompetitionType t) => t == CompetitionType.concours ? 'المجموع' : 'المعدل';
// ────────────────────────────────────────────────────────────────────────────

class _SearchResult {
  final StudentResult student;
  final CompetitionModel competition;
  final List<StudentResult> allResults;

  _SearchResult({required this.student, required this.competition, required this.allResults});
}

class GlobalSearchScreen extends StatefulWidget {
  final List<CompetitionModel> competitions;

  const GlobalSearchScreen({super.key, required this.competitions});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  // cached data per competition
  final Map<String, List<StudentResult>> _cache = {};
  bool _loadingData = false;
  bool _searching = false;

  List<_SearchResult> _results = [];
  String _lastQuery = '';

  // Debounce
  DateTime? _lastType;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
    _focus.requestFocus();
    _preloadPublished();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  // سبق تحميل نتائج المسابقات المنشورة
  Future<void> _preloadPublished() async {
    final published = widget.competitions.where((c) => c.isPublished && c.link.isNotEmpty).toList();
    if (published.isEmpty) return;
    setState(() => _loadingData = true);
    for (final comp in published) {
      if (!_cache.containsKey(comp.rawKey)) {
        try {
          final r = await ResultsService.fetchResults(_examFor(comp.type), comp.link);
          _cache[comp.rawKey] = r;
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _loadingData = false);
    // إذا كان هناك نص مكتوب مسبقاً
    if (_ctrl.text.trim().length >= 2) _doSearch(_ctrl.text.trim());
  }

  void _onTextChanged() {
    final q = _ctrl.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;
    _lastType = DateTime.now();
    if (q.length < 2) {
      if (mounted) setState(() { _results = []; _searching = false; });
      return;
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _lastType != null &&
          DateTime.now().difference(_lastType!) >= const Duration(milliseconds: 300)) {
        _doSearch(q);
      }
    });
  }

  void _doSearch(String q) {
    if (!mounted) return;
    setState(() => _searching = true);
    final lower = q.toLowerCase();
    final results = <_SearchResult>[];

    for (final comp in widget.competitions) {
      if (!_cache.containsKey(comp.rawKey)) continue;
      final all = _cache[comp.rawKey]!;
      for (final s in all) {
        if (_matchesQuery(s, lower)) {
          results.add(_SearchResult(student: s, competition: comp, allResults: all));
          if (results.length >= 50) break; // حد أقصى لمنع التجمد
        }
      }
      if (results.length >= 50) break;
    }

    if (mounted) setState(() { _results = results; _searching = false; });
  }

  bool _matchesQuery(StudentResult s, String q) {
    return s.name.toLowerCase().contains(q) ||
        s.id.toLowerCase().contains(q) ||
        s.school.toLowerCase().contains(q) ||
        s.center.toLowerCase().contains(q) ||
        s.wilaya.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.tajawal(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'ابحث في جميع المسابقات...',
            hintStyle: GoogleFonts.tajawal(color: Colors.grey[400], fontSize: 15),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () { _ctrl.clear(); setState(() => _results = []); },
                  )
                : null,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loadingData && _cache.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('جاري تحميل بيانات البحث...', style: GoogleFonts.tajawal(color: Colors.grey[500])),
          ],
        ),
      );
    }

    if (_ctrl.text.trim().length < 2) {
      return _buildHint(isDark);
    }

    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2));
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('لا توجد نتائج لـ "${_ctrl.text}"', style: GoogleFonts.tajawal(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('تأكد من كتابة الاسم أو الرقم بشكل صحيح', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '${_results.length} نتيجة${_results.length >= 50 ? ' (أول 50)' : ''}',
                style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (_, i) => _buildResultTile(_results[i], isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHint(bool isDark) {
    final favorites = context.watch<FavoriteResultsProvider>().items;
    final recents = context.watch<FavoriteResultsProvider>().recents;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تلميح البحث
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 يمكنك البحث بـ:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                for (final hint in ['الاسم الكامل', 'رقم التسجيل', 'اسم المؤسسة', 'اسم المركز', 'الولاية'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check_rounded, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(hint, style: GoogleFonts.tajawal(fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // المفضلة
          if (favorites.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('❤️ نتائجك المفضلة', style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...favorites.take(3).map((item) => _buildHintTile(item, isDark)),
          ],

          // آخر المشاهدات
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('🕒 آخر المشاهدات', style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...recents.take(5).map((item) => _buildHintTile(item, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildHintTile(FavoriteResultItem item, bool isDark) {
    final statusColor = item.result.isPassed
        ? const Color(0xFF16A34A)
        : item.result.status == 'الدورة التكميلية' ? Colors.blue : Colors.red;
    return ListTile(
      onTap: () {
        final comp = widget.competitions.firstWhere(
          (c) => _examFor(c.type) == item.examType,
          orElse: () => widget.competitions.first,
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => StudentDetailScreen(
            student: item.result,
            gradient: _gradientFor(comp.type),
            emoji: comp.displayEmoji,
            passScore: _passFor(comp.type),
            maxScore: _maxFor(comp.type),
            scoreLabel: _labelFor(comp.type),
            allResults: _cache[comp.rawKey] ?? [],
            examType: item.examType,
            title: comp.title,
          ),
        ));
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: statusColor.withValues(alpha: 0.12),
        child: Text(
          item.result.isPassed ? '✓' : '✗',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        item.result.name.isNotEmpty ? item.result.name : item.result.id,
        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(item.title, style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500])),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(item.result.status, style: GoogleFonts.tajawal(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildResultTile(_SearchResult r, bool isDark) {
    final s = r.student;
    final comp = r.competition;
    final statusColor = s.isPassed
        ? const Color(0xFF16A34A)
        : s.isAbsent ? Colors.orange : s.status == 'الدورة التكميلية' ? Colors.blue : Colors.red;
    final favProvider = context.read<FavoriteResultsProvider>();
    final isFav = favProvider.isFavorite(s.id, _examFor(comp.type));

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDetailScreen(
            student: s,
            gradient: _gradientFor(comp.type),
            emoji: comp.displayEmoji,
            passScore: _passFor(comp.type),
            maxScore: _maxFor(comp.type),
            scoreLabel: _labelFor(comp.type),
            allResults: r.allResults,
            examType: _examFor(comp.type),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12), shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  s.isPassed ? '✓' : s.isAbsent ? '?' : s.status == 'الدورة التكميلية' ? '🔄' : '✗',
                  style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name.isNotEmpty ? s.name : 'مترشح رقم ${s.id}',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(comp.displayEmoji, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        comp.title,
                        style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[500]),
                      ),
                      if (s.wilaya.isNotEmpty) ...[
                        Text(' • ', style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                        Text(s.wilaya, style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (s.score != null)
                  Text(s.score!.toStringAsFixed(2),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: statusColor)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => favProvider.toggleFavorite(s, _examFor(comp.type), comp.title, context),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 16,
                        color: isFav ? Colors.red : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(s.status, style: GoogleFonts.tajawal(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
