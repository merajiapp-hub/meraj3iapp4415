import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> userData;

  const AdminUserDetailScreen(
      {super.key, required this.uid, required this.userData});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _data = Map.from(widget.userData);
  }

  Future<void> _refresh() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    if (doc.exists && mounted) setState(() => _data = doc.data()!);
  }

  Future<void> _callFunction(String name, Map<String, dynamic> params,
      String successMsg) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFunctions.instance.httpsCallable(name).call(params);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(
                content: Text(successMsg),
                backgroundColor: Colors.green));
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ: ${e.message}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmAction(
      String title, String body, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('تأكيد',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = _data['isSuspended'] == true;
    final name = _data['name'] ?? 'بدون اسم';
    final email = _data['email'] ?? '';
    final phone = _data['phone'] ?? '';
    final photoUrl = _data['profileImageUrl'];
    final createdAt = _data['createdAt'];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('تفاصيل المستخدم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Profile Card ---
                  Card(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            backgroundColor: Colors.teal.withValues(alpha: 0.3),
                            child: photoUrl == null
                                ? Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.tealAccent,
                                        fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: isSuspended
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              isSuspended ? '🔴 موقوف' : '🟢 نشط',
                              style: TextStyle(
                                  color: isSuspended
                                      ? Colors.red
                                      : Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- Info ---
                  _infoCard('معلومات الحساب', [
                    _infoRow(Icons.email, 'البريد', email),
                    _infoRow(Icons.phone, 'الهاتف', phone.isNotEmpty ? phone : 'غير محدد'),
                    _infoRow(Icons.fingerprint, 'UID', widget.uid),
                    _infoRow(Icons.calendar_today, 'تاريخ الإنشاء',
                        createdAt != null
                            ? (createdAt as Timestamp)
                                .toDate()
                                .toString()
                                .split('.')[0]
                            : 'غير محدد'),
                  ]),
                  const SizedBox(height: 16),
                  // --- Actions ---
                  _sectionTitle('إجراءات إدارية'),
                  const SizedBox(height: 8),
                  if (!isSuspended)
                    _adminActionButton(
                      icon: Icons.block,
                      label: 'تعليق الحساب',
                      color: Colors.orange,
                      onTap: () => _confirmAction(
                        'تعليق الحساب',
                        'هل أنت متأكد من تعليق حساب $name؟',
                        () => _callFunction(
                            'suspendUser',
                            {'uid': widget.uid},
                            'تم تعليق الحساب بنجاح'),
                      ),
                    )
                  else
                    _adminActionButton(
                      icon: Icons.check_circle,
                      label: 'إعادة تفعيل الحساب',
                      color: Colors.green,
                      onTap: () => _confirmAction(
                        'إعادة التفعيل',
                        'هل تريد إعادة تفعيل حساب $name؟',
                        () => _callFunction(
                            'reactivateUser',
                            {'uid': widget.uid},
                            'تم تفعيل الحساب بنجاح'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: Icons.lock_reset,
                    label: 'إجبار تغيير كلمة المرور',
                    color: Colors.blueAccent,
                    onTap: () => _confirmAction(
                      'إجبار تغيير كلمة المرور',
                      'سيُطلب من $name تغيير كلمة مروره عند تسجيل الدخول التالي.',
                      () => _callFunction(
                          'requirePasswordChange',
                          {'uid': widget.uid},
                          'تم تفعيل إجبار تغيير كلمة المرور'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _adminActionButton(
                    icon: Icons.delete_forever,
                    label: 'حذف الحساب نهائياً',
                    color: Colors.red,
                    onTap: () => _confirmAction(
                      '⚠️ حذف الحساب',
                      'هذا الإجراء غير قابل للتراجع.\nهل أنت متأكد تماماً من حذف حساب $name؟',
                      () => _callFunction(
                          'deleteUserAdmin',
                          {'uid': widget.uid},
                          'تم حذف الحساب').then((_) {
                        if (context.mounted) Navigator.pop(context);
                      }),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const Divider(color: Color(0xFF2C2C2C)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _adminActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
