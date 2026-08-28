import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<NotesProvider>(context);
    final trashed = provider.trashedNotes;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('سلة المهملات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 20)),
        actions: [
          if (trashed.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              label: Text('إفراغ الكل', style: GoogleFonts.tajawal(color: Colors.red)),
              onPressed: () => _confirmEmptyTrash(context, provider),
            ),
        ],
      ),
      body: trashed.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded, size: 80, color: isDark ? Colors.white12 : Colors.black12),
                  const SizedBox(height: 16),
                  Text('سلة المهملات فارغة', style: GoogleFonts.tajawal(fontSize: 18, color: isDark ? Colors.white38 : Colors.black38)),
                  const SizedBox(height: 8),
                  Text('الملاحظات المحذوفة ستظهر هنا', style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? Colors.white24 : Colors.black26)),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'الملاحظات المحذوفة قابلة للاستعادة في أي وقت. اضغط "حذف نهائي" لحذفها للأبد.',
                          style: GoogleFonts.tajawal(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: trashed.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final note = trashed[index];
                      return _buildTrashCard(context, note, provider, isDark);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTrashCard(BuildContext context, Note note, NotesProvider provider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, size: 20, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isNotEmpty ? note.title : 'بدون عنوان',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'محذوفة ${note.deletedAt != null ? intl.DateFormat('d MMM y', 'ar').format(note.deletedAt!) : ''}',
                        style: GoogleFonts.tajawal(fontSize: 12, color: Colors.red.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text('استعادة', style: GoogleFonts.tajawal()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      provider.restoreFromTrash(note.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تمت الاستعادة', style: GoogleFonts.tajawal()),
                          backgroundColor: AppTheme.primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: Text('حذف نهائي', style: GoogleFonts.tajawal()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _confirmPermanentDelete(context, note.id, provider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPermanentDelete(BuildContext context, String noteId, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('حذف نهائي؟', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text(
          'هل تريد حذف هذه الملاحظة نهائيًا؟\n\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.tajawal(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              provider.deleteNote(noteId);
              Navigator.pop(ctx);
            },
            child: Text('حذف نهائي', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, NotesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text('إفراغ السلة؟', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'سيتم حذف جميع الملاحظات الموجودة في سلة المهملات نهائيًا.\n\nهذه العملية لا يمكن التراجع عنها.',
          style: GoogleFonts.tajawal(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              final trashed = List<Note>.from(provider.trashedNotes);
              for (final note in trashed) {
                provider.deleteNote(note.id);
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('إفراغ السلة', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
