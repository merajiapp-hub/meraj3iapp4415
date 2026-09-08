import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersListScreen extends StatefulWidget {
  const AdminUsersListScreen({super.key});

  @override
  State<AdminUsersListScreen> createState() => _AdminUsersListScreenState();
}

enum UserFilter { all, active, inactive, admins, suspended }

class _AdminUsersListScreenState extends State<AdminUsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserFilter _filter = UserFilter.all;
  String _searchQuery = '';
  static const int _limit = 100;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('users');
    switch (_filter) {
      case UserFilter.active:
        return q.where('isSuspended', isEqualTo: false).limit(_limit).snapshots();
      case UserFilter.inactive:
        return q.where('lastActivity', isLessThan: DateTime.now().subtract(const Duration(days: 30)))
                .orderBy('lastActivity', descending: true).limit(_limit).snapshots();
      case UserFilter.admins:
        return q.where('isAdmin', isEqualTo: true).limit(_limit).snapshots();
      case UserFilter.suspended:
        return q.where('isSuspended', isEqualTo: true).limit(_limit).snapshots();
      case UserFilter.all:
        return q.orderBy('createdAt', descending: true).limit(_limit).snapshots();
    }
  }

  List<QueryDocumentSnapshot> _filterAndSortResults(List<QueryDocumentSnapshot> docs) {
    // ترتيب محلي حسب تاريخ الإنشاء إذا لم يكن الاستعلام مرتباً مسبقاً من Firestore لتجنب أخطاء الفهرس
    if (_filter != UserFilter.all && _filter != UserFilter.inactive) {
      docs.sort((a, b) {
        final ad = a.data() as Map<String, dynamic>;
        final bd = b.data() as Map<String, dynamic>;
        final aTime = (ad['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        final bTime = (bd['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });
    }

    if (_searchQuery.isEmpty) return docs;
    final q = _searchQuery.toLowerCase();
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
        return (d['name'] ?? d['fullName'] ?? '').toString().toLowerCase().contains(q) ||
          (d['email'] ?? '').toString().toLowerCase().contains(q) ||
          (d['phone'] ?? '').toString().toLowerCase().contains(q) ||
          (d['authProvider'] ?? d['provider'] ?? '').toString().toLowerCase().contains(q) ||
          doc.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('إدارة المستخدمين',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'بحث باسم، بريد، UID، هاتف...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            })
                        : null,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: UserFilter.values.map((f) {
                    final labels = {
                      UserFilter.all: 'الكل',
                      UserFilter.active: 'النشطون',
                      UserFilter.inactive: 'غير النشطين',
                      UserFilter.admins: 'المدراء',
                      UserFilter.suspended: 'موقوفون',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text(labels[f]!),
                        selected: _filter == f,
                        selectedColor: Colors.tealAccent.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: _filter == f ? Colors.tealAccent : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: const Color(0xFF2C2C2C),
                        onSelected: (_) {
                          setState(() => _filter = f);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _buildStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final filtered = _filterAndSortResults(docs);

          if (filtered.isEmpty) {
            return const Center(
              child: Text('لا يوجد مستخدمون مطابقون',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final doc = filtered[i];
              final d = doc.data() as Map<String, dynamic>;
              return _UserTile(
                uid: doc.id,
                data: d,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserDetailScreen(
                      uid: doc.id,
                      userData: d,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _UserTile({required this.uid, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSuspended = data['isSuspended'] == true;
    final name = data['name'] ?? data['fullName'] ?? 'بدون اسم';
    final email = data['email'] ?? '';
    final photoUrl = data['profileImageUrl'] ?? data['photoUrl'];

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          backgroundColor: Colors.teal.withValues(alpha: 0.3),
          child: photoUrl == null
              ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: uid));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ معرف المستخدم (UID) بنجاح'),
                    backgroundColor: Colors.teal,
                  ),
                );
              },
            ),
            if (isSuspended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: const Text('موقوف',
                    style: TextStyle(color: Colors.red, fontSize: 11)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('UID: ${uid.substring(0, uid.length < 10 ? uid.length : 10)}${uid.length > 10 ? '...' : ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
