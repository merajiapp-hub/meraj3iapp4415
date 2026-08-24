import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';
import 'note_editor_screen.dart';
import 'trash_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تأكيد الحذف',
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'سيتم نقل هذه الملاحظة إلى سلة المحذوفات.',
            style: GoogleFonts.tajawal(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.tajawal(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<NotesProvider>(context, listen: false).moveToTrash(noteId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<NotesProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'ملاحظاتي',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'سلة المحذوفات',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                provider.setSearchQuery(val);
              },
              style: GoogleFonts.tajawal(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'البحث في الملاحظات...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
          Expanded(
            child: provider.isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : provider.notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 80,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'الملاحظات التي تضيفها تظهر هنا',
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: provider.notes.length,
                        itemBuilder: (context, index) {
                          final note = provider.notes[index];
                          return GestureDetector(
                            onTap: () => _openEditor(note: note),
                            onLongPress: () => _confirmDelete(context, note.id),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: note.color != null 
                                    ? Color(note.color!) 
                                    : (isDark ? AppTheme.surfaceDark : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // To fit masonry size
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          note.title.isNotEmpty ? note.title : 'بدون عنوان',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark || note.color != null ? Colors.white : AppTheme.primaryColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => provider.togglePin(note.id),
                                        child: Icon(
                                          note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                          color: note.isPinned ? (isDark || note.color != null ? Colors.white : AppTheme.primaryColor) : Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getPreviewText(note.content),
                                    style: GoogleFonts.tajawal(
                                      fontSize: 14,
                                      color: isDark || note.color != null ? Colors.white70 : Colors.black87,
                                      height: 1.5,
                                    ),
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    intl.DateFormat('MMM d').format(note.updatedAt),
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11,
                                      color: isDark || note.color != null ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getPreviewText(String content) {
    if (content.isEmpty) return 'بدون محتوى';
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
