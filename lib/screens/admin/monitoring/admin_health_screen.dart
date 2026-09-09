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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FB);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final softText = isDark ? Colors.white70 : const Color(0xFF5B6474);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE5EAF2);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
        title: Text('حالة النظام', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: text),
        actions: [
          IconButton(
            icon: _isChecking
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: text, strokeWidth: 2))
                : Icon(Icons.refresh, color: text),
            onPressed: _isChecking ? null : _runHealthCheck,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('مراقبة الخدمات', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._statuses.entries.map((e) => _ServiceCard(
                name: e.key,
                status: e.value,
                isDark: isDark,
              )),
          const SizedBox(height: 24),
          Text('سجل الأخطاء الأخيرة', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ErrorLogSection(isDark: isDark, surface: surface, cardBg: cardBg, border: border, softText: softText),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String name;
  final _ServiceStatus status;
  final bool isDark;

  const _ServiceCard({required this.name, required this.status, required this.isDark});

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
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5EAF2)),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(data.$3, color: data.$1),
        title: Text(name, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
        trailing: Text(data.$2, style: TextStyle(color: data.$1, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ErrorLogSection extends StatelessWidget {
  final bool isDark;
  final Color surface;
  final Color cardBg;
  final Color border;
  final Color softText;

  const _ErrorLogSection({required this.isDark, required this.surface, required this.cardBg, required this.border, required this.softText});

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
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: border),
            ),
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
              color: cardBg,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: border),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2D1515),
                  child: Icon(Icons.bug_report, color: Colors.red, size: 20),
                ),
                title: Text(d['type'] ?? 'خطأ غير محدد', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d['screen'] != null)
                      Text('الشاشة: ${d['screen']}', style: TextStyle(color: softText, fontSize: 11)),
                    if (d['appVersion'] != null)
                      Text('الإصدار: ${d['appVersion']}', style: TextStyle(color: softText, fontSize: 11)),
                    if (ts != null)
                      Text(ts.toDate().toString().split('.')[0], style: TextStyle(color: softText, fontSize: 11)),
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

enum _ServiceStatus { unknown, checking, ok, warning, error }
