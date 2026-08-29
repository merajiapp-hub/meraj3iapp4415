import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import 'note_editor_screen.dart';

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

  void _openEditor({Note? note}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isGuest || auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تسجيل الدخول لإنشاء وتعديل الملاحظات.', style: TextStyle(fontFamily: 'Tajawal')),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<NotesProvider>(context);
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFF);
    final textCol = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Text('الملاحظات', style: GoogleFonts.tajawal(fontSize: 24, fontWeight: FontWeight.bold, color: textCol)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'ابحث في الملاحظات...',
                  hintStyle: GoogleFonts.tajawal(color: textCol.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.tajawal(color: textCol),
              ),
            ),

            // Content
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(provider, isDark),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('ملاحظة جديدة', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildContent(NotesProvider provider, bool isDark) {
    final displayNotes = provider.notes;
    
    if (displayNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add_rounded, size: 80, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('لا توجد ملاحظات', style: GoogleFonts.tajawal(fontSize: 18, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5))),
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
        itemCount: displayNotes.length,
        itemBuilder: (context, index) => _buildNoteCard(displayNotes[index], isDark, provider),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        itemCount: displayNotes.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNoteCard(displayNotes[index], isDark, provider),
        ),
      );
    }
  }

  Widget _buildNoteCard(Note note, bool isDark, NotesProvider provider) {
    final hasColor = note.color != null;
    final cardColor = hasColor ? Color(note.color!) : (isDark ? const Color(0xFF1E293B) : Colors.white);
    final textColor = hasColor ? Colors.white : (isDark ? Colors.white : Colors.black87);
    
    return GestureDetector(
      onTap: () => _openEditor(note: note),
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('خيارات الملاحظة', style: GoogleFonts.tajawal()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('حذف الملاحظة', style: GoogleFonts.tajawal(color: Colors.red)),
                  onTap: () {
                    provider.deleteNote(note.id);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!hasColor && !isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty) ...[
              Text(
                note.title,
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            // Content preview (parsing the quill delta if possible)
            Text(
              _getPreviewText(note.content),
              style: GoogleFonts.tajawal(fontSize: 14, color: textColor.withValues(alpha: 0.8), height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              intl.DateFormat('d MMM yyyy, h:mm a', 'ar').format(note.updatedAt),
              style: GoogleFonts.tajawal(fontSize: 10, color: textColor.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    if (content.isEmpty) return '';
    try {
      // Assuming it's a Quill Delta JSON. Just extract strings roughly for preview
      if (content.startsWith('[')) {
        // Very basic extraction, real extraction needs quill.Document
        return content.replaceAll(RegExp(r'[{}"\[\]]'), '').replaceAll(RegExp(r'insert:'), '').replaceAll(RegExp(r',attributes:.*?\\n'), ' ').trim();
      }
      return content;
    } catch (_) {
      return content;
    }
  }
}
