import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';
import '../services/note_export_service.dart';

// ─── Page Background Painter ─────────────────────────────────────────────────
class _NotePagePainter extends CustomPainter {
  final String pageStyle;
  final Color lineColor;

  const _NotePagePainter({required this.pageStyle, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (pageStyle == 'blank') return;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.6;
    if (pageStyle == 'lined') {
      const spacing = 32.0;
      const startY = 60.0;
      for (double y = startY; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (pageStyle == 'dotted') {
      paint.style = PaintingStyle.fill;
      const spacing = 24.0;
      const startY = 60.0;
      for (double y = startY; y < size.height; y += spacing) {
        for (double x = 0; x < size.width; x += spacing) {
          canvas.drawCircle(Offset(x, y), 1.2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NotePagePainter old) =>
      old.pageStyle != pageStyle || old.lineColor != lineColor;
}

// ─── Note Editor Screen ───────────────────────────────────────────────────────
class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late ScrollController _scrollController;
  late FocusNode _editorFocusNode;

  bool _isChanged = false;
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  String? _createdNoteId;
  bool _readMode = false;

  Color? _noteColor;
  String _selectedCategory = 'اخرى';
  String _selectedFont = 'Tajawal';
  String _pageStyle = 'blank';
  int _wordCount = 0;
  int _charCount = 0;

  final List<String> _fonts = [
    'Tajawal',
    'Amiri',
    'Cairo',
    'El Messiri',
    'Reem Kufi',
    'Lalezar',
    'Changa',
  ];

  final List<String> _categories = [
    'الرياضيات',
    'العلوم',
    'اللغة العربية',
    'التاريخ',
    'الجغرافيا',
    'التربية الاسلامية',
    'مراجعة',
    'افكار',
    'اخرى',
  ];

  final List<Color> _availableColors = [
    Colors.white,
    const Color(0xFFFDE68A),
    const Color(0xFFFECACA),
    const Color(0xFFBBF7D0),
    const Color(0xFFBFDBFE),
    const Color(0xFFE9D5FF),
    const Color(0xFFFED7AA),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _editorFocusNode = FocusNode();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _pageStyle = widget.note?.pageSettings?.paperType ?? 'blank';

    final contentJson = widget.note?.content ?? '';
    quill.Document doc;
    if (contentJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentJson);
        doc = quill.Document.fromJson(decoded);
      } catch (e) {
        doc = quill.Document()..insert(0, contentJson);
      }
    } else {
      doc = quill.Document();
    }

    _quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _noteColor = widget.note?.color != null
        ? Color(widget.note!.color!)
        : Colors.white;

    if (widget.note?.tags != null && widget.note!.tags.isNotEmpty) {
      _selectedCategory = widget.note!.tags.first;
    }

    _updateCounts();
    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);
  }

  void _updateCounts() {
    final text = _quillController.document.toPlainText().trim();
    _charCount = text.length;
    _wordCount = text.isEmpty
        ? 0
        : text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void _onTextChanged() {
    _updateCounts();
    if (!_isChanged) setState(() => _isChanged = true);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 1500), _autoSave);
  }

  Future<void> _autoSave() async {
    if (!_isChanged || !mounted) return;
    setState(() => _isSaving = true);
    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    if (title.isEmpty && _quillController.document.isEmpty()) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final existingId = widget.note?.id ?? _createdNoteId;
    final pageSettings = NotePageSettings(paperType: _pageStyle);
    try {
      if (existingId != null) {
        await provider.updateNote(
          existingId,
          title.isEmpty ? 'بدون عنوان' : title,
          content,
          color: _noteColor?.toARGB32(),
          tags: [_selectedCategory],
          pageSettings: pageSettings,
        );
      } else {
        _createdNoteId = await provider.addNote(
          title.isEmpty ? 'بدون عنوان' : title,
          content,
          color: _noteColor?.toARGB32(),
          tags: [_selectedCategory],
          pageSettings: pageSettings,
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isChanged = false;
        });
      }
    }
  }

  Future<void> _saveAndPop() async {
    _autoSaveTimer?.cancel();
    final title = _titleController.text.trim();
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    if (title.isEmpty && _quillController.document.isEmpty()) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final provider = Provider.of<NotesProvider>(context, listen: false);
    final existingId = widget.note?.id ?? _createdNoteId;
    final pageSettings = NotePageSettings(paperType: _pageStyle);
    if (existingId == null) {
      await provider.addNote(
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        tags: [_selectedCategory],
        pageSettings: pageSettings,
      );
    } else {
      await provider.updateNote(
        existingId,
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        tags: [_selectedCategory],
        pageSettings: pageSettings,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _noteTitle => _titleController.text.trim().isEmpty
      ? 'ملاحظة MERAJ3I'
      : _titleController.text.trim();
  String get _noteContent => _quillController.document.toPlainText().trim();

  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final plainText = _quillController.document.toPlainText();
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: '$title\n\n$plainText'.trim(),
          subject: title.isEmpty ? 'ملاحظة MERAJ3I' : title,
        ),
      );
    } catch (error) {
      _showExportError(error);
    }
  }

  Future<void> _exportTextFile() async {
    try {
      final file = XFile.fromData(
        NoteExportService.textBytes(title: _noteTitle, content: _noteContent),
        name: '${_safeFileName(_noteTitle)}.txt',
        mimeType: 'text/plain',
      );
      await SharePlus.instance.share(
        ShareParams(files: [file], subject: _noteTitle),
      );
    } catch (error) {
      _showExportError(error);
    }
  }

  Future<void> _exportPdfFile() async {
    try {
      final bytes = await NoteExportService.pdfBytes(
        title: _noteTitle,
        content: _noteContent,
        pageStyle: _pageStyle,
        includeBackground: _pageStyle != 'blank',
      );
      final file = XFile.fromData(
        bytes,
        name: '${_safeFileName(_noteTitle)}.pdf',
        mimeType: 'application/pdf',
      );
      await SharePlus.instance.share(
        ShareParams(files: [file], subject: _noteTitle),
      );
    } catch (error) {
      _showExportError(error);
    }
  }

  String _safeFileName(String value) => value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');

  void _showExportError(Object error) {
    debugPrint('Note export error: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تعذر تصدير الملاحظة. حاول مرة اخرى.',
          style: GoogleFonts.tajawal(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExportMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Text(
              'مشاركة وتصدير',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _exportTile(
              ctx,
              Icons.share_rounded,
              'مشاركة كنص',
              const Color(0xFF3B82F6),
              _shareNote,
            ),
            _exportTile(
              ctx,
              Icons.picture_as_pdf_rounded,
              'تصدير PDF (عربي)',
              const Color(0xFFDC2626),
              _exportPdfFile,
            ),
            _exportTile(
              ctx,
              Icons.description_rounded,
              'تصدير TXT',
              const Color(0xFF16A34A),
              _exportTextFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportTile(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    Future<void> Function() action,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_left_rounded, color: Colors.grey[400]),
      onTap: () async {
        Navigator.pop(ctx);
        await action();
      },
    );
  }

  void _showOptionsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'لون الملاحظة',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: color == Colors.white
                                  ? Colors.black
                                  : Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'نوع الصفحة',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _pageChip(ctx, 'blank', 'بدون'),
                  const SizedBox(width: 10),
                  _pageChip(ctx, 'lined', 'اسطر'),
                  const SizedBox(width: 10),
                  _pageChip(ctx, 'dotted', 'نقاط'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'تصنيف',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white12 : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.tajawal(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'خط الكتابة',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
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
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white12 : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        font,
                        style: GoogleFonts.getFont(
                          font,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
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
      ),
    );
  }

  Widget _pageChip(BuildContext ctx, String style, String label) {
    final isSelected = _pageStyle == style;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _pageStyle = style;
            _isChanged = true;
          });
          _scheduleAutoSave();
          Navigator.pop(ctx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                : (isDark ? Colors.white12 : Colors.grey[100]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardToolbar(Color textColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  _tb(
                    Icons.format_bold,
                    'عريض',
                    () =>
                        _quillController.formatSelection(quill.Attribute.bold),
                  ),
                  _tb(
                    Icons.format_italic,
                    'مائل',
                    () => _quillController.formatSelection(
                      quill.Attribute.italic,
                    ),
                  ),
                  _tb(
                    Icons.format_underlined,
                    'تسطير',
                    () => _quillController.formatSelection(
                      quill.Attribute.underline,
                    ),
                  ),
                  _tb(
                    Icons.format_strikethrough,
                    'شطب',
                    () => _quillController.formatSelection(
                      quill.Attribute.strikeThrough,
                    ),
                  ),
                  _div(),
                  _tb(
                    Icons.format_list_bulleted,
                    'نقطية',
                    () => _quillController.formatSelection(quill.Attribute.ul),
                  ),
                  _tb(
                    Icons.format_list_numbered,
                    'مرقمة',
                    () => _quillController.formatSelection(quill.Attribute.ol),
                  ),
                  _tb(
                    Icons.checklist_rounded,
                    'مهام',
                    () => _quillController.formatSelection(
                      quill.Attribute.unchecked,
                    ),
                  ),
                  _div(),
                  _tb(
                    Icons.format_quote_rounded,
                    'اقتباس',
                    () => _quillController.formatSelection(
                      quill.Attribute.blockQuote,
                    ),
                  ),
                  _tb(
                    Icons.title_rounded,
                    'H1',
                    () => _quillController.formatSelection(quill.Attribute.h1),
                  ),
                  _tb(
                    Icons.text_fields_rounded,
                    'H2',
                    () => _quillController.formatSelection(quill.Attribute.h2),
                  ),
                  _div(),
                  _tb(
                    Icons.format_align_right_rounded,
                    'يمين',
                    () => _quillController.formatSelection(
                      quill.Attribute.rightAlignment,
                    ),
                  ),
                  _tb(
                    Icons.format_align_center_rounded,
                    'وسط',
                    () => _quillController.formatSelection(
                      quill.Attribute.centerAlignment,
                    ),
                  ),
                  _div(),
                  _tb(Icons.undo_rounded, 'تراجع', () {
                    if (_quillController.hasUndo) _quillController.undo();
                  }),
                  _tb(Icons.redo_rounded, 'اعادة', () {
                    if (_quillController.hasRedo) _quillController.redo();
                  }),
                  _div(),
                  _tb(Icons.keyboard_hide_rounded, 'اخفاء', () {
                    _editorFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _badge('كلمة', '$_wordCount', const Color(0xFF3B82F6)),
                      const SizedBox(width: 8),
                      _badge('حرف', '$_charCount', const Color(0xFF8B5CF6)),
                    ],
                  ),
                  if (_isSaving)
                    Row(
                      children: [
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'جار الحفظ...',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                  else if (!_isChanged)
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_done_rounded,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'تم الحفظ',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'لم يحفظ',
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tb(IconData icon, String tooltip, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 19,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _div() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  Widget _badge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$value $label',
        style: GoogleFonts.outfit(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
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
      bgColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.65), bgColor);
    }
    final textColor = (isDark && bgColor == const Color(0xFF0F172A))
        ? Colors.white
        : Colors.black87;
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 82,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: _saveAndPop,
                splashRadius: 18,
              ),
              Expanded(
                child: Center(
                  child: _isSaving
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'جار الحفظ...',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        )
                      : (!_isChanged
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.cloud_done_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'تم الحفظ',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink()),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _readMode ? Icons.edit_note_rounded : Icons.menu_book_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _readMode = !_readMode;
                  _quillController.readOnly = _readMode;
                });
                if (_readMode) {
                  _editorFocusNode.unfocus();
                  FocusScope.of(context).unfocus();
                }
              },
              tooltip: _readMode ? 'وضع التحرير' : 'وضع القراءة',
            ),
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _showOptionsModal,
              tooltip: 'الخيارات',
            ),
            IconButton(
              icon: const Icon(
                Icons.ios_share_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: _showExportMenu,
              tooltip: 'مشاركة',
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(26),
              bottomRight: Radius.circular(26),
            ),
          ),
        ),
        body: Container(
          color: bgColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  controller: _titleController,
                  textDirection: TextDirection.rtl,
                  readOnly: _readMode,
                  style: GoogleFonts.tajawal(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'عنوان الملاحظة...',
                    hintStyle: GoogleFonts.tajawal(
                      color: textColor.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  color: textColor.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: CustomPaint(
                  painter: _NotePagePainter(
                    pageStyle: _pageStyle,
                    lineColor: lineColor,
                  ),
                  child: GestureDetector(
                    onTap: _readMode
                        ? null
                        : () => _editorFocusNode.requestFocus(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Material(
                          color: bgColor,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              canvasColor: bgColor,
                              scaffoldBackgroundColor: bgColor,
                              cardColor: bgColor,
                              colorScheme: Theme.of(
                                context,
                              ).colorScheme.copyWith(surface: bgColor),
                            ),
                            child: quill.QuillEditor(
                              controller: _quillController,
                              focusNode: _editorFocusNode,
                              scrollController: _scrollController,
                              config: quill.QuillEditorConfig(
                                autoFocus: !_readMode,
                                expands: true,
                                scrollable: true,
                                showCursor: !_readMode,
                                padding: const EdgeInsets.only(bottom: 80),
                                placeholder:
                                    '«اكتب ما يستحق القراءة، أو افعل ما يستحق الكتابة»\nابدأ بتدوين أفكارك هنا...',
                                customStyles: quill.DefaultStyles(
                                  placeHolder: quill.DefaultTextBlockStyle(
                                    GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: 18,
                                      color: textColor.withAlpha(76),
                                    ),
                                    const quill.HorizontalSpacing(0, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  paragraph: quill.DefaultTextBlockStyle(
                                    GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: _readMode ? 19 : 18,
                                      color: textColor,
                                      height: _readMode ? 2.0 : 1.7,
                                    ),
                                    const quill.HorizontalSpacing(0, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  h1: quill.DefaultTextBlockStyle(
                                    GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: 30,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const quill.HorizontalSpacing(0, 0),
                                    const quill.VerticalSpacing(16, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  h2: quill.DefaultTextBlockStyle(
                                    GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: 24,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const quill.HorizontalSpacing(0, 0),
                                    const quill.VerticalSpacing(8, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  h3: quill.DefaultTextBlockStyle(
                                    GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: 20,
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const quill.HorizontalSpacing(0, 0),
                                    const quill.VerticalSpacing(6, 0),
                                    const quill.VerticalSpacing(0, 0),
                                    null,
                                  ),
                                  lists: quill.DefaultListBlockStyle(
                                    GoogleFonts.getFont(
                                      _selectedFont,
                                      fontSize: 17,
                                      color: textColor,
                                      height: 1.7,
                                    ),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _readMode
            ? null
            : _buildKeyboardToolbar(textColor, isDark),
      ),
    );
  }
}
