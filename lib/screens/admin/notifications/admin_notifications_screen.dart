import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('مركز الإشعارات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: Colors.purpleAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'إرسال إشعار'),
            Tab(text: 'السجل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SendNotificationTab(),
          _NotificationLogTab(),
        ],
      ),
    );
  }
}

class _SendNotificationTab extends StatefulWidget {
  const _SendNotificationTab();

  @override
  State<_SendNotificationTab> createState() => _SendNotificationTabState();
}

class _SendNotificationTabState extends State<_SendNotificationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _uidCtrl = TextEditingController();
  String _sendType = 'all'; // all, uid, topic
  String _selectedTopic = 'all';
  String _notifType = 'general';
  bool _isSending = false;

  final _topics = ['all', 'students', 'teachers', 'bac', 'bem'];
  final _topicLabels = {
    'all': 'جميع المستخدمين',
    'students': 'الطلاب',
    'teachers': 'المعلمون',
    'bac': 'طلاب البكالوريا',
    'bem': 'طلاب البيام',
  };
  final _notifTypes = ['general', 'update', 'reminder', 'system', 'result'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _uidCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final params = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'dataPayload': {'type': _notifType},
      };
      if (_sendType == 'uid') {
        params['uid'] = _uidCtrl.text.trim();
      } else {
        params['topic'] = _selectedTopic;
      }

      await FirebaseFunctions.instance
          .httpsCallable('sendAdminNotification')
          .call(params);

      // Log to Firestore
      await FirebaseFirestore.instance.collection('notification_logs').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _notifType,
        'target': _sendType == 'uid' ? _uidCtrl.text.trim() : _selectedTopic,
        'sendType': _sendType,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ تم إرسال الإشعار بنجاح'),
          backgroundColor: Colors.green,
        ));
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _uidCtrl.clear();
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ: ${e.message}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Send Type
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: RadioGroup<String>(
                groupValue: _sendType,
                onChanged: (v) => setState(() => _sendType = v as String),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('إشعار عام (للجميع أو لفئة)',
                          style: TextStyle(color: Colors.white)),
                      value: 'all',
                      activeColor: Colors.purpleAccent,
                    ),
                    RadioListTile<String>(
                      title: const Text('إشعار فردي (بـ UID)',
                          style: TextStyle(color: Colors.white)),
                      value: 'uid',
                      activeColor: Colors.purpleAccent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_sendType == 'all') ...[
              const Text('الفئة المستهدفة',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _topics
                    .map((t) => ChoiceChip(
                          label: Text(_topicLabels[t]!),
                          selected: _selectedTopic == t,
                          selectedColor: Colors.purple.withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: _selectedTopic == t
                                ? Colors.purpleAccent
                                : Colors.grey,
                          ),
                          backgroundColor: const Color(0xFF2C2C2C),
                          onSelected: (_) =>
                              setState(() => _selectedTopic = t),
                        ))
                    .toList(),
              ),
            ] else ...[
              TextFormField(
                controller: _uidCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('UID المستخدم', Icons.person),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'أدخل UID صالح' : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('عنوان الإشعار', Icons.title),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'العنوان مطلوب'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('نص الإشعار', Icons.message),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'النص مطلوب' : null,
            ),
            const SizedBox(height: 12),
            const Text('نوع الإشعار',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _notifTypes
                  .map((t) => ChoiceChip(
                        label: Text(t),
                        selected: _notifType == t,
                        selectedColor: Colors.purple.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: _notifType == t
                              ? Colors.purpleAccent
                              : Colors.grey,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(0xFF2C2C2C),
                        onSelected: (_) => setState(() => _notifType = t),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'جارٍ الإرسال...' : 'إرسال الإشعار',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _isSending ? null : _send,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purpleAccent)),
    );
  }
}

class _NotificationLogTab extends StatelessWidget {
  const _NotificationLogTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notification_logs')
          .orderBy('sentAt', descending: true)
          .limit(50)
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
              child: Text('لا توجد إشعارات مرسلة',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final sentAt = d['sentAt'] as Timestamp?;
            return Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2C1A4D),
                  child: Icon(Icons.notifications, color: Colors.purpleAccent),
                ),
                title: Text(d['title'] ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['body'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey)),
                    Text(
                        '${d['sendType'] == 'uid' ? 'فردي' : 'عام'} · ${d['target'] ?? ''} · ${sentAt != null ? sentAt.toDate().toString().split('.')[0] : ''}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ],
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(d['status'] ?? 'sent',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 11)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
