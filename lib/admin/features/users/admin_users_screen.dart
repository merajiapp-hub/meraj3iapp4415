import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/admin_colors.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة المستخدمين',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textDark,
                    ),
                  ),
                  Text(
                    'عرض وتعديل والتحكم في حسابات المستخدمين',
                    style: GoogleFonts.tajawal(
                      color: AdminColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: Text('مستخدم جديد', style: GoogleFonts.tajawal()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // ── Search & Filters ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'البحث عن مستخدم (الاسم، البريد)...',
                    hintStyle: GoogleFonts.tajawal(color: AdminColors.textLight),
                    prefixIcon: const Icon(Icons.search, color: AdminColors.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: GoogleFonts.tajawal(),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  initialValue: 'all',
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('جميع المستخدمين', style: GoogleFonts.tajawal())),
                    DropdownMenuItem(value: 'active', child: Text('نشط', style: GoogleFonts.tajawal())),
                    DropdownMenuItem(value: 'blocked', child: Text('محظور', style: GoogleFonts.tajawal())),
                  ],
                  onChanged: (val) {},
                ),
              ),
            ],
          ),
        ),

        // ── Users Table ───────────────────────────────────────────────────
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: StreamBuilder<QuerySnapshot>(
              // Fetch latest 50 users. Note: Full pagination needs a more complex setup.
              stream: _firestore
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'خطأ أثناء تحميل المستخدمين',
                      style: GoogleFonts.tajawal(color: AdminColors.error),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                
                // Client-side search filtering (since Firestore doesn't support generic string search easily)
                final filteredDocs = docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  return name.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'لم يتم العثور على أي مستخدمين',
                      style: GoogleFonts.tajawal(color: AdminColors.textLight),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey.shade50),
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 60,
                      columns: [
                        DataColumn(label: Text('المستخدم', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('البريد الإلكتروني', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('تاريخ التسجيل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('النوع', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الحالة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('الإجراءات', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildDataRow(doc.id, data);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  DataRow _buildDataRow(String docId, Map<String, dynamic> data) {
    final name = data['name'] as String? ?? 'بدون اسم';
    final email = data['email'] as String? ?? 'لا يوجد';
    final ts = data['createdAt'];
    final time = ts is Timestamp ? _formatDate(ts.toDate()) : '—';
    final isGuest = data['isGuest'] as bool? ?? false;
    final isBlocked = data['isBlocked'] as bool? ?? false; // Assume we have a blocked field

    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AdminColors.primaryLight,
                radius: 16,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AdminColors.primaryDark, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(name, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        DataCell(Text(email, style: GoogleFonts.tajawal())),
        DataCell(Text(time, style: GoogleFonts.tajawal())),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isGuest ? Colors.grey.shade100 : AdminColors.primaryLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isGuest ? 'زائر' : 'مسجل',
              style: GoogleFonts.tajawal(
                color: isGuest ? Colors.grey.shade700 : AdminColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isBlocked ? AdminColors.error.withValues(alpha: 0.1) : AdminColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isBlocked ? 'محظور' : 'نشط',
              style: GoogleFonts.tajawal(
                color: isBlocked ? AdminColors.error : AdminColors.success,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AdminColors.info, size: 20),
                onPressed: () {},
                tooltip: 'تعديل',
              ),
              IconButton(
                icon: Icon(
                  isBlocked ? Icons.lock_open : Icons.block,
                  color: isBlocked ? AdminColors.success : AdminColors.warning,
                  size: 20,
                ),
                onPressed: () {},
                tooltip: isBlocked ? 'إلغاء الحظر' : 'حظر',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AdminColors.error, size: 20),
                onPressed: () {},
                tooltip: 'حذف',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
