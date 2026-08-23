import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
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
  // Track if we created a new note during an auto-save (so we have an id)
  String? _createdNoteId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    // Load content: if JSON delta, parse it; else treat as plain text.
    quill.Document doc;
    final content = widget.note?.content ?? '';
    if (content.isNotEmpty) {
      try {
        final decoded = jsonDecode(content);
        if (decoded is List) {
          doc = quill.Document.fromJson(decoded);
        } else {
          doc = quill.Document()..insert(0, content);
        }
      } catch (_) {
        doc = quill.Document()..insert(0, content);
      }
    } else {
      doc = quill.Document();
    }

    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _quillController.addListener(() {
      if (!_isChanged) setState(() => _isChanged = true);
      _scheduleAutoSave();
    });

    _titleController.addListener(() {
      if (!_isChanged) setState(() => _isChanged = true);
      _scheduleAutoSave();
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), _autoSave);
  }

  Future<void> _autoSave() async {
    if (!_isChanged || !mounted) return;
    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);
    final existingId = widget.note?.id ?? _createdNoteId;

    if (existingId != null) {
      await provider.updateNote(existingId, title.isEmpty ? 'بدون عنوان' : title, content);
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isChanged = false;
      });
    }
  }

  void _saveNote() {
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final provider = Provider.of<NotesProvider>(context, listen: false);
    final existingId = widget.note?.id ?? _createdNoteId;

    if (existingId == null) {
      provider.addNote(title.isEmpty ? 'بدون عنوان' : title, content);
    } else {
      provider.updateNote(existingId, title.isEmpty ? 'بدون عنوان' : title, content);
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null && mounted) {
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        index,
        length < 0 ? 0 : length,
        quill.BlockEmbed.image(pickedFile.path),
        null,
      );
      setState(() => _isChanged = true);
    }
  }

  Future<void> _openDrawingSheet() async {
    final result = await showModalBottomSheet<List<int>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DrawingSheet(),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/draw_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(result);

      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        index,
        length < 0 ? 0 : length,
        quill.BlockEmbed.image(file.path),
        null,
      );
      setState(() => _isChanged = true);
    }
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
          title: _isSaving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text('حفظ تلقائي...', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey)),
                  ],
                )
              : (_isChanged
                  ? Text('غير محفوظ', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.orange))
                  : null),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.primaryColor, size: 28),
              onPressed: _saveNote,
              tooltip: 'حفظ',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ── Title ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: TextField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.tajawal(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'العنوان',
                    hintStyle: GoogleFonts.tajawal(color: Colors.grey.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),

              // ── Quill Editor ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: quill.QuillEditor(
                    controller: _quillController,
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                    config: quill.QuillEditorConfig(
                      placeholder: 'ابدأ الكتابة هنا...',
                      customStyles: quill.DefaultStyles(
                        paragraph: quill.DefaultTextBlockStyle(
                          GoogleFonts.tajawal(
                            fontSize: 17,
                            height: 1.7,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Toolbar ──
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController,
                      config: quill.QuillSimpleToolbarConfig(
                        showFontFamily: false,
                        showFontSize: true,
                        showSubscript: false,
                        showSuperscript: false,
                        showInlineCode: false,
                        showColorButton: true,
                        showBackgroundColorButton: true,
                        showClearFormat: true,
                        showAlignmentButtons: true,
                        showLeftAlignment: true,
                        showCenterAlignment: true,
                        showRightAlignment: true,
                        showJustifyAlignment: true,
                        showHeaderStyle: true,
                        showListNumbers: true,
                        showListBullets: true,
                        showListCheck: true,
                        showCodeBlock: false,
                        showQuote: true,
                        showIndent: true,
                        showLink: true,
                        showUndo: true,
                        showRedo: true,
                        showDirection: true,
                      ),
                    ),
                    // Extra tools row: image, camera, drawing
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                      child: Row(
                        children: [
                          _ExtraBtn(
                            icon: Icons.image_rounded,
                            label: 'معرض',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                          _ExtraBtn(
                            icon: Icons.camera_alt_rounded,
                            label: 'كاميرا',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                          _ExtraBtn(
                            icon: Icons.draw_rounded,
                            label: 'رسم',
                            onTap: _openDrawingSheet,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Extra toolbar button ──
class _ExtraBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ExtraBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppTheme.primaryColor),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.tajawal(fontSize: 10, color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }
}

// ── Drawing Sheet ──
class _DrawingSheet extends StatefulWidget {
  const _DrawingSheet();

  @override
  State<_DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends State<_DrawingSheet> {
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3;
  late SignatureController _sigController;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _sigController.dispose();
    super.dispose();
  }

  void _rebuildController() {
    final points = _sigController.points;
    _sigController.dispose();
    _sigController = SignatureController(
      penStrokeWidth: _strokeWidth,
      penColor: _selectedColor,
      exportBackgroundColor: Colors.white,
      points: points,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'الرسم اليدوي',
                  style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _sigController.clear()),
                  child: Text('مسح', style: GoogleFonts.tajawal(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final image = await _sigController.toPngBytes();
                    if (context.mounted) Navigator.pop(context, image);
                  },
                  child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
                ),
              ],
            ),
          ),
          // Color palette + stroke width
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final color in _palette)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                        _rebuildController();
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: _selectedColor == color
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  ),
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1,
                    max: 12,
                    divisions: 11,
                    activeColor: _selectedColor,
                    onChanged: (v) {
                      setState(() {
                        _strokeWidth = v;
                        _rebuildController();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Canvas
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Signature(
                key: ValueKey(_sigController),
                controller: _sigController,
                backgroundColor: Colors.grey[100]!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  final List<Color> _palette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];
}
