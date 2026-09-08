import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// شاشة المسؤول — رؤية جميع المحادثات والرد على كل مستخدم
class AdminChatDashboardScreen extends StatefulWidget {
  const AdminChatDashboardScreen({super.key});

  @override
  State<AdminChatDashboardScreen> createState() => _AdminChatDashboardScreenState();
}

class _AdminChatDashboardScreenState extends State<AdminChatDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        title: Text(
          'صندوق الرسائل',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) => _chatDate(b).compareTo(_chatDate(a)));
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'لا توجد محادثات بعد',
                style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final chatId = docs[index].id;
              final userName = d['userName'] as String? ?? 'مستخدم';
              final lastMsg = d['lastMessage'] as String? ?? '';
              final adminUnread = (d['adminUnread'] as int?) ?? 0;
              final lastAt = d['lastMessageAt'] as Timestamp?;
              final timeStr = lastAt != null
                  ? intl.DateFormat('d/M HH:mm').format(lastAt.toDate())
                  : '';

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _AdminChatViewScreen(chatId: chatId, userName: userName),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: adminUnread > 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                        child: Center(child: Text(userName.isNotEmpty ? userName[0] : 'م', style: GoogleFonts.tajawal(color: const Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: GoogleFonts.tajawal(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.tajawal(color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.tajawal(color: Colors.grey[500], fontSize: 13),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                      if (adminUnread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$adminUnread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  DateTime _chatDate(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final value = data['updatedAt'] ?? data['lastMessageAt'];
    return value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _AdminChatViewScreen extends StatefulWidget {
  final String chatId;
  final String userName;

  const _AdminChatViewScreen({required this.chatId, required this.userName});

  @override
  State<_AdminChatViewScreen> createState() => _AdminChatViewScreenState();
}

class _AdminChatViewScreenState extends State<_AdminChatViewScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  final Set<String> _seenMessageIds = <String>{};
  bool _messageStreamInitialized = false;

  @override
  void initState() {
    super.initState();
    // Mark admin messages as read
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'adminUnread': 0});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendAdminReply() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final adminId = auth.user?.uid;
      if (adminId == null || !auth.isAdmin) {
        throw StateError('لا توجد صلاحية إدارية لإرسال الرد');
      }
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': adminId,
        'senderName': 'فريق MERAJ3I',
        'isAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userUnread': FieldValue.increment(1),
        'status': 'open',
      }, SetOptions(merge: true));
      _ctrl.clear();
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الرد: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleStatus() async {
    final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final isClosed = doc.data()?['status'] == 'closed';
    await doc.reference.update({
      'status': isClosed ? 'open' : 'closed',
      'closedAt': isClosed ? FieldValue.delete() : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) setState(() {});
  }

  Future<void> _assignToMe() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'assignedTo': uid, 'updatedAt': FieldValue.serverTimestamp()});
  }


  Future<void> _deleteMessage(String messageId) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف الرسالة'),
            content: const Text('سيتم إخفاء الرسالة مع الاحتفاظ بسجلها.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
            ],
          ),
        );
        if (confirm != true) return;
        if (!mounted) return;
        try {
          final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
          await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').doc(messageId).update({
            'isDeleted': true,
            'deletedAt': FieldValue.serverTimestamp(),
            'deletedBy': uid,
          });
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف الرسالة')));
        }
  }

  void _playIncomingSound(List<QueryDocumentSnapshot> docs) {
    final hasNewIncoming = docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isAdmin'] != true && !_seenMessageIds.contains(doc.id);
    });
    _seenMessageIds.addAll(docs.map((doc) => doc.id));
    final shouldPlay = _messageStreamInitialized && hasNewIncoming;
    _messageStreamInitialized = true;
    if (shouldPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.userName,
          style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(tooltip: 'تعيين لي', onPressed: _assignToMe, icon: const Icon(Icons.assignment_ind_rounded)),
          IconButton(tooltip: 'إغلاق أو إعادة فتح', onPressed: _toggleStatus, icon: const Icon(Icons.lock_open_rounded)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                _playIncomingSound(docs);
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    final isAdmin = d['isAdmin'] as bool? ?? false;
                    final text = d['text'] as String? ?? '';
                    final isDeleted = d['isDeleted'] == true;
                    final time = d['createdAt'] as Timestamp?;
                    final timeStr = time != null
                        ? '${time.toDate().hour.toString().padLeft(2, '0')}:${time.toDate().minute.toString().padLeft(2, '0')}'
                        : '';
                    return GestureDetector(
                      onLongPress: () => _deleteMessage(docs[index].id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                        mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFF0D9488),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                children: [
                                  if (isDeleted)
                                    const Text('تم حذف هذه الرسالة', style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic))
                                  else if (text.isNotEmpty)
                                    Text(text, textDirection: TextDirection.rtl, style: GoogleFonts.tajawal(color: Colors.white, fontSize: 14, height: 1.4)),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Reply Input
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب ردك...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _sendAdminReply,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9488),
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
