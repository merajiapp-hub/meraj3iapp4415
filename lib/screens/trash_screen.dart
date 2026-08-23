import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/notes_provider.dart';
import 'package:intl/intl.dart' as intl;

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<NotesProvider>(context);
    final trashNotes = provider.trashedNotes;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'سلة المحذوفات',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: trashNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 80, color: isDark ? Colors.white24 : Colors.black26),
                  const SizedBox(height: 16),
                  Text('السلة فارغة', style: GoogleFonts.tajawal(fontSize: 18, color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: trashNotes.length,
              itemBuilder: (context, index) {
                final note = trashNotes[index];
                final dateStr = intl.DateFormat('yyyy/MM/dd HH:mm').format(note.deletedAt ?? note.updatedAt);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isNotEmpty ? note.title : 'بدون عنوان',
                              style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore, color: Colors.green),
                                tooltip: 'استعادة',
                                onPressed: () {
                                  provider.restoreFromTrash(note.id);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت الاستعادة بنجاح', style: GoogleFonts.tajawal())));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                tooltip: 'حذف نهائي',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('حذف نهائي', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                                      content: Text('لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟', style: GoogleFonts.tajawal()),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: GoogleFonts.tajawal())),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () {
                                            provider.deleteNote(note.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: Text('حذف نهائياً', style: GoogleFonts.tajawal(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('تم الحذف في: $dateStr', style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
