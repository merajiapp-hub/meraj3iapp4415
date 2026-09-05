import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBooksScreen extends StatefulWidget {
  const AdminBooksScreen({super.key});

  @override
  State<AdminBooksScreen> createState() => _AdminBooksScreenState();
}

class _AdminBooksScreenState extends State<AdminBooksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _deleteBook(String bookId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الكتاب؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('books').doc(bookId).delete();
        _showSnackBar('تم حذف الكتاب بنجاح');
      } catch (e) {
        _showSnackBar('خطأ أثناء الحذف: $e', isError: true);
      }
    }
  }

  void _toggleBookStatus(String bookId, bool currentStatus) async {
    try {
      await _firestore.collection('books').doc(bookId).update({
        'isActive': !currentStatus,
      });
      _showSnackBar(currentStatus ? 'تم تعطيل الكتاب' : 'تم تفعيل الكتاب');
    } catch (e) {
      _showSnackBar('خطأ: $e', isError: true);
    }
  }

  void _showAddEditBookDialog([DocumentSnapshot? book]) {
    final isEditing = book != null;
    final data = book?.data() as Map<String, dynamic>?;

    final titleController = TextEditingController(text: data?['title'] ?? '');
    final subjectController = TextEditingController(text: data?['subject'] ?? '');
    final stageController = TextEditingController(text: data?['stage'] ?? '');
    final pdfUrlController = TextEditingController(text: data?['pdfUrl'] ?? '');
    final coverUrlController = TextEditingController(text: data?['coverUrl'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'تعديل الكتاب' : 'إضافة كتاب جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'عنوان الكتاب'),
              ),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'المادة'),
              ),
              TextField(
                controller: stageController,
                decoration: const InputDecoration(labelText: 'المرحلة الدراسية'),
              ),
              TextField(
                controller: pdfUrlController,
                decoration: const InputDecoration(labelText: 'رابط ملف الـ PDF'),
              ),
              TextField(
                controller: coverUrlController,
                decoration: const InputDecoration(labelText: 'رابط صورة الغلاف'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                _showSnackBar('يرجى إدخال العنوان', isError: true);
                return;
              }

              final bookData = {
                'title': titleController.text,
                'subject': subjectController.text,
                'stage': stageController.text,
                'pdfUrl': pdfUrlController.text,
                'coverUrl': coverUrlController.text,
                'isActive': data?['isActive'] ?? true,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              try {
                if (isEditing) {
                  await _firestore.collection('books').doc(book.id).update(bookData);
                  _showSnackBar('تم تعديل الكتاب بنجاح');
                } else {
                  bookData['createdAt'] = FieldValue.serverTimestamp();
                  await _firestore.collection('books').add(bookData);
                  _showSnackBar('تم إضافة الكتاب بنجاح');
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                _showSnackBar('خطأ: $e', isError: true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الكتب والمحتوى',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBookDialog(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة كتاب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('books').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(child: Text('لا توجد كتب مضافة حتى الآن'));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isActive = data['isActive'] ?? true;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                            image: data['coverUrl'] != null && data['coverUrl'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(data['coverUrl']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: data['coverUrl'] == null || data['coverUrl'].toString().isEmpty
                              ? const Icon(Icons.book, color: Colors.grey)
                              : null,
                        ),
                        title: Text(data['title'] ?? 'بدون عنوان', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${data['stage'] ?? 'بدون مرحلة'} - ${data['subject'] ?? 'بدون مادة'}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (val) => _toggleBookStatus(doc.id, isActive),
                              activeThumbColor: const Color(0xFF10B981),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditBookDialog(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteBook(doc.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
