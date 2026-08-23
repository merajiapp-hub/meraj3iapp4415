import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);
    if (widget.note == null) {
      provider.addNote(title.isEmpty ? 'بدون عنوان' : title, content);
    } else {
      if (_isChanged) {
        provider.updateNote(widget.note!.id, title.isEmpty ? 'بدون عنوان' : title, content);
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveNote();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87),
            onPressed: _saveNote,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.primaryColor, size: 28),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (v) => _isChanged = true,
                  style: GoogleFonts.tajawal(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'العنوان',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    onChanged: (v) => _isChanged = true,
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'ابدأ الكتابة هنا...',
                      hintStyle: GoogleFonts.tajawal(color: Colors.grey.withValues(alpha: 0.5)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
