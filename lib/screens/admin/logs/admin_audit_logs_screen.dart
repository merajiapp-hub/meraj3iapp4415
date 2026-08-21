import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  String _formatAction(String action) {
    const map = {
      'SUSPEND_USER': 'تعليق حساب',
      'REACTIVATE_USER': 'إعادة تفعيل حساب',
      'DELETE_USER': 'حذف حساب',
      'FORCE_PASSWORD_CHANGE': 'إجبار تغيير كلمة المرور',
      'SEND_NOTIFICATION': 'إرسال إشعار',
      'UPDATE_USER': 'تعديل مستخدم',
    };
    return map[action] ?? action;
  }

  Color _actionColor(String action) {
    if (action.contains('DELETE')) return Colors.red;
    if (action.contains('SUSPEND')) return Colors.orange;
    if (action.contains('REACTIVATE')) return Colors.green;
    if (action.contains('NOTIFICATION')) return Colors.purple;
    return Colors.blue;
  }

  IconData _actionIcon(String action) {
    if (action.contains('DELETE')) return Icons.delete;
    if (action.contains('SUSPEND')) return Icons.block;
    if (action.contains('REACTIVATE')) return Icons.check_circle;
    if (action.contains('NOTIFICATION')) return Icons.notifications;
    if (action.contains('PASSWORD')) return Icons.lock_reset;
    return Icons.admin_panel_settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('سجل نشاط الإدارة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('audit_logs')
            .orderBy('timestamp', descending: true)
            .limit(100)
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
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list_alt, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد سجلات إدارية حتى الآن',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final action = d['action'] as String? ?? '';
              final timestamp = d['timestamp'] as Timestamp?;
              final adminName = d['adminName'] ?? 'مدير';
              final targetUid = d['targetUid'] ?? '';
              final color = _actionColor(action);

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(_actionIcon(action), color: color, size: 20),
                  ),
                  title: Text(
                    _formatAction(action),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بواسطة: $adminName',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      if (targetUid.isNotEmpty)
                        Text(
                            'المستخدم المتأثر: ${targetUid.length > 12 ? '${targetUid.substring(0, 12)}...' : targetUid}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      if (timestamp != null)
                        Text(
                            timestamp.toDate().toString().split('.')[0],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  trailing: Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
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
