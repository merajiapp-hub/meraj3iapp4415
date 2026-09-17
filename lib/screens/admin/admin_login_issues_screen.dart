import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'users/admin_user_detail_screen.dart';

class AdminLoginIssuesScreen extends StatelessWidget {
  const AdminLoginIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('مشاكل تسجيل الدخول'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('needsSupport', isEqualTo: true)
            .orderBy('lastLoginFailureAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'تعذر تحميل الحالات: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد حالات تحتاج إلى مساعدة حاليًا.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final name = (data['name'] ?? data['fullName'] ?? 'بدون اسم').toString();
              final reason = (data['lastLoginFailureReason'] ?? 'غير متوفر').toString();
              final attempts = data['failedLoginAttempts'] ?? 0;
              return Card(
                color: const Color(0xFF1E293B),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x33F59E0B),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('المحاولات: $attempts\nالسبب الأخير: $reason'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailScreen(uid: doc.id, userData: data),
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
