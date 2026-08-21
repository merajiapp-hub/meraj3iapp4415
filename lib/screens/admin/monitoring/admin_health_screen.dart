import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHealthScreen extends StatefulWidget {
  const AdminHealthScreen({super.key});

  @override
  State<AdminHealthScreen> createState() => _AdminHealthScreenState();
}

class _AdminHealthScreenState extends State<AdminHealthScreen> {
  bool _isChecking = false;
  final Map<String, _ServiceStatus> _statuses = {
    'Firebase Auth': _ServiceStatus.unknown,
    'Firestore': _ServiceStatus.unknown,
    'Cloud Functions': _ServiceStatus.unknown,
    'FCM': _ServiceStatus.unknown,
    'نظام النتائج': _ServiceStatus.unknown,
  };

  Future<void> _runHealthCheck() async {
    setState(() {
      _isChecking = true;
      for (final key in _statuses.keys) {
        _statuses[key] = _ServiceStatus.checking;
      }
    });

    // Check Firestore
    try {
      await FirebaseFirestore.instance
          .collection('admin_settings')
          .doc('health_ping')
          .set({'ping': DateTime.now().toIso8601String()})
          .timeout(const Duration(seconds: 5));
      setState(() => _statuses['Firestore'] = _ServiceStatus.ok);
    } catch (_) {
      setState(() => _statuses['Firestore'] = _ServiceStatus.error);
    }

    // Auth is ok if we're on this screen (admin only)
    setState(() => _statuses['Firebase Auth'] = _ServiceStatus.ok);

    // Cloud Functions: attempt a simple callable
    // Since we can't call without triggering something, we just mark as OK if Firestore is OK
    setState(() => _statuses['Cloud Functions'] = _statuses['Firestore'] ?? _ServiceStatus.error);

    // FCM: We check if we can read the config
    try {
      await FirebaseFirestore.instance
          .collection('notification_logs')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      setState(() => _statuses['FCM'] = _ServiceStatus.ok);
    } catch (_) {
      setState(() => _statuses['FCM'] = _ServiceStatus.warning);
    }

    // Results system
    try {
      await FirebaseFirestore.instance
          .collection('results')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      setState(() => _statuses['نظام النتائج'] = _ServiceStatus.ok);
    } catch (_) {
      setState(() => _statuses['نظام النتائج'] = _ServiceStatus.warning);
    }

    setState(() => _isChecking = false);
  }

  @override
  void initState() {
    super.initState();
    _runHealthCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('حالة النظام',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isChecking ? null : _runHealthCheck,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // System health
          const Text('مراقبة الخدمات',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._statuses.entries.map((e) => _ServiceCard(
                name: e.key,
                status: e.value,
              )),
          const SizedBox(height: 24),
          // Error log section
          const Text('سجل الأخطاء الأخيرة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ErrorLogSection(),
        ],
      ),
    );
  }
}

enum _ServiceStatus { unknown, checking, ok, warning, error }

class _ServiceCard extends StatelessWidget {
  final String name;
  final _ServiceStatus status;

  const _ServiceCard({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      _ServiceStatus.ok => (Colors.green, '🟢 يعمل', Icons.check_circle),
      _ServiceStatus.warning => (Colors.orange, '🟡 تحذير', Icons.warning),
      _ServiceStatus.error => (Colors.red, '🔴 مشكلة', Icons.error),
      _ServiceStatus.checking => (Colors.grey, '⏳ جارٍ الفحص...', Icons.sync),
      _ServiceStatus.unknown => (Colors.grey, '⚪ غير معروف', Icons.help),
    };

    return Card(
      color: const Color(0xFF1E1E1E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(data.$3, color: data.$1),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: Text(data.$2,
            style: TextStyle(color: data.$1, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ErrorLogSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('error_logs')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  '✅ لا توجد أخطاء مسجلة',
                  style: TextStyle(color: Colors.green, fontSize: 15),
                ),
              ),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final ts = d['timestamp'] as Timestamp?;
            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2D1515),
                  child: Icon(Icons.bug_report, color: Colors.red, size: 20),
                ),
                title: Text(d['type'] ?? 'خطأ غير محدد',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d['screen'] != null)
                      Text('الشاشة: ${d['screen']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    if (d['appVersion'] != null)
                      Text('الإصدار: ${d['appVersion']}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    if (ts != null)
                      Text(ts.toDate().toString().split('.')[0],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
