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
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';
import '../features/notes/ui/widgets/paper_background.dart';
import '../services/pdf_export_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late quill.QuillController _quillController;
  late FocusNode _focusNode;
  late ScrollController _editorScrollController;

  bool _isChanged = false;
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _savedOnce = false;
  bool _isFocusMode = false;
  String? _createdNoteId;

  Color? _noteColor;
  NotePageSettings _pageSettings = NotePageSettings();

  // Stats
  int _wordCount = 0;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _editorScrollController = ScrollController();
    _titleController = TextEditingController(text: widget.note?.title ?? '');

    if (widget.note?.color != null) {
      _noteColor = Color(widget.note!.color!);
    }
    if (widget.note?.pageSettings != null) {
      _pageSettings = widget.note!.pageSettings!;
    }

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
      _updateStats();
    });

    _titleController.addListener(() {
      if (!_isChanged) setState(() => _isChanged = true);
      _scheduleAutoSave();
    });

    _updateStats();
  }

  void _updateStats() {
    final text = _quillController.document.toPlainText().trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    if (mounted) {
      setState(() {
        _wordCount = words;
        _charCount = text.length;
      });
    }
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
      await provider.updateNote(
        existingId,
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        pageSettings: _pageSettings,
      );
    } else {
      await provider.addNote(
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        pageSettings: _pageSettings,
      );
    }

    _savedOnce = true;

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isChanged = false;
      });
    }
  }

  void _saveAndPop() {
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
      provider.addNote(
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        pageSettings: _pageSettings,
      );
    } else {
      provider.updateNote(
        existingId,
        title.isEmpty ? 'بدون عنوان' : title,
        content,
        color: _noteColor?.toARGB32(),
        pageSettings: _pageSettings,
      );
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  // ── Image Picker ──
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null && mounted) {
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        index < 0 ? 0 : index,
        length < 0 ? 0 : length,
        quill.BlockEmbed.image(pickedFile.path),
        null,
      );
      setState(() => _isChanged = true);
    }
  }

  // ── File Picker ──
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc'],
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرفاق: ${file.name}', style: GoogleFonts.tajawal()),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        setState(() => _isChanged = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر فتح الملف، حاول مرة أخرى.', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Drawing Sheet ──
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
        index < 0 ? 0 : index,
        length < 0 ? 0 : length,
        quill.BlockEmbed.image(file.path),
        null,
      );
      setState(() => _isChanged = true);
    }
  }

  // ── Page Settings Sheet ──
  void _openPageSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PageSettingsSheet(
        settings: _pageSettings,
        noteColor: _noteColor,
        onSettingsChanged: (newSettings) {
          setState(() {
            _pageSettings = newSettings;
            _isChanged = true;
          });
          _scheduleAutoSave();
        },
        onColorChanged: (color) {
          setState(() {
            _noteColor = color;
            _isChanged = true;
          });
          _scheduleAutoSave();
        },
      ),
    );
  }

  // ── Font Library Sheet ──
  void _openFontLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FontLibrarySheet(
        controller: _quillController,
      ),
    );
  }

  // ── Stats Sheet ──
  void _openStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('إحصائيات الملاحظة', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 24),
                  _statRow(Icons.text_snippet_rounded, 'عدد الكلمات', '$_wordCount كلمة', isDark),
                  _statRow(Icons.abc_rounded, 'عدد الأحرف', '$_charCount حرف', isDark),
                  _statRow(Icons.timer_rounded, 'وقت القراءة', '${(_wordCount / 200).ceil()} دقيقة', isDark),
                  _statRow(Icons.calendar_today_rounded, 'تاريخ الإنشاء', widget.note != null ? '${widget.note!.createdAt.day}/${widget.note!.createdAt.month}/${widget.note!.createdAt.year}' : 'اليوم', isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.tajawal(color: isDark ? Colors.white70 : Colors.black54)),
          const Spacer(),
          Text(value, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  // ── Share ──
  Future<void> _shareNote() async {
    final title = _titleController.text.trim();
    final content = _quillController.document.toPlainText().trim();
    await SharePlus.instance.share(ShareParams(text: '$title\n\n$content', subject: title));
  }

  // ── More Options ──
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: AppTheme.primaryColor),
                  title: Text('مشاركة', style: GoogleFonts.tajawal()),
                  onTap: () { Navigator.pop(ctx); _shareNote(); },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor),
                  title: Text('تصدير كـ PDF', style: GoogleFonts.tajawal()),
                  onTap: () async { 
                    Navigator.pop(ctx); 
                    
                    final tempNote = Note(
                      id: widget.note?.id ?? _createdNoteId ?? 'temp',
                      title: _titleController.text.trim().isEmpty ? 'بدون عنوان' : _titleController.text.trim(),
                      content: jsonEncode(_quillController.document.toDelta().toJson()),
                      createdAt: widget.note?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                      isPinned: widget.note?.isPinned ?? false,
                      isFavorite: widget.note?.isFavorite ?? false,
                      isArchived: widget.note?.isArchived ?? false,
                      isDeleted: widget.note?.isDeleted ?? false,
                      folderId: widget.note?.folderId,
                      tags: widget.note?.tags ?? [],
                      wordCount: _wordCount,
                      pageCount: 1,
                      attachments: widget.note?.attachments ?? [],
                      drawings: widget.note?.drawings ?? [],
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('جارِ تحضير الملف...', style: GoogleFonts.tajawal())),
                    );
                    
                    try {
                      await PdfExportService.exportNoteToPdf(tempNote);
                    } catch(e) {
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ أثناء التصدير', style: GoogleFonts.tajawal()), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryColor),
                  title: Text('إحصائيات', style: GoogleFonts.tajawal()),
                  onTap: () { Navigator.pop(ctx); _openStats(); },
                ),
                ListTile(
                  leading: Icon(_isFocusMode ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: AppTheme.primaryColor),
                  title: Text(_isFocusMode ? 'الخروج من وضع التركيز' : 'وضع التركيز', style: GoogleFonts.tajawal()),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _isFocusMode = !_isFocusMode);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens_rounded, color: AppTheme.primaryColor),
                  title: Text('إعدادات الصفحة', style: GoogleFonts.tajawal()),
                  onTap: () { Navigator.pop(ctx); _openPageSettings(); },
                ),
                ListTile(
                  leading: const Icon(Icons.font_download_rounded, color: AppTheme.primaryColor),
                  title: Text('مكتبة الخطوط', style: GoogleFonts.tajawal()),
                  onTap: () { Navigator.pop(ctx); _openFontLibrary(); },
                ),
                const SizedBox(height: 8),
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

    Color bgColor;
    if (_noteColor != null) {
      bgColor = _noteColor!;
    } else if (_pageSettings.paperColor != null) {
      bgColor = Color(_pageSettings.paperColor!);
    } else {
      bgColor = isDark ? AppTheme.backgroundDark : const Color(0xFFFAFAF8);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _isFocusMode
            ? null
            : AppBar(
                backgroundColor: bgColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                  onPressed: _saveAndPop,
                ),
                title: _buildSaveStatus(isDark),
                actions: [
                  // Undo
                  IconButton(
                    icon: Icon(Icons.undo_rounded, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => _quillController.undo(),
                    tooltip: 'تراجع',
                  ),
                  // Redo
                  IconButton(
                    icon: Icon(Icons.redo_rounded, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => _quillController.redo(),
                    tooltip: 'إعادة',
                  ),
                  // More Options
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: _showMoreOptions,
                  ),
                ],
              ),
        body: PaperBackground(
          settings: _pageSettings,
          child: Column(
            children: [
              if (_isFocusMode)
                Padding(
                  padding: const EdgeInsets.only(top: 40, right: 16),
                  child: Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                      onPressed: () => setState(() => _isFocusMode = false),
                    ),
                  ),
                ),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
                  maxLines: null,
                ),
              ),

              // ── Divider + Stats ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                    const SizedBox(width: 8),
                    Text(
                      '$_wordCount كلمة · $_charCount حرف',
                      style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                  ],
                ),
              ),

              // ── Editor ──
              Expanded(
                child: GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: quill.QuillEditor(
                    controller: _quillController,
                    focusNode: _focusNode,
                    scrollController: _editorScrollController,
                    config: quill.QuillEditorConfig(
                      scrollable: true,
                      expands: true,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      placeholder: 'ابدأ بكتابة ملاحظتك...',
                      customStyles: quill.DefaultStyles(
                        paragraph: quill.DefaultTextBlockStyle(
                          GoogleFonts.tajawal(
                            fontSize: 17,
                            height: 1.75,
                            color: isDark ? Colors.white.withValues(alpha: 0.88) : Colors.black.withValues(alpha: 0.85),
                          ),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(4, 4),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        h1: quill.DefaultTextBlockStyle(
                          GoogleFonts.tajawal(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(8, 4),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                        h2: quill.DefaultTextBlockStyle(
                          GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          const quill.HorizontalSpacing(0, 0),
                          const quill.VerticalSpacing(6, 4),
                          const quill.VerticalSpacing(0, 0),
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom Toolbar ──
              if (!_isFocusMode) _buildToolbar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveStatus(bool isDark) {
    if (_isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('جارٍ الحفظ...', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey)),
        ],
      );
    }
    if (_isChanged) {
      return Text('غير محفوظ', style: GoogleFonts.tajawal(fontSize: 13, color: Colors.orange));
    }
    if (_savedOnce || widget.note != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text('تم الحفظ', style: GoogleFonts.tajawal(fontSize: 13, color: AppTheme.primaryColor)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildToolbar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.07))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quill Formatting Toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: quill.QuillSimpleToolbar(
                controller: _quillController,
                config: const quill.QuillSimpleToolbarConfig(
                  showFontFamily: false,
                  showFontSize: true,
                  showSubscript: false,
                  showSuperscript: false,
                  showInlineCode: false,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showClearFormat: true,
                  showAlignmentButtons: true,
                  showHeaderStyle: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: true,
                  showCodeBlock: false,
                  showQuote: true,
                  showIndent: true,
                  showLink: true,
                  showUndo: false,
                  showRedo: false,
                  showDirection: true,
                ),
              ),
            ),
            // Extra Action Row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildExtraBtn(icon: Icons.image_rounded, label: 'صورة', onTap: () => _pickImage(ImageSource.gallery)),
                    _buildExtraBtn(icon: Icons.camera_alt_rounded, label: 'كاميرا', onTap: () => _pickImage(ImageSource.camera)),
                    _buildExtraBtn(icon: Icons.draw_rounded, label: 'رسم', onTap: _openDrawingSheet),
                    _buildExtraBtn(icon: Icons.attach_file_rounded, label: 'ملف', onTap: _pickFile),
                    _buildExtraBtn(icon: Icons.color_lens_rounded, label: 'الصفحة', onTap: _openPageSettings),
                    _buildExtraBtn(icon: Icons.font_download_rounded, label: 'الخط', onTap: _openFontLibrary),
                    _buildExtraBtn(icon: Icons.table_chart_outlined, label: 'جدول', onTap: _insertTable),
                    _buildExtraBtn(icon: Icons.checklist_rounded, label: 'مهام', onTap: _insertChecklist),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraBtn({required IconData icon, required String label, required VoidCallback onTap}) {
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
            Text(label, style: GoogleFonts.tajawal(fontSize: 9, color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }

  void _insertTable() {
    showDialog(
      context: context,
      builder: (ctx) => _InsertTableDialog(
        onInsert: (rows, cols) {
          final tableText = StringBuffer();
          for (int r = 0; r < rows; r++) {
            tableText.write('|');
            for (int c = 0; c < cols; c++) {
              tableText.write('  خلية $r-$c  |');
            }
            tableText.write('\n');
          }
          final idx = _quillController.selection.baseOffset;
          _quillController.replaceText(idx < 0 ? 0 : idx, 0, tableText.toString(), null);
          setState(() => _isChanged = true);
        },
      ),
    );
  }

  void _insertChecklist() {
    _quillController.formatSelection(quill.Attribute.unchecked);
    setState(() => _isChanged = true);
  }
}

// ──────────────────────────────────────
// Page Settings Bottom Sheet
// ──────────────────────────────────────
class _PageSettingsSheet extends StatefulWidget {
  final NotePageSettings settings;
  final Color? noteColor;
  final ValueChanged<NotePageSettings> onSettingsChanged;
  final ValueChanged<Color?> onColorChanged;

  const _PageSettingsSheet({
    required this.settings,
    required this.noteColor,
    required this.onSettingsChanged,
    required this.onColorChanged,
  });

  @override
  State<_PageSettingsSheet> createState() => _PageSettingsSheetState();
}

class _PageSettingsSheetState extends State<_PageSettingsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotePageSettings _settings;
  Color? _noteColor;

  final List<Map<String, dynamic>> _paperTypes = [
    {'type': 'blank', 'label': 'فارغ', 'icon': Icons.crop_square},
    {'type': 'horizontal', 'label': 'أفقي', 'icon': Icons.horizontal_rule},
    {'type': 'vertical', 'label': 'رأسي', 'icon': Icons.vertical_align_center_rounded},
    {'type': 'grid', 'label': 'شبكة', 'icon': Icons.grid_4x4_rounded},
    {'type': 'dots', 'label': 'نقاط', 'icon': Icons.scatter_plot_rounded},
    {'type': 'school', 'label': 'مدرسي', 'icon': Icons.school_rounded},
  ];

  final List<Color?> _noteColors = [
    null, // Default
    const Color(0xFFFAFAF8),
    const Color(0xFFFFF8E1),
    const Color(0xFFE8F5E9),
    const Color(0xFFE3F2FD),
    const Color(0xFFEDE7F6),
    const Color(0xFFFFEBEE),
    const Color(0xFFFCE4EC),
    const Color(0xFFF3E5F5),
    const Color(0xFFE0F7FA),
    const Color(0xFF1A1A2E),
    const Color(0xFF0D1117),
    const Color(0xFF1E2139),
  ];

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _noteColor = widget.noteColor;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'إعدادات الصفحة',
                  style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    final reset = NotePageSettings();
                    setState(() => _settings = reset);
                    widget.onSettingsChanged(reset);
                  },
                  child: Text('إعادة تعيين', style: GoogleFonts.tajawal(color: Colors.grey)),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            tabs: const [Tab(text: 'الورق'), Tab(text: 'اللون')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaperTab(isDark),
                _buildColorTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نمط الورق', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _paperTypes.length,
            itemBuilder: (context, index) {
              final pt = _paperTypes[index];
              final isSelected = _settings.paperType == pt['type'];
              return GestureDetector(
                onTap: () {
                  setState(() => _settings = NotePageSettings(
                    paperType: pt['type'],
                    paperColor: _settings.paperColor,
                    isDark: _settings.isDark,
                    lineSpacing: _settings.lineSpacing,
                    lineColor: _settings.lineColor,
                    lineOpacity: _settings.lineOpacity,
                  ));
                  widget.onSettingsChanged(_settings);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(pt['icon'] as IconData, size: 28, color: isSelected ? AppTheme.primaryColor : Colors.grey),
                      const SizedBox(height: 6),
                      Text(pt['label'] as String, style: GoogleFonts.tajawal(fontSize: 12, color: isSelected ? AppTheme.primaryColor : Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Text('تباعد الأسطر', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Slider(
            value: _settings.lineSpacing,
            min: 16,
            max: 60,
            divisions: 11,
            activeColor: AppTheme.primaryColor,
            label: '${_settings.lineSpacing.round()}',
            onChanged: (v) {
              setState(() => _settings = NotePageSettings(
                paperType: _settings.paperType,
                paperColor: _settings.paperColor,
                isDark: _settings.isDark,
                lineSpacing: v,
                lineColor: _settings.lineColor,
                lineOpacity: _settings.lineOpacity,
              ));
              widget.onSettingsChanged(_settings);
            },
          ),

          const SizedBox(height: 8),
          Text('شفافية الخطوط', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          Slider(
            value: _settings.lineOpacity,
            min: 0.05,
            max: 0.5,
            activeColor: AppTheme.primaryColor,
            label: '${(_settings.lineOpacity * 100).round()}%',
            onChanged: (v) {
              setState(() => _settings = NotePageSettings(
                paperType: _settings.paperType,
                paperColor: _settings.paperColor,
                isDark: _settings.isDark,
                lineSpacing: _settings.lineSpacing,
                lineColor: _settings.lineColor,
                lineOpacity: v,
              ));
              widget.onSettingsChanged(_settings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('لون الخلفية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _noteColors.map((color) {
              final isSelected = _noteColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() => _noteColor = color);
                  widget.onColorChanged(color);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: color ?? (isDark ? Colors.black : Colors.white),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8)] : null,
                  ),
                  child: color == null ? Icon(Icons.block, color: Colors.grey.withValues(alpha: 0.5), size: 20) : (isSelected ? Icon(Icons.check, size: 20, color: (color.computeLuminance() > 0.5) ? Colors.black87 : Colors.white) : null),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────
// Font Library Sheet
// ──────────────────────────────────────
class _FontLibrarySheet extends StatefulWidget {
  final quill.QuillController controller;
  const _FontLibrarySheet({required this.controller});

  @override
  State<_FontLibrarySheet> createState() => _FontLibrarySheetState();
}

class _FontLibrarySheetState extends State<_FontLibrarySheet> {
  final List<Map<String, dynamic>> _arabicFonts = [
    {'name': 'Tajawal', 'label': 'تجوال - حديث'},
    {'name': 'Cairo', 'label': 'القاهرة - رسمي'},
    {'name': 'Amiri', 'label': 'أميري - كلاسيكي'},
    {'name': 'Scheherazade New', 'label': 'شهرزاد - تقليدي'},
    {'name': 'Noto Naskh Arabic', 'label': 'نسخ - واضح'},
    {'name': 'Almarai', 'label': 'المرعي - عصري'},
  ];

  String? _selectedFont;

  @override
  Widget build(BuildContext context) {
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
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text('مكتبة الخطوط', style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'خطوط عربية',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _arabicFonts.length,
              itemBuilder: (context, index) {
                final font = _arabicFonts[index];
                final isSelected = _selectedFont == font['name'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFont = font['name']);
                    widget.controller.formatSelection(
                      quill.Attribute.fromKeyValue('font', font['name']),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.07)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          font['label'],
                          style: GoogleFonts.getFont(font['name'], fontSize: 20, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'العلم نور والمعرفة قوة',
                          style: GoogleFonts.getFont(font['name'], fontSize: 15, color: isDark ? Colors.white60 : Colors.black54),
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
}

// ──────────────────────────────────────
// Insert Table Dialog
// ──────────────────────────────────────
class _InsertTableDialog extends StatefulWidget {
  final Function(int rows, int cols) onInsert;
  const _InsertTableDialog({required this.onInsert});

  @override
  State<_InsertTableDialog> createState() => _InsertTableDialogState();
}

class _InsertTableDialogState extends State<_InsertTableDialog> {
  int _rows = 3;
  int _cols = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('إدراج جدول', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('الصفوف: $_rows', style: GoogleFonts.tajawal()),
            Expanded(child: Slider(value: _rows.toDouble(), min: 1, max: 10, divisions: 9, activeColor: AppTheme.primaryColor, onChanged: (v) => setState(() => _rows = v.round()))),
          ]),
          Row(children: [
            Text('الأعمدة: $_cols', style: GoogleFonts.tajawal()),
            Expanded(child: Slider(value: _cols.toDouble(), min: 1, max: 8, divisions: 7, activeColor: AppTheme.primaryColor, onChanged: (v) => setState(() => _cols = v.round()))),
          ]),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.tajawal())),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () { Navigator.pop(context); widget.onInsert(_rows, _cols); },
          child: Text('إدراج', style: GoogleFonts.tajawal(color: Colors.white)),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────
// Drawing Sheet
// ──────────────────────────────────────
class _DrawingSheet extends StatefulWidget {
  const _DrawingSheet();
  @override
  State<_DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends State<_DrawingSheet> {
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  late SignatureController _sigController;

  final List<Color> _palette = [
    Colors.black, Colors.white, Colors.red, Colors.blue,
    Colors.green, Colors.orange, Colors.purple, Colors.teal,
    Colors.brown, Colors.pink,
  ];

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
      penColor: _isEraser ? Colors.white : _selectedColor,
      exportBackgroundColor: Colors.white,
      points: points,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text('لوحة الرسم اليدوي', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                // Eraser toggle
                GestureDetector(
                  onTap: () => setState(() { _isEraser = !_isEraser; _rebuildController(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isEraser ? Colors.orange.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _isEraser ? Colors.orange : Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.auto_fix_high_rounded, size: 18, color: _isEraser ? Colors.orange : Colors.grey),
                      const SizedBox(width: 4),
                      Text('ممحاة', style: GoogleFonts.tajawal(color: _isEraser ? Colors.orange : Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _sigController.clear()),
                  child: Text('مسح الكل', style: GoogleFonts.tajawal(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    final image = await _sigController.toPngBytes();
                    if (context.mounted) Navigator.pop(context, image);
                  },
                  child: Text('إضافة', style: GoogleFonts.tajawal(color: Colors.white)),
                ),
              ],
            ),
          ),

          // Color palette + stroke width
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                // Colors
                ...(_palette.map((color) => GestureDetector(
                  onTap: () => setState(() {
                    _selectedColor = color;
                    _isEraser = false;
                    _rebuildController();
                  }),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (!_isEraser && _selectedColor == color) ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
                        width: (!_isEraser && _selectedColor == color) ? 3 : 1,
                      ),
                    ),
                  ),
                ))),
                // Stroke slider
                Expanded(
                  child: Slider(
                    value: _strokeWidth,
                    min: 1, max: 20,
                    activeColor: _isEraser ? Colors.orange : _selectedColor,
                    onChanged: (v) => setState(() { _strokeWidth = v; _rebuildController(); }),
                  ),
                ),
                Text('${_strokeWidth.round()}px', style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Container(
                color: Colors.white,
                child: Signature(
                  key: ValueKey('${_sigController.hashCode}'),
                  controller: _sigController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
