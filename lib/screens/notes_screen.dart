import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';
import 'note_editor_screen.dart';
import 'notes_settings_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

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

  void _openEditor({Note? note, String? template}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
  }

  void _showNewNoteTemplates() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'إنشاء ملاحظة جديدة',
                      style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildTemplateCard('ملاحظة فارغة', Icons.note_add_rounded, Colors.blue, 'blank'),
                    _buildTemplateCard('ملاحظة سريعة', Icons.flash_on_rounded, Colors.orange, 'quick'),
                    _buildTemplateCard('ملخص درس', Icons.menu_book_rounded, Colors.green, 'summary'),
                    _buildTemplateCard('مراجعة امتحان', Icons.assignment_rounded, Colors.redAccent, 'exam'),
                    _buildTemplateCard('خطة مذاكرة', Icons.calendar_month_rounded, Colors.purple, 'plan'),
                    _buildTemplateCard('قالب رياضيات', Icons.calculate_rounded, Colors.teal, 'math'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateCard(String title, IconData icon, Color color, String template) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _openEditor(template: template);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteContextMenu(Note note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final provider = Provider.of<NotesProvider>(context, listen: false);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: Text('تعديل', style: GoogleFonts.tajawal()),
                  onTap: () {
                    Navigator.pop(context);
                    _openEditor(note: note);
                  },
                ),
                ListTile(
                  leading: Icon(note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                  title: Text(note.isPinned ? 'إزالة التثبيت' : 'تثبيت', style: GoogleFonts.tajawal()),
                  onTap: () {
                    provider.togglePin(note.id);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(note.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber),
                  title: Text(note.isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة', style: GoogleFonts.tajawal()),
                  onTap: () {
                    provider.toggleFavorite(note.id);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: Text('حذف', style: GoogleFonts.tajawal(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    provider.moveToTrash(note.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<NotesProvider>(context);
    final bg = isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFF);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الملاحظات',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () {
                      // show search bar logic
                    },
                  ),
                  IconButton(
                    icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesSettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => provider.setSearchQuery(val),
                style: GoogleFonts.tajawal(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'ابحث في ملاحظاتك...',
                  hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? AppTheme.surfaceDark : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // ── Tabs ──
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTab('الكل', 'all', provider, isDark),
                  _buildTab('المفضلة', 'favorites', provider, isDark),
                  _buildTab('المثبتة', 'pinned', provider, isDark),
                  _buildTab('المجلدات', 'folders', provider, isDark),
                  _buildTab('الأرشيف', 'archive', provider, isDark),
                  _buildTab('سلة المهملات', 'trash', provider, isDark),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Content ──
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(provider, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: provider.currentTab == 'trash' ? null : FloatingActionButton.extended(
        onPressed: _showNewNoteTemplates,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'ملاحظة جديدة',
          style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildContent(NotesProvider provider, bool isDark) {
    if (provider.currentTab == 'trash') {
      final trashed = provider.trashedNotes;
      if (trashed.isEmpty) return _buildEmptyState(isDark, 'سلة المهملات فارغة', Icons.delete_outline);
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trashed.length,
        itemBuilder: (context, index) {
          final note = trashed[index];
          return ListTile(
            title: Text(note.title.isNotEmpty ? note.title : 'بدون عنوان', style: GoogleFonts.tajawal(color: isDark ? Colors.white : Colors.black)),
            subtitle: Text('محذوفة منذ ${intl.DateFormat('d MMM', 'ar').format(note.deletedAt ?? DateTime.now())}', style: GoogleFonts.tajawal(color: Colors.redAccent)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore_rounded, color: Colors.green),
                  onPressed: () => provider.restoreFromTrash(note.id),
                  tooltip: 'استعادة',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  onPressed: () => provider.deleteNote(note.id),
                  tooltip: 'حذف نهائي',
                ),
              ],
            ),
          );
        },
      );
    }

    if (provider.currentTab == 'folders') {
      return _buildEmptyState(isDark, 'سيتم تفعيل المجلدات قريباً', Icons.folder_open_rounded);
    }

    final displayNotes = provider.notes;
    if (displayNotes.isEmpty) {
      return _buildEmptyState(isDark, 'لا توجد ملاحظات', Icons.note_add_rounded);
    }

    if (_isGridView) {
      return MasonryGridView.count(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: displayNotes.length,
        itemBuilder: (context, index) => _buildNoteCard(displayNotes[index], isDark, provider),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: displayNotes.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNoteCard(displayNotes[index], isDark, provider, isListView: true),
        ),
      );
    }
  }

  Widget _buildTab(String title, String tabId, NotesProvider provider, bool isDark) {
    final isSelected = provider.currentTab == tabId;
    return GestureDetector(
      onTap: () => provider.setTab(tabId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (isDark ? AppTheme.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.tajawal(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note, bool isDark, NotesProvider provider, {bool isListView = false}) {
    final hasColor = note.color != null;
    final cardColor = hasColor ? Color(note.color!) : (isDark ? AppTheme.surfaceDark : Colors.white);
    final textColor = hasColor ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final subTextColor = hasColor ? Colors.white70 : (isDark ? Colors.white54 : Colors.black54);

    return GestureDetector(
      onTap: () => _openEditor(note: note),
      onLongPress: () => _showNoteContextMenu(note),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: hasColor ? null : Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: hasColor ? Color(note.color!).withValues(alpha: 0.3) : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                if (note.isPinned || note.isFavorite) ...[
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      if (note.isPinned) Icon(Icons.push_pin_rounded, size: 16, color: Colors.amberAccent),
                      if (note.isPinned && note.isFavorite) const SizedBox(height: 4),
                      if (note.isFavorite) Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    ],
                  ),
                ],
                // Context Menu
                GestureDetector(
                  onTap: () => _showNoteContextMenu(note),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.more_vert_rounded, size: 18, color: subTextColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getPreviewText(note.content),
              style: GoogleFonts.tajawal(fontSize: 13, color: subTextColor, height: 1.5),
              maxLines: isListView ? 3 : 5,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: note.tags.map((tagId) {
                  // Use tag ID as tag name for now
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$tagId',
                      style: GoogleFonts.tajawal(fontSize: 10, color: subTextColor),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 12, color: subTextColor),
                const SizedBox(width: 4),
                Text(
                  intl.DateFormat('d MMM', 'ar').format(note.updatedAt),
                  style: GoogleFonts.tajawal(fontSize: 11, color: subTextColor),
                ),
                const Spacer(),
                if (note.attachments.isNotEmpty) ...[
                  Icon(Icons.attach_file_rounded, size: 12, color: subTextColor),
                  const SizedBox(width: 2),
                  Text('${note.attachments.length}', style: GoogleFonts.tajawal(fontSize: 11, color: subTextColor)),
                  const SizedBox(width: 8),
                ],
                if (note.wordCount > 0) ...[
                  Icon(Icons.text_snippet_rounded, size: 12, color: subTextColor),
                  const SizedBox(width: 2),
                  Text('${note.wordCount} كلمة', style: GoogleFonts.tajawal(fontSize: 11, color: subTextColor)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    if (content.isEmpty) return 'لا يوجد محتوى';
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final doc = quill.Document.fromJson(decoded);
        return doc.toPlainText().trim();
      }
    } catch (_) {}
    return content;
  }
}
