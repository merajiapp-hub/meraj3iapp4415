import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  String _activeCategory = 'الكل';
  bool _showFavoritesOnly = false;

  // Theme colors for notes page
  final List<Color> _pageThemes = [
    const Color(0xFF0F172A), // Dark Slate
    const Color(0xFF1E3A8A), // Deep Blue
    const Color(0xFF14532D), // Deep Green
    const Color(0xFF701A75), // Deep Purple
    const Color(0xFF7F1D1D), // Deep Red
    const Color(0xFF064E3B), // Emerald
  ];
  int _selectedThemeIndex = 0;

  final List<String> _categories = [
    'الكل',
    'الرياضيات',
    'العلوم',
    'اللغة العربية',
    'التاريخ',
    'الجغرافيا',
    'التربية الإسلامية',
    'مراجعة',
    'أفكار',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesProvider>(context, listen: false).fetchNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor({Note? note}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isGuest || auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تسجيل الدخول لإنشاء وتعديل الملاحظات.',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'اختر ثيم صفحة الملاحظات',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(_pageThemes.length, (index) {
                final color = _pageThemes[index];
                final isSelected = _selectedThemeIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThemeIndex = index);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<NotesProvider>(context);

    // Background based on selected theme for dark mode, or light theme gradient for light mode
    final themeColor = _pageThemes[_selectedThemeIndex];
    final bgGradient = isDark
        ? LinearGradient(
            colors: [themeColor, themeColor.withValues(alpha: 0.6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [const Color(0xFFF8FAFF), const Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark, themeColor),
              _buildFilters(isDark),

              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(provider, isDark),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(
          'ملاحظة جديدة',
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color themeColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              const SizedBox(width: 8),
              Text(
                'ملاحظاتي',
                style: GoogleFonts.tajawal(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.color_lens_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                tooltip: 'تغيير الثيم',
                onPressed: _showThemeSelector,
              ),
              IconButton(
                icon: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'اكتب ما تتعلمه، واحفظ ما يهمك، وراجع ما كتبته.',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.transparent,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث في العنوان أو المحتوى...',
                hintStyle: GoogleFonts.tajawal(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? Colors.white70 : AppTheme.primaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.tajawal(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Favorites Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showFavoritesOnly = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: !_showFavoritesOnly
                        ? AppTheme.primaryColor
                        : (isDark ? Colors.white12 : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'الكل',
                    style: GoogleFonts.tajawal(
                      color: !_showFavoritesOnly
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showFavoritesOnly = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _showFavoritesOnly
                        ? AppTheme.secondaryColor
                        : (isDark ? Colors.white12 : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: _showFavoritesOnly
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'المفضلة',
                        style: GoogleFonts.tajawal(
                          color: _showFavoritesOnly
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Categories
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _activeCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _activeCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDark ? Colors.white30 : Colors.black26),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.tajawal(
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContent(NotesProvider provider, bool isDark) {
    // Basic pre-filtered notes from provider
    var notes = provider.notes;

    // Apply local filters (Favorites, Categories, Search)
    if (_showFavoritesOnly) {
      notes = notes.where((n) => n.isFavorite).toList();
    }

    if (_activeCategory != 'الكل') {
      notes = notes.where((n) => n.tags.contains(_activeCategory)).toList();
    }

    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      notes = notes.where((n) {
        final contentText = _extractTextFromDelta(n.content).toLowerCase();
        return n.title.toLowerCase().contains(query) ||
            contentText.contains(query);
      }).toList();
    }

    if (provider.notes.isEmpty &&
        query.isEmpty &&
        !_showFavoritesOnly &&
        _activeCategory == 'الكل') {
      return _buildLiteraryIntro(isDark);
    }

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد ملاحظات مطابقة',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return MasonryGridView.count(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: notes.length,
        itemBuilder: (context, index) =>
            _buildNoteCard(notes[index], isDark, provider),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: notes.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNoteCard(notes[index], isDark, provider),
        ),
      );
    }
  }

  Widget _buildLiteraryIntro(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              size: 60,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'اكتب ما لا تريد أن تنساه',
              style: GoogleFonts.tajawal(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'تتيح لنا الكتابة أن نحتفظ بشيء من اللحظات التي تمر بنا، وأن نحول الأفكار العابرة إلى كلمات يمكننا العودة إليها متى شئنا. فمن خلالها نستطيع أن نتواصل مع ما تعلمناه في الماضي، وأن نرتب أفكارنا في الحاضر، وأن نترك لأنفسنا طريقًا واضحًا نحو المستقبل.\n\n'
              'كم فكرة جميلة خطرت لك ثم اختفت لأنك قلت: «سأتذكرها لاحقًا»؟\n'
              'وكم معلومة مهمة قرأتها أو سمعتها أثناء الدراسة، ثم احتجت إليها بعد أيام فلم تتذكر أين وجدتها؟\n'
              'وكم مرة جاءك الإلهام في لحظة لم تكن مستعدًا فيها للكتابة، فمضت اللحظة وبقيت الفكرة في ذاكرتك ناقصة أو لم تعد إليها أبدًا؟\n\n'
              'لهذا جاءت ملاحظاتي؛ لتكون المساحة التي تضع فيها ما تريد أن يبقى.\n\n'
              'اكتب هنا ما تتعلمه، وسجل ما تراه مهمًا، واحفظ الأفكار التي لا تريد أن تضيع بين تفاصيل يومك. قد تكون ملاحظتك درسًا مختصرًا، أو معلومة جديدة، أو فكرة لمشروع، أو سؤالًا تريد البحث عن إجابته، أو نقطة تريد العودة إليها أثناء المراجعة. لا يشترط أن تكون الفكرة كبيرة حتى تستحق أن تُكتب؛ فأحيانًا تبدأ الأشياء المهمة من سطر صغير.\n\n'
              'وفي الدراسة تحديدًا، لا تكون الكتابة مجرد وسيلة لحفظ المعلومات، بل وسيلة لفهمها أيضًا. فعندما تكتب ما تعلمته بأسلوبك، فإنك تمنح المعلومة فرصة أخرى لتثبت في ذهنك، وعندما تعود إليها لاحقًا، تصبح المراجعة أكثر وضوحًا وأسهل تنظيمًا.\n\n'
              'ومن هنا، تصبح كل ملاحظة تكتبها جزءًا من رحلتك مع المعرفة.\n\n'
              'قد تكتب اليوم ملاحظة قصيرة لا تحتاج إليها الآن، ثم تعود إليها بعد أسبوع فتجد فيها ما كنت تبحث عنه. وقد تسجل فكرة أثناء قراءة أحد الكتب، ثم تكتشف بعد مدة أنها ساعدتك على فهم موضوع آخر. وهكذا لا تبقى الملاحظات مجرد كلمات محفوظة، بل تتحول مع الوقت إلى ذاكرة خاصة بك، تجمع فيها ما تعلمته وما فكرت فيه وما أردت الاحتفاظ به.\n\n'
              'وفي مراجعي، نؤمن بأن المعرفة لا تكمن فقط في كمية ما تقرأ، وإنما في قدرتك على الاحتفاظ بما يفيدك والعودة إليه عندما تحتاج إليه. لذلك جاءت هذه المساحة لتكون قريبة منك، بسيطة في استخدامها، ومفتوحة لكل فكرة تستحق أن تجد لها مكانًا.\n\n'
              'لا تنتظر أن تكون الفكرة كاملة حتى تكتبها.\n'
              'ابدأ بما لديك، ثم دع الكلمات تساعدك على ترتيبها.\n\n'
              'اكتب الجملة الأولى، ثم أضف إليها ما يأتي بعدها. راجع ما كتبت، وعدّل ما يحتاج إلى تعديل، واترك للفكرة وقتها حتى تكتمل. فالكتابة ليست دائمًا بحثًا عن الكلمات المثالية، بل هي في كثير من الأحيان محاولة لاكتشاف ما نريد قوله أصلًا.\n\n'
              'وقد لا تعرف اليوم قيمة ما تكتبه، لكنك قد تحتاج إليه غدًا.\n\n'
              'لهذا، لا تعتمد على ذاكرتك وحدها.\n'
              'اكتب ما تخشى أن تنساه، واحفظ ما ترى أنه يستحق أن يبقى.\n\n'
              'ومع مرور الوقت، ستجد أن هذه الملاحظات الصغيرة بدأت تتجمع لتصنع شيئًا أكبر؛ مجموعة من الدروس والأفكار والمعلومات التي مررت بها، واحتفظت بها، ثم عدت إليها في الوقت المناسب.\n\n'
              'إنها ليست مجرد ملاحظات، بل أثر من رحلتك في التعلم.\n\n'
              'فكلما تعلمت شيئًا، اكتب.\n'
              'وكلما جاءت فكرة، دوّنها.\n'
              'وكلما وجدت معلومة مهمة، احفظها.\n'
              'وكلما احتجت إلى التذكر، عد إلى ما كتبت.\n\n'
              'ومن هنا يبدأ دور «مراجعي»؛ أن يمنح أفكارك مكانًا، ولملاحظاتك ذاكرة، ولمراجعتك طريقًا أكثر تنظيمًا.\n\n'
              'اكتب دون تردد، ودع هذه المساحة تحتفظ بما يستحق أن يعود إليك يومًا.\n\n'
              'فربما يكون ما تكتبه الآن مجرد ملاحظة صغيرة، لكنه قد يصبح لاحقًا إجابة عن سؤال، أو مفتاحًا لفهم درس، أو بداية لفكرة جديدة.\n\n'
              'ملاحظاتي في مراجعي...\n\n'
              'مساحة تكتب فيها ما تعلمته، وتحفظ فيها ما يهمك، وتعود إليها عندما تحتاج إلى أن تتذكر.\n\n'
              'ابدأ من هنا...\n'
              'اكتب أول ملاحظة، فكل معرفة عظيمة تبدأ أحيانًا بفكرة صغيرة.',
              style: GoogleFonts.amiri(
                fontSize: 16,
                height: 2.2,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openEditor(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
              label: Text(
                'اكتب أول ملاحظة',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractTextFromDelta(String deltaStr) {
    if (deltaStr.isEmpty) return '';
    try {
      if (deltaStr.startsWith('[{"insert"')) {
        final List<dynamic> decoded = RegExp(
          r'"insert":"(.*?)"',
        ).allMatches(deltaStr).map((m) => m.group(1) ?? '').toList();
        return decoded.join(' ').replaceAll(RegExp(r'\\n'), ' ');
      }
    } catch (_) {}
    return deltaStr; // Fallback
  }

  Widget _buildNoteCard(Note note, bool isDark, NotesProvider provider) {
    final hasColor =
        note.color != null && note.color != Colors.white.toARGB32();
    final cardColor = hasColor
        ? Color(note.color!)
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    // Auto darken light colors for dark mode readability
    final effectiveCardColor = (isDark && hasColor)
        ? Color.alphaBlend(Colors.black.withValues(alpha: 0.6), cardColor)
        : cardColor;

    final textColor = (hasColor && !isDark)
        ? Colors.black87
        : (isDark ? Colors.white : Colors.black87);
    final secondaryTextColor = (hasColor && !isDark)
        ? Colors.black54
        : (isDark ? Colors.white54 : Colors.black54);

    final plainText = _extractTextFromDelta(note.content);
    final snippet = plainText.length > 100
        ? '${plainText.substring(0, 100)}...'
        : plainText;

    final dateStr = intl.DateFormat('d MMM yyyy', 'ar').format(note.updatedAt);

    return GestureDetector(
      onTap: () => _openEditor(note: note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: effectiveCardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.transparent,
          ),
          boxShadow: [
            if (!isDark && !hasColor)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : 'بدون عنوان',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    provider.updateNote(
                      note.id,
                      note.title,
                      note.content,
                      isFavorite: !note.isFavorite,
                      tags: note.tags,
                      color: note.color,
                    );
                  },
                  child: Icon(
                    note.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: note.isFavorite ? Colors.orange : secondaryTextColor,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snippet.isNotEmpty ? snippet : 'لا يوجد محتوى...',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                height: 1.5,
                color: secondaryTextColor,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (note.tags.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      note.tags.first,
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: textColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
                if (note.tags.isEmpty) const Spacer(),
                Text(
                  dateStr,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _confirmDelete(context, note, provider),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.red[300],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Note note, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'حذف الملاحظة؟',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه الملاحظة نهائياً؟',
          style: GoogleFonts.tajawal(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteNote(note.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حذف الملاحظة.',
                    style: GoogleFonts.tajawal(),
                  ),
                  backgroundColor: Colors.black87,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.tajawal(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
