import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _toggleUserSuspension(String uid, bool currentStatus) async {
    final action = currentStatus ? 'إلغاء حظر' : 'حظر';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد $action'),
        content: Text('هل أنت متأكد من رغبتك في $action هذا المستخدم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: currentStatus ? Colors.green : Colors.red),
            child: Text(action, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'isSuspended': !currentStatus,
      });
      _showSnackBar('تم $action المستخدم بنجاح');
    } catch (e) {
      _showSnackBar('حدث خطأ: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    Query query = _firestore.collection('users').orderBy('createdAt', descending: true).limit(100);

    // Simple client-side filtering placeholder since complex queries require indexes
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة المستخدمين',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'البحث عن مستخدم (الاسم، البريد)...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
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
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('خطأ: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data?.docs ?? [];
                  
                  if (_searchQuery.isNotEmpty) {
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(child: Text('لا يوجد مستخدمون'));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isSuspended = data['isSuspended'] == true;
                      
                      DateTime? createdDate;
                      if (data['createdAt'] != null) {
                        createdDate = (data['createdAt'] as Timestamp).toDate();
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['profileImageUrl'] != null ? NetworkImage(data['profileImageUrl']) : null,
                          child: data['profileImageUrl'] == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(data['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['email'] ?? 'بدون بريد'),
                            Text(
                              createdDate != null ? 'تاريخ التسجيل: ${DateFormat('yyyy-MM-dd HH:mm').format(createdDate)}' : 'تاريخ غير معروف',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSuspended)
                              const Chip(
                                label: Text('محظور', style: TextStyle(color: Colors.white, fontSize: 10)),
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              tooltip: 'نسخ UID',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: doc.id));
                                _showSnackBar('تم نسخ UID');
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'suspend') {
                                  _toggleUserSuspension(doc.id, isSuspended);
                                } else if (value == 'delete') {
                                  // Implementation for deletion if needed (requires careful handling)
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'suspend',
                                  child: Text(isSuspended ? 'إلغاء الحظر' : 'حظر المستخدم'),
                                ),
                              ],
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
