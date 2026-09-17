import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/admin_user_profile_service.dart';
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
  static const int _limit = 50;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('users');

    switch (_filter) {
      case UserFilter.active:
        return query.where('isSuspended', isEqualTo: false).limit(_limit).snapshots();
      case UserFilter.suspended:
        return query.where('isSuspended', isEqualTo: true).limit(_limit).snapshots();
      case UserFilter.admins:
        return query.where('isAdmin', isEqualTo: true).limit(_limit).snapshots();
      case UserFilter.inactive:
        return query
            .orderBy('lastActivity', descending: false)
            .limit(_limit)
            .snapshots();
      case UserFilter.all:
        return query.orderBy('createdAt', descending: true).limit(_limit).snapshots();
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterAndSortResults(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? docs
        : docs.where((doc) {
            final data = doc.data();
            final profile = AdminUserProfile.fromUidAndData(doc.id, data);
            final searchable = [
              profile.fullName,
              profile.email,
              profile.phone,
              profile.username,
              profile.provider,
              doc.id,
              data['provider'] ?? '',
              data['authProvider'] ?? '',
            ].join(' ').toLowerCase();

            return searchable.contains(query);
          }).toList();

    filtered.sort((a, b) {
      final da = a.data();
      final db = b.data();
      final ta = (da['createdAt'] as Timestamp?)?.seconds ?? 0;
      final tb = (db['createdAt'] as Timestamp?)?.seconds ?? 0;
      return tb.compareTo(ta);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'إدارة المستخدمين',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'بحث باسم، بريد، هاتف، UID...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: UserFilter.values.map((filter) {
                final labels = {
                  UserFilter.all: 'الكل',
                  UserFilter.active: 'النشطون',
                  UserFilter.inactive: 'غير النشطين',
                  UserFilter.admins: 'المدراء',
                  UserFilter.suspended: 'الموقوفون',
                };
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(labels[filter]!),
                    selected: _filter == filter,
                    selectedColor: Colors.tealAccent.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: _filter == filter ? Colors.tealAccent : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: const Color(0xFF2C2C2C),
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _buildStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = _filterAndSortResults(docs);

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا يوجد مستخدمون مطابقون',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();
                    final profile = AdminUserProfile.fromUidAndData(doc.id, data);
                    final isSuspended = data['isSuspended'] == true || data['accountStatus'] == 'suspended';
                    final needsSupport = data['needsSupport'] == true;

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminUserDetailScreen(
                              uid: doc.id,
                              userData: data,
                            ),
                          ),
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: profile.photoUrl.isNotEmpty ? NetworkImage(profile.photoUrl) : null,
                          backgroundColor: Colors.teal.withValues(alpha: 0.2),
                          child: profile.photoUrl.isEmpty
                              ? Text(
                                  profile.fullName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: doc.id));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم نسخ UID بنجاح')),
                                  );
                                }
                              },
                            ),
                            if (isSuspended)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'موقوف',
                                  style: TextStyle(color: Colors.red, fontSize: 11),
                                ),
                              ),
                            if (needsSupport)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.email,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.phone,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'UID: ${doc.id}',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
