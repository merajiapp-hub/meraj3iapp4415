import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/drive_url_service.dart';
import '../../../services/admin_activity_service.dart';

const _kBg       = Color(0xFF0D1117);
const _kSurface  = Color(0xFF161B22);
const _kSurface2 = Color(0xFF21262D);
const _kBorder   = Color(0xFF30363D);
const _kPrimary  = Color(0xFF1DB954);
const _kAccent   = Color(0xFF58A6FF);
const _kRed      = Color(0xFFFF4D4F);
const _kOrange   = Color(0xFFFF9A3C);
const _kPurple   = Color(0xFFAB7AFF);
const _kText     = Color(0xFFE6EDF3);
const _kTextDim  = Color(0xFF8B949E);

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});
  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  bool _isLoading = false;
  String _filterSection = 'الكل';
  String _sortBy = 'newest';
  late final TabController _tabController;

  static const _sections = ['الكل', 'ابتدائي', 'متوسط', 'ثانوي', 'مسابقات', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _filterSection = _sections[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filter(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final title    = (d['title']    ?? '').toString().toLowerCase();
      final author   = (d['author']   ?? '').toString().toLowerCase();
      final section  = (d['section']  ?? d['stage'] ?? '').toString();
      final grade    = (d['grade']    ?? d['year']  ?? '').toString().toLowerCase();
      final category = (d['category'] ?? d['type']  ?? d['bookType'] ?? '').toString().toLowerCase();
      final subject  = (d['subject']  ?? d['material'] ?? '').toString().toLowerCase();
      final matchSearch = _search.isEmpty ||
          title.contains(_search) || author.contains(_search) ||
          grade.contains(_search) || category.contains(_search) ||
          subject.contains(_search);
      final matchSection = _filterSection == 'الكل' ||
          section.contains(_filterSection) ||
          (_filterSection == 'أخرى' &&
              !_sections.skip(1).take(4).any((s) => section.contains(s)));
      return matchSearch && matchSection;
    }).toList();
  }

  List<QueryDocumentSnapshot> _sort(List<QueryDocumentSnapshot> docs) {
    final sorted = List<QueryDocumentSnapshot>.from(docs);
    sorted.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      switch (_sortBy) {
        case 'opens':
          return ((db['openCount'] ?? db['opens'] ?? 0) as int)
              .compareTo((da['openCount'] ?? da['opens'] ?? 0) as int);
        case 'downloads':
          return ((db['downloadCount'] ?? db['downloads'] ?? 0) as int)
              .compareTo((da['downloadCount'] ?? da['downloads'] ?? 0) as int);
        case 'alpha':
          return (da['title'] ?? '').toString()
              .compareTo((db['title'] ?? '').toString());
        default:
          final at = (da['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bt = (db['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
      }
    });
    return sorted;
  }

  Future<void> _deleteBook(String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'حذف الكتاب',
        message: 'هل أنت متأكد من حذف\n"$title"؟\nلا يمكن التراجع عن هذا الإجراء.',
        confirmLabel: 'حذف', confirmColor: _kRed,
        icon: Icons.delete_forever_rounded,
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('books').doc(docId).delete();
      await AdminActivityService.log(
        type: AdminActivityType.bookDeleted,
        title: 'حذف كتاب', description: 'تم حذف الكتاب: "$title"',
      );
      if (mounted) _snack('تم حذف الكتاب بنجاح', _kPrimary);
    } catch (e) {
      if (mounted) _snack('خطأ: $e', _kRed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String docId, Map<String, dynamic> d, String title) async {
    final cur = (d['is_active'] ?? d['isActive'] ?? true) as bool;
    try {
      await FirebaseFirestore.instance.collection('books').doc(docId).update({
        'is_active': !cur, 'isActive': !cur,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _snack(!cur ? 'تم تفعيل "$title"' : 'تم إيقاف "$title"',
            !cur ? _kPrimary : _kOrange);
      }
    } catch (e) {
      if (mounted) _snack('خطأ: $e', _kRed);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.tajawal(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [_buildAppBar()],
              body: _buildBody(),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 164,
      pinned: true,
      backgroundColor: _kSurface,
      iconTheme: const IconThemeData(color: _kText),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A2A1A), Color(0xFF0D1B2A)],
              ),
            ),
          ),
          Positioned(right: -20, top: -20,
              child: Container(width: 130, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _kPrimary.withValues(alpha: 0.07)))),
          Positioned(left: -30, bottom: -30,
              child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _kAccent.withValues(alpha: 0.05)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: _kPrimary, size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('مكتبة الإدارة', style: GoogleFonts.tajawal(
                      color: _kText, fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('إدارة الكتب المضافة', style: GoogleFonts.tajawal(
                      color: _kTextDim, fontSize: 13)),
                ]),
              ]),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.tajawal(color: _kText, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'بحث بالعنوان، المادة، المرحلة...',
                      hintStyle: GoogleFonts.tajawal(color: _kTextDim, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: _kTextDim, size: 20),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: _kTextDim, size: 18),
                              onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                          : null,
                      filled: true,
                      fillColor: _kSurface2.withValues(alpha: 0.9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: Column(children: [
          TabBar(
            controller: _tabController,
            isScrollable: true, tabAlignment: TabAlignment.start,
            indicatorColor: _kPrimary, indicatorWeight: 2.5,
            labelColor: _kPrimary, unselectedLabelColor: _kTextDim,
            labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12),
            tabs: _sections.map((s) => Tab(text: s)).toList(),
          ),
          Container(
            color: _kSurface,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                const Icon(Icons.sort_rounded, color: _kTextDim, size: 16),
                const SizedBox(width: 6),
                Text('ترتيب:', style: GoogleFonts.tajawal(color: _kTextDim, fontSize: 12)),
                const SizedBox(width: 8),
                _sortChip('newest',    'الاحدث',        Icons.schedule_rounded),
                _sortChip('alpha',     'ابجدي',          Icons.sort_by_alpha_rounded),
                _sortChip('opens',     'الاكثر فتحا',   Icons.visibility_rounded),
                _sortChip('downloads', 'الاكثر تحميلا', Icons.download_rounded),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sortChip(String value, String label, IconData icon) {
    final active = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: () => setState(() => _sortBy = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? _kPrimary.withValues(alpha: 0.18) : _kSurface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? _kPrimary.withValues(alpha: 0.5) : _kBorder,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 11, color: active ? _kPrimary : _kTextDim),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.tajawal(fontSize: 10,
                color: active ? _kPrimary : _kTextDim,
                fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('books').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kPrimary));
        }
        if (snap.hasError) {
          return Center(child: Text('خطأ: ${snap.error}',
              style: GoogleFonts.tajawal(color: _kRed)));
        }
        final all = snap.data?.docs ?? [];
        final filtered = _sort(_filter(all));
        if (all.isEmpty) return _empty('لم يتم اضافة اي كتاب بعد');
        if (filtered.isEmpty) return _empty('لا توجد نتائج مطابقة');
        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _stats(all, filtered)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _BookCard(
                  doc: filtered[i], onDelete: _deleteBook,
                  onToggleStatus: _toggleStatus, onEditLink: _editLink,
                ),
                childCount: filtered.length,
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _stats(List<QueryDocumentSnapshot> all, List<QueryDocumentSnapshot> filtered) {
    int opens = 0, dl = 0, active = 0;
    for (final d in all) {
      final m = d.data() as Map<String, dynamic>;
      opens  += (m['openCount']     ?? m['opens']     ?? 0) as int;
      dl     += (m['downloadCount'] ?? m['downloads'] ?? 0) as int;
      if ((m['is_active'] ?? m['isActive'] ?? true) as bool) active++;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('يعرض ${filtered.length} من ${all.length} كتاب',
              style: GoogleFonts.tajawal(color: _kTextDim, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text('$active نشط', style: GoogleFonts.tajawal(
                color: _kPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _QuickStat(icon: Icons.menu_book_rounded,  label: 'اجمالي الكتب',   value: '${all.length}', color: _kAccent),
          const SizedBox(width: 10),
          _QuickStat(icon: Icons.visibility_rounded,  label: 'اجمالي الفتح',   value: _fmt(opens), color: _kPrimary),
          const SizedBox(width: 10),
          _QuickStat(icon: Icons.download_rounded,    label: 'اجمالي التحميل', value: _fmt(dl),    color: _kOrange),
        ]),
        const SizedBox(height: 6),
      ]),
    );
  }

  Widget _empty(String msg) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _kSurface2, shape: BoxShape.circle,
              border: Border.all(color: _kBorder)),
          child: const Icon(Icons.library_books_rounded, size: 48, color: _kTextDim)),
      const SizedBox(height: 16),
      Text(msg, style: GoogleFonts.tajawal(color: _kTextDim, fontSize: 15)),
    ],
  ));

  Future<void> _editLink(String docId, String title, String currentUrl) async {
    final ctrl = TextEditingController(text: currentUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _kBorder)),
        title: Row(children: [
          const Icon(Icons.link_rounded, color: _kAccent, size: 20),
          const SizedBox(width: 10),
          Text('تعديل الرابط', style: GoogleFonts.tajawal(
              color: _kText, fontWeight: FontWeight.bold)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _kSurface2,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(title, style: GoogleFonts.tajawal(color: _kTextDim, fontSize: 12),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl, maxLines: 3,
            style: GoogleFonts.tajawal(color: _kText, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'رابط Google Drive',
              labelStyle: const TextStyle(color: _kTextDim),
              filled: true, fillColor: _kSurface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kAccent, width: 1.5)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('الغاء', style: GoogleFonts.tajawal(color: _kTextDim))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            icon: const Icon(Icons.save_rounded, size: 16),
            label: Text('حفظ', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != currentUrl) {
      final fileId = DriveUrlService.extractFileId(result);
      await FirebaseFirestore.instance.collection('books').doc(docId).update({
        'url': result, 'originalDriveUrl': currentUrl, 'extractedFileId': fileId,
        'linkStatus': DriveUrlService.statusValid,
        'linkUpdatedAt': FieldValue.serverTimestamp(),
      });
      await AdminActivityService.log(
        type: AdminActivityType.bookUpdated, title: 'تعديل رابط كتاب',
        description: 'تم تحديث رابط: "$title"',
        metadata: {'bookId': docId, 'oldUrl': currentUrl, 'newUrl': result},
      );
      if (mounted) _snack('تم تحديث الرابط بنجاح', _kPrimary);
    }
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return '$n';
  }
}

class _BookCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Future<void> Function(String, String) onDelete;
  final Future<void> Function(String, Map<String, dynamic>, String) onToggleStatus;
  final Future<void> Function(String, String, String) onEditLink;
  const _BookCard({required this.doc, required this.onDelete,
      required this.onToggleStatus, required this.onEditLink});
  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d        = widget.doc.data() as Map<String, dynamic>;
    final title    = (d['title']    ?? 'بدون عنوان').toString();
    final author   = (d['author']   ?? '').toString();
    final section  = (d['section']  ?? d['stage']    ?? '').toString();
    final grade    = (d['grade']    ?? d['year']     ?? '').toString();
    final category = (d['category'] ?? d['type']     ?? d['bookType'] ?? '').toString();
    final subject  = (d['subject']  ?? d['material'] ?? '').toString();
    final isActive = (d['is_active']?? d['isActive'] ?? true) as bool;
    final coverUrl = (d['coverUrl'] ?? d['imageUrl'] ?? d['thumbnailUrl'])?.toString();
    final url      = (d['url'] ?? '').toString();
    final opens    = (d['openCount']     ?? d['opens']     ?? 0) as int;
    final dls      = (d['downloadCount'] ?? d['downloads'] ?? 0) as int;
    final favs     = (d['favoriteCount'] ?? d['favorites'] ?? 0) as int;
    final fileId   = DriveUrlService.extractFileId(url);
    final cover    = (coverUrl?.isNotEmpty == true) ? coverUrl
        : (fileId != null ? DriveUrlService.getThumbnailUrl(fileId) : null);
    final linkOk   = DriveUrlService.getUrlStatus(url) == DriveUrlService.statusValid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kSurface, borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? _kBorder : _kOrange.withValues(alpha: 0.35),
          width: isActive ? 1 : 1.5,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildCover(cover, isActive),
                const SizedBox(width: 14),
                Expanded(child: _buildInfo(title, author, section, grade,
                    category, subject, isActive, opens, dls, favs)),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220), turns: _expanded ? 0.5 : 0,
                  child: const Icon(Icons.expand_more_rounded, color: _kTextDim, size: 22),
                ),
              ]),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: _buildActions(d, title, url, isActive, linkOk, fileId),
          secondChild: const SizedBox.shrink(),
        ),
      ]),
    );
  }

  Widget _buildCover(String? url, bool isActive) {
    return Stack(children: [
      Container(
        width: 72, height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A2A), Color(0xFF1A2A3A)]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: url != null
              ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                  placeholder: (context, url) => _ph(), errorWidget: (context, url, error) => _ph())
              : _ph(),
        ),
      ),
      Positioned(top: 5, right: 5,
          child: AnimatedBuilder(animation: _pulse, builder: (context, child) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: isActive
                  ? Color.lerp(_kPrimary, _kPrimary.withValues(alpha: 0.3), _pulse.value)
                  : _kOrange,
              border: Border.all(color: _kSurface, width: 1.5)),
          ))),
    ]);
  }

  Widget _ph() => Container(color: _kSurface2, child: const Center(
      child: Icon(Icons.auto_stories_rounded, color: _kTextDim, size: 28)));

  Widget _buildInfo(String title, String author, String section, String grade,
      String category, String subject, bool isActive, int opens, int dls, int favs) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!isActive) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _kOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _kOrange.withValues(alpha: 0.3))),
          child: Text('موقوف مؤقتا', style: GoogleFonts.tajawal(
              color: _kOrange, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 5),
      ],
      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: GoogleFonts.tajawal(color: _kText, fontSize: 14,
              fontWeight: FontWeight.bold, height: 1.3)),
      if (author.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(author, style: GoogleFonts.tajawal(color: _kTextDim, fontSize: 11),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      const SizedBox(height: 8),
      Wrap(spacing: 5, runSpacing: 5, children: [
        if (section.isNotEmpty)  _chip(section,   _kAccent,  Icons.school_rounded),
        if (grade.isNotEmpty)    _chip(grade,     _kPurple,  Icons.layers_rounded),
        if (category.isNotEmpty) _chip(category,  _kPrimary, Icons.category_rounded),
        if (subject.isNotEmpty)  _chip(subject,   _kOrange,  Icons.subject_rounded),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _stat(Icons.visibility_rounded, opens, _kAccent),
        const SizedBox(width: 10),
        _stat(Icons.download_rounded,   dls,   _kPrimary),
        const SizedBox(width: 10),
        _stat(Icons.favorite_rounded,   favs,  _kRed),
      ]),
    ]);
  }

  Widget _chip(String label, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: color), const SizedBox(width: 3),
      Text(label, style: GoogleFonts.tajawal(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _stat(IconData icon, int v, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color.withValues(alpha: 0.8)), const SizedBox(width: 3),
    Text(_fmt(v), style: GoogleFonts.outfit(fontSize: 11, color: _kTextDim, fontWeight: FontWeight.w600)),
  ]);

  Widget _buildActions(Map<String, dynamic> d, String title, String url,
      bool isActive, bool linkOk, String? fileId) {
    final docId = widget.doc.id;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 6, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (linkOk ? _kPrimary : _kOrange).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (linkOk ? _kPrimary : _kOrange).withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(linkOk ? Icons.link_rounded : Icons.warning_amber_rounded,
                  size: 12, color: linkOk ? _kPrimary : _kOrange),
              const SizedBox(width: 5),
              Text(linkOk ? 'رابط Drive صالح' : 'يحتاج مراجعة',
                  style: GoogleFonts.tajawal(fontSize: 10,
                      color: linkOk ? _kPrimary : _kOrange, fontWeight: FontWeight.bold)),
            ]),
          ),
          if (fileId != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: _kAccent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.fingerprint_rounded, size: 11, color: _kAccent),
              const SizedBox(width: 4),
              Text(fileId.length > 14 ? '${fileId.substring(0, 14)}...' : fileId,
                  style: GoogleFonts.outfit(fontSize: 9, color: _kAccent)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _ActionBtn(
            icon: isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
            label: isActive ? 'ايقاف' : 'تفعيل',
            color: isActive ? _kOrange : _kPrimary,
            onTap: () => widget.onToggleStatus(docId, d, title),
          ),
          const SizedBox(width: 8),
          _ActionBtn(icon: Icons.edit_rounded, label: 'تعديل الرابط', color: _kAccent,
              onTap: () => widget.onEditLink(docId, title, url)),
          const Spacer(),
          _ActionBtn(icon: Icons.delete_outline_rounded, label: 'حذف', color: _kRed,
              onTap: () => widget.onDelete(docId, title)),
        ]),
      ]),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك';
    return '$n';
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color), const SizedBox(width: 5),
        Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

class _QuickStat extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _QuickStat({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 13, color: color), const SizedBox(width: 4),
          Expanded(child: Text(label, style: GoogleFonts.tajawal(color: _kTextDim, fontSize: 9),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title, message, confirmLabel; final Color confirmColor; final IconData icon;
  const _ConfirmDialog({required this.title, required this.message, required this.confirmLabel,
      required this.confirmColor, required this.icon});
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: _kSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: confirmColor.withValues(alpha: 0.3))),
    title: Row(children: [
      Icon(icon, color: confirmColor, size: 22), const SizedBox(width: 10),
      Text(title, style: GoogleFonts.tajawal(color: _kText, fontWeight: FontWeight.bold)),
    ]),
    content: Text(message, style: GoogleFonts.tajawal(color: _kTextDim, height: 1.5)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false),
          child: Text('الغاء', style: GoogleFonts.tajawal(color: _kTextDim))),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: confirmColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel, style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    ],
  );
}
