import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';

class NotesSettingsScreen extends StatefulWidget {
  const NotesSettingsScreen({super.key});

  @override
  State<NotesSettingsScreen> createState() => _NotesSettingsScreenState();
}

class _NotesSettingsScreenState extends State<NotesSettingsScreen> {
  bool _autoSave = true;
  bool _wordCount = true;
  bool _focusMode = false;
  String _trashDuration = '30'; // days: 7, 30, 60, 90, never
  String _defaultPaper = 'blank';
  double _defaultFontSize = 17.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSave = prefs.getBool('notes_autoSave') ?? true;
      _wordCount = prefs.getBool('notes_wordCount') ?? true;
      _focusMode = prefs.getBool('notes_focusMode') ?? false;
      _trashDuration = prefs.getString('notes_trashDuration') ?? '30';
      _defaultPaper = prefs.getString('notes_defaultPaper') ?? 'blank';
      _defaultFontSize = prefs.getDouble('notes_defaultFontSize') ?? 17.0;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    if (value is double) await prefs.setDouble(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('إعدادات الملاحظات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // المحرر
          _buildSectionHeader('المحرر', isDark),
          _buildSettingsCard(isDark, children: [
            _buildSwitch('الحفظ التلقائي', 'يحفظ الملاحظة أثناء الكتابة', Icons.save_outlined, _autoSave, (v) {
              setState(() => _autoSave = v);
              _savePref('notes_autoSave', v);
            }, isDark),
            _buildDivider(isDark),
            _buildSwitch('عداد الكلمات', 'يعرض عدد الكلمات أسفل العنوان', Icons.text_snippet_outlined, _wordCount, (v) {
              setState(() => _wordCount = v);
              _savePref('notes_wordCount', v);
            }, isDark),
            _buildDivider(isDark),
            _buildSwitch('وضع التركيز', 'يفعّل وضع التركيز عند الفتح تلقائيًا', Icons.fullscreen_rounded, _focusMode, (v) {
              setState(() => _focusMode = v);
              _savePref('notes_focusMode', v);
            }, isDark),
          ]),

          const SizedBox(height: 20),

          // الصفحة
          _buildSectionHeader('إعدادات الصفحة', isDark),
          _buildSettingsCard(isDark, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نمط الورق الافتراضي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaperChip('blank', 'فارغ', isDark),
                      _buildPaperChip('horizontal', 'أفقي', isDark),
                      _buildPaperChip('grid', 'شبكة', isDark),
                      _buildPaperChip('dots', 'نقاط', isDark),
                      _buildPaperChip('school', 'مدرسي', isDark),
                    ],
                  ),
                ],
              ),
            ),
            _buildDivider(isDark),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('حجم الخط الافتراضي: ${_defaultFontSize.round()}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Slider(
                    value: _defaultFontSize,
                    min: 12, max: 24,
                    divisions: 12,
                    activeColor: AppTheme.primaryColor,
                    label: '${_defaultFontSize.round()}',
                    onChanged: (v) {
                      setState(() => _defaultFontSize = v);
                      _savePref('notes_defaultFontSize', v);
                    },
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),

          // سلة المهملات
          _buildSectionHeader('سلة المهملات', isDark),
          _buildSettingsCard(isDark, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('احتفظ بالملاحظات المحذوفة لمدة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDurationChip('7', '7 أيام', isDark),
                      _buildDurationChip('30', '30 يومًا', isDark),
                      _buildDurationChip('60', '60 يومًا', isDark),
                      _buildDurationChip('90', '90 يومًا', isDark),
                      _buildDurationChip('never', 'أبدًا', isDark),
                    ],
                  ),
                ],
              ),
            ),
            _buildDivider(isDark),
            ListTile(
              leading: Icon(Icons.delete_sweep_rounded, color: Colors.red.withValues(alpha: 0.8)),
              title: Text('إفراغ سلة المهملات', style: GoogleFonts.tajawal(color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.red),
              onTap: () => _confirmEmptyTrash(context),
            ),
          ]),

          const SizedBox(height: 20),

          // النسخ الاحتياطي
          _buildSectionHeader('النسخ الاحتياطي', isDark),
          _buildSettingsCard(isDark, children: [
            ListTile(
              leading: const Icon(Icons.backup_rounded, color: AppTheme.primaryColor),
              title: Text('إنشاء نسخة احتياطية', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              subtitle: Text('تصدير جميع الملاحظات كملف', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => _createBackup(context),
            ),
            _buildDivider(isDark),
            ListTile(
              leading: const Icon(Icons.restore_page_rounded, color: AppTheme.primaryColor),
              title: Text('استعادة من ملف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              subtitle: Text('استيراد ملف نسخة احتياطية', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => _importBackup(context),
            ),
          ]),

          const SizedBox(height: 20),

          // إعدادات متقدمة
          _buildSectionHeader('إعدادات متقدمة', isDark),
          _buildSettingsCard(isDark, children: [
            ListTile(
              leading: const Icon(Icons.cleaning_services_rounded, color: Colors.orange),
              title: Text('مسح الملفات المؤقتة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              subtitle: Text('حرر مساحة التخزين', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
              onTap: () => _clearTempFiles(context),
            ),
            _buildDivider(isDark),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore_rounded, color: Colors.orange),
              title: Text('إعادة إعدادات المحرر', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              subtitle: Text('إعادة جميع الإعدادات للوضع الافتراضي', style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
              onTap: () => _resetAllSettings(context),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: GoogleFonts.tajawal(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitch(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 12)),
      trailing: Switch(activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5), activeThumbColor: AppTheme.primaryColor, value: value, onChanged: onChanged),
    );
  }

  Widget _buildDivider(bool isDark) => Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06));

  Widget _buildPaperChip(String type, String label, bool isDark) {
    final isSelected = _defaultPaper == type;
    return GestureDetector(
      onTap: () {
        setState(() => _defaultPaper = type);
        _savePref('notes_defaultPaper', type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.tajawal(fontSize: 13, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
      ),
    );
  }

  Widget _buildDurationChip(String value, String label, bool isDark) {
    final isSelected = _trashDuration == value;
    return GestureDetector(
      onTap: () {
        setState(() => _trashDuration = value);
        _savePref('notes_trashDuration', value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.tajawal(fontSize: 13, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54))),
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إفراغ السلة؟', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('سيتم حذف جميع العناصر في سلة المهملات نهائيًا.', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final provider = Provider.of<NotesProvider>(context, listen: false);
              final trashed = List.from(provider.trashedNotes);
              for (final note in trashed) { provider.deleteNote(note.id); }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إفراغ سلة المهملات', style: GoogleFonts.tajawal()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            },
            child: Text('إفراغ', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          const SizedBox(width: 12),
          Text('جارٍ إنشاء النسخة الاحتياطية...', style: GoogleFonts.tajawal()),
        ]),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ فتح الملف...', style: GoogleFonts.tajawal()),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _clearTempFiles(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم مسح الملفات المؤقتة', style: GoogleFonts.tajawal()),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetAllSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إعادة الإعدادات؟', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text('سيتم إعادة جميع إعدادات المحرر للوضع الافتراضي.', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('notes_autoSave');
              await prefs.remove('notes_wordCount');
              await prefs.remove('notes_focusMode');
              await prefs.remove('notes_trashDuration');
              await prefs.remove('notes_defaultPaper');
              await prefs.remove('notes_defaultFontSize');
              await _loadSettings();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('إعادة', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
