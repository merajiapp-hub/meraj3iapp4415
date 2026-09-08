import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/drive_url_service.dart';
import '../../../services/admin_activity_service.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteBook(String docId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('⚠️ حذف كتاب',
            style: TextStyle(color: Colors.white)),
        content: Text('هل تريد حذف الكتاب: "$title"؟',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('books').doc(docId).delete();
      
      // تسجيل النشاط
      await AdminActivityService.log(
        type: AdminActivityType.bookDeleted,
        title: 'حذف كتاب',
        description: 'تم حذف الكتاب: "$title"',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم حذف الكتاب'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في الحذف: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBookStatus(String docId, Map<String, dynamic> data, String title) async {
    final currentStatus = (data['is_active'] ?? data['isActive'] ?? true) as bool;

    try {
      await FirebaseFirestore.instance.collection('books').doc(docId).update({
        'is_active': !currentStatus,
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? '✅ تم تفعيل الكتاب: $title' : '✅ تم إيقاف الكتاب: $title'),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحديث الحالة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('إدارة الكتب',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث عن كتاب...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('books')
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('خطأ: ${snap.error}',
                          style: const TextStyle(color: Colors.red)));
                }
                var docs = snap.data?.docs ?? [];
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title =
                        (data['title'] ?? '').toString().toLowerCase();
                    final author =
                        (data['author'] ?? '').toString().toLowerCase();
                  final section =
                    (data['section'] ?? data['stage'] ?? '').toString().toLowerCase();
                  final grade =
                    (data['grade'] ?? data['year'] ?? '').toString().toLowerCase();
                  final category =
                    (data['category'] ?? data['type'] ?? data['bookType'] ?? '').toString().toLowerCase();
                  final subject =
                    (data['subject'] ?? data['material'] ?? '').toString().toLowerCase();
                    return title.contains(_search) ||
                    author.contains(_search) ||
                    section.contains(_search) ||
                    grade.contains(_search) ||
                    category.contains(_search) ||
                    subject.contains(_search);
                  }).toList();
                }
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد كتب',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    final d = doc.data() as Map<String, dynamic>;
                    final title = d['title'] ?? 'بدون عنوان';
                    final author = d['author'] ?? '';
                    final section = d['section'] ?? d['stage'] ?? '';
                    final grade = d['grade'] ?? d['year'] ?? '';
                    final category = d['category'] ?? d['type'] ?? d['bookType'] ?? '';
                    final subject = d['subject'] ?? d['material'] ?? '';
                    final isActive = (d['is_active'] ?? d['isActive'] ?? true) as bool;
                    final coverUrl = d['coverUrl'] ?? d['imageUrl'];
                    final opens = d['opens'] ?? d['openCount'] ?? 0;
                    final downloads = d['downloads'] ?? d['downloadCount'] ?? 0;
                    final favorites = d['favorites'] ?? d['favoriteCount'] ?? 0;

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: coverUrl != null
                                  ? Image.network(coverUrl,
                                      width: 55,
                                      height: 75,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          _bookPlaceholder())
                                  : _bookPlaceholder(),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isActive)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'غير نشط',
                                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  Text(title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  if (author.isNotEmpty)
                                    Text(author,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (section.isNotEmpty)
                                        _metaChip(section, Colors.blue),
                                      if (grade.isNotEmpty)
                                        _metaChip(grade, Colors.purple),
                                      if (category.isNotEmpty)
                                        _metaChip(category, Colors.green),
                                      if (subject.isNotEmpty)
                                        _metaChip(subject, Colors.orange),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _stat(Icons.visibility, '$opens'),
                                      const SizedBox(width: 12),
                                      _stat(Icons.download, '$downloads'),
                                      const SizedBox(width: 12),
                                      _stat(Icons.favorite, '$favorites'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: IconButton(
                                    icon: Icon(
                                      isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: isActive ? Colors.green : Colors.orange,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleBookStatus(doc.id, d, title),
                                    tooltip: isActive ? 'إيقاف الكتاب' : 'تفعيل الكتاب',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                                // Link Status Badge
                                Builder(builder: (context) {
                                  final url = d['url'] as String? ?? '';
                                  final status = DriveUrlService.getUrlStatus(url);
                                  final isGood = status == DriveUrlService.statusValid;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isGood ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isGood ? '✓ رابط صالح' : '⚠ تحتاج مراجعة',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 9,
                                        color: isGood ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }),
                                // Fix Link Button
                                IconButton(
                                  icon: const Icon(Icons.link_rounded, color: Colors.blue, size: 20),
                                  onPressed: () => _showEditLinkDialog(doc.id, d['title'] ?? '', d['url'] ?? ''),
                                  tooltip: 'تعديل الرابط',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () => _deleteBook(doc.id, title),
                                  tooltip: 'حذف الكتاب',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _showEditLinkDialog(String docId, String title, String currentUrl) async {
    final controller = TextEditingController(text: currentUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تعديل رابط الكتاب',
          style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'الرابط الجديد',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text('حفظ', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentUrl) {
      final fileId = DriveUrlService.extractFileId(result);
      await FirebaseFirestore.instance.collection('books').doc(docId).update({
        'url': result,
        'originalDriveUrl': currentUrl, // احتفظ بالرابط القديم
        'extractedFileId': fileId,
        'linkStatus': DriveUrlService.statusValid,
        'linkUpdatedAt': FieldValue.serverTimestamp(),
      });
      // Log the change in audit
      await AdminActivityService.log(
        type: AdminActivityType.bookUpdated,
        title: 'تعديل رابط كتاب',
        description: 'تم تحديث رابط الكتاب: "$title"',
        metadata: {
          'bookId': docId,
          'oldUrl': currentUrl,
          'newUrl': result,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم تحديث الرابط بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    }
  }

  Widget _bookPlaceholder() {
    return Container(
      width: 55,
      height: 75,
      decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.book, color: Colors.orange, size: 28),
    );
  }

  Widget _stat(IconData icon, String val) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        Text(val,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _metaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
