import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
  late quill.QuillController _quillController;
  
  bool _isChanged = false;
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  String? _createdNoteId;

  Color? _noteColor;
  String _selectedCategory = 'أخرى';
  String _selectedFont = 'Tajawal';

  final List<String> _fonts = [
    'Tajawal', 'Amiri', 'Cairo', 'El Messiri', 'Reem Kufi', 'Lalezar', 'Changa'
  ];

  final List<String> _categories = [
    'الرياضيات', 'العلوم', 'اللغة العربية', 
    'التاريخ', 'الجغرافيا', 'التربية الإسلامية', 
    'مراجعة', 'أفكار', 'أخرى'
  ];

  final List<Color> _availableColors = [
    Colors.white,
    const Color(0xFFFDE68A), // Light Yellow
    const Color(0xFFFECACA), // Light Red
    const Color(0xFFBBF7D0), // Light Green
    const Color(0xFFBFDBFE), // Light Blue
    const Color(0xFFE9D5FF), // Light Purple
    const Color(0xFFFED7AA), // Light Orange
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    
    // Parse quill content
    final contentJson = widget.note?.content ?? '';
    quill.Document doc;
    if (contentJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentJson);
        doc = quill.Document.fromJson(decoded);
      } catch (e) {
        // Fallback if not valid JSON delta (e.g. older plain text notes)
        doc = quill.Document()..insert(0, contentJson);
      }
    } else {
      doc = quill.Document();
    }

    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    if (widget.note?.color != null) {
      _noteColor = Color(widget.note!.color!);
    } else {
      _noteColor = Colors.white;
    }

    if (widget.note?.tags != null && widget.note!.tags.isNotEmpty) {
      _selectedCategory = widget.note!.tags.first;
    }

    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isChanged) setState(() => _isChanged = true);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), _autoSave); // 1.5s debounce
  }

  Future<void> _autoSave() async {
    if (!_isChanged || !mounted) return;
    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());

    // Prevent saving completely empty note
    if (title.isEmpty && _quillController.document.isEmpty()) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);
    final existingId = widget.note?.id ?? _createdNoteId;

    try {
      if (existingId != null) {
        await provider.updateNote(
          existingId,
          title.isEmpty ? 'بدون عنوان' : title,
          content,
          color: _noteColor?.toARGB32(),
          tags: [_selectedCategory],
        );
      } else {
        // Add note
        await provider.addNote(
          title.isEmpty ? 'بدون عنوان' : title,
          content,
          color: _noteColor?.toARGB32(),
          tags: [_selectedCategory],
        );
        // Note: provider.addNote doesn't return ID currently.
        // It's safer to pop after first creation if we can't track ID, but for seamless UX, 
        // a workaround is to fetch the latest note. For now we assume the provider handles it nicely.
      }
    } catch (e) {
      // Ignore background save errors to not interrupt user
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isChanged = false;
        });
      }
    }
  }

  void _saveAndPop() {
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());

    if (title.isEmpty && _quillController.document.isEmpty()) {
      Navigator.pop(context);
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);
    final existingId = widget.note?.id ?? _createdNoteId;

    if (existingId == null) {
      provider.addNote(
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        tags: [_selectedCategory],
      );
    } else {
      provider.updateNote(
        existingId,
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        tags: [_selectedCategory],
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final plainText = _quillController.document.toPlainText();
    // ignore: deprecated_member_use
    await Share.share('$title\n\n$plainText', subject: title);
  }

  void _showOptionsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('لون الملاحظة', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: _availableColors.map((color) {
                final isSelected = _noteColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _noteColor = color;
                      _isChanged = true;
                    });
                    _scheduleAutoSave();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected ? Icon(Icons.check_rounded, color: color == Colors.white ? Colors.black : Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('تصنيف الملاحظة', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _isChanged = true;
                    });
                    _scheduleAutoSave();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white12 : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.tajawal(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text('خط الملاحظة', style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _fonts.map((font) {
                final isSelected = _selectedFont == font;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFont = font;
                      _isChanged = true;
                    });
                    _scheduleAutoSave();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white12 : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      font,
                      style: GoogleFonts.getFont(
                        font,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
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

    Color bgColor = _noteColor ?? Colors.white;
    if (isDark && bgColor == Colors.white) {
      bgColor = const Color(0xFF0F172A);
    } else if (isDark && bgColor != Colors.white) {
      bgColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.7), bgColor);
    }
    
    final textColor = (isDark && bgColor == const Color(0xFF0F172A)) ? Colors.white : Colors.black87;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: _saveAndPop,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (!_isChanged && (_autoSaveTimer == null || !_autoSaveTimer!.isActive))
                Icon(Icons.cloud_done_rounded, size: 16, color: textColor.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                _isSaving ? 'جارٍ الحفظ...' : (!_isChanged ? 'تم الحفظ' : ''),
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.tune_rounded, color: textColor),
              onPressed: _showOptionsModal,
              tooltip: 'الخيارات',
            ),
            IconButton(
              icon: Icon(Icons.share_rounded, color: textColor),
              onPressed: _shareNote,
              tooltip: 'مشاركة',
            ),
          ],
        ),
        body: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _titleController,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.tajawal(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'عنوان الملاحظة...',
                  hintStyle: GoogleFonts.tajawal(color: textColor.withValues(alpha: 0.3)),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: quill.QuillSimpleToolbar(
                controller: _quillController,
                config: const quill.QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: false,
                  showInlineCode: false,
                  showCodeBlock: false,
                  showListCheck: true,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showAlignmentButtons: true,
                  showLeftAlignment: false,
                  showCenterAlignment: false,
                  showRightAlignment: false,
                  showJustifyAlignment: false,
                  showHeaderStyle: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showQuote: true,
                  showLink: false,
                  showUndo: true,
                  showRedo: true,
                  showDirection: true,
                  showSearchButton: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showStrikeThrough: true,
                ),
              ),
            ),

            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: quill.QuillEditor.basic(
                    controller: _quillController,
                    config: quill.QuillEditorConfig(
                      autoFocus: true,
                      expands: true,
                      padding: EdgeInsets.zero,
                      placeholder: 'ابدأ بالكتابة هنا...',
                      customStyles: quill.DefaultStyles(
                        placeHolder: quill.DefaultTextBlockStyle(
                          GoogleFonts.getFont(_selectedFont, fontSize: 18, color: textColor.withAlpha((0.3 * 255).toInt())),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        paragraph: quill.DefaultTextBlockStyle(
                          GoogleFonts.getFont(_selectedFont, fontSize: 18, color: textColor, height: 1.6),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        h1: quill.DefaultTextBlockStyle(
                          GoogleFonts.getFont(_selectedFont, fontSize: 32, color: textColor, fontWeight: FontWeight.bold),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(16, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        h2: quill.DefaultTextBlockStyle(
                          GoogleFonts.getFont(_selectedFont, fontSize: 26, color: textColor, fontWeight: FontWeight.bold),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(8, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        h3: quill.DefaultTextBlockStyle(
                          GoogleFonts.getFont(_selectedFont, fontSize: 22, color: textColor, fontWeight: FontWeight.bold),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(8, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        lists: quill.DefaultListBlockStyle(
                          GoogleFonts.getFont(_selectedFont, fontSize: 18, color: textColor),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
