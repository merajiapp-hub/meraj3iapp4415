import 'package:flutter/material.dart';
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
  DocumentSnapshot? _lastDoc;
  final List<QueryDocumentSnapshot> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('users');
    switch (_filter) {
      case UserFilter.active:
        q = q.where('isSuspended', isEqualTo: false);
        break;
      case UserFilter.inactive:
        q = q.where('lastActivity', isLessThan: DateTime.now()
            .subtract(const Duration(days: 30)));
        break;
      case UserFilter.admins:
        q = q.where('isAdmin', isEqualTo: true);
        break;
      case UserFilter.suspended:
        q = q.where('isSuspended', isEqualTo: true);
        break;
      case UserFilter.all:
        break;
    }
    return q.orderBy('createdAt', descending: true);
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      setState(() {
        _users.clear();
        _lastDoc = null;
        _hasMore = true;
      });
    }
    if (!_hasMore) return;
    setState(() => _isLoading = true);
    try {
      Query<Map<String, dynamic>> q = _buildQuery().limit(_pageSize);
      if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
      final snap = await q.get();
      if (snap.docs.length < _pageSize) _hasMore = false;
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;
      setState(() => _users.addAll(snap.docs));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في تحميل المستخدمين: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<QueryDocumentSnapshot> get _filtered {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return (d['name'] ?? '').toLowerCase().contains(q) ||
          (d['email'] ?? '').toLowerCase().contains(q) ||
          (d['phone'] ?? '').toLowerCase().contains(q) ||
          doc.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
                          _loadUsers(refresh: true);
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
      body: RefreshIndicator(
        onRefresh: () => _loadUsers(refresh: true),
        child: filtered.isEmpty && !_isLoading
            ? const Center(
                child: Text('لا يوجد مستخدمون',
                    style: TextStyle(color: Colors.grey, fontSize: 16)))
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                      _hasMore) {
                    _loadUsers();
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length + (_isLoading ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= filtered.length) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final doc = filtered[i];
                    final d = doc.data() as Map<String, dynamic>;
                    return _UserTile(
                      uid: doc.id,
                      data: d,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AdminUserDetailScreen(
                                  uid: doc.id, userData: d))),
                    );
                  },
                ),
              ),
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
    final name = data['name'] ?? 'بدون اسم';
    final email = data['email'] ?? '';
    final photoUrl = data['profileImageUrl'];

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
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
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
            Text('UID: ${uid.substring(0, 10)}...',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
