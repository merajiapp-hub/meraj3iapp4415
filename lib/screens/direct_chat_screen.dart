import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _sending = false;
  String _uid = '';
  String _userName = 'مستخدم';
  String _chatId = '';
  final Set<String> _seenMessageIds = <String>{};
  bool _messageStreamInitialized = false;
  bool _chatClosed = false;

  @override
  void initState() {
    super.initState();
    // defer until first frame so context/provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _uid = auth.user?.uid ?? '';
        _userName = auth.user?.displayName ?? auth.user?.email ?? 'مستخدم';
        _chatId = 'chat_$_uid';
      });
      if (_uid.isNotEmpty) {
        await _db.collection('chats').doc(_chatId).set({
          'userId': _uid,
          'userName': _userName,
          'status': 'open',
          'userUnread': 0,
          'adminUnread': 0,
        }, SetOptions(merge: true));
        await _db.collection('chats').doc(_chatId).update({'userUnread': 0});
        _db.collection('chats').doc(_chatId).snapshots().listen((snapshot) {
          if (!mounted) return;
          setState(() => _chatClosed = snapshot.data()?['status'] == 'closed');
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_uid.isEmpty || _chatClosed) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _db.collection('chats').doc(_chatId).collection('messages').add({
        'text': text,
        'senderId': _uid,
        'senderName': _userName,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      // Update chat metadata
      await _db.collection('chats').doc(_chatId).set({
        'userId': _uid,
        'userName': _userName,
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userUnread': 0,
        'adminUnread': FieldValue.increment(1),
      }, SetOptions(merge: true));
      _ctrl.clear();
      // Scroll to bottom after messages update
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإرسال: $e', style: GoogleFonts.tajawal()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show login required if not authenticated
    if (_uid.isEmpty) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isGuest || auth.user == null) {
        return Scaffold(
          appBar: AppBar(title: Text('الدعم الفني', style: GoogleFonts.tajawal())),
          body: Center(
            child: Text(
              'يجب تسجيل الدخول للوصول إلى الدعم الفني',
              style: GoogleFonts.tajawal(),
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'الدعم الفني',
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryColor,
                fontSize: 17,
              ),
            ),
            Text(
              'فريق MERAJ3I',
              style: GoogleFonts.tajawal(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Welcome Banner
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withValues(alpha: 0.12), AppTheme.primaryColor.withValues(alpha: 0.04)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مرحباً! كيف يمكننا مساعدتك اليوم؟',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(includeMetadataChanges: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                _playIncomingSound(docs);
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'ابدأ محادثة مع فريق الدعم',
                          style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index].data() as Map<String, dynamic>;
                    final isMe = !(d['isAdmin'] as bool? ?? false);
                    return GestureDetector(
                      onLongPress: isMe ? () => _deleteOwnMessage(docs[index].id) : null,
                      child: _buildBubble(d, isMe, isDark),
                    );
                  },
                );
              },
            ),
          ),
          // Input
          if (_chatClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Text('تم إغلاق هذه المحادثة من الدعم الفني.', textAlign: TextAlign.center, style: GoogleFonts.tajawal(color: isDark ? Colors.white70 : Colors.black54)),
            )
          else
            _buildInputBar(isDark),
        ],
      ),
    );
  }

  Future<void> _deleteOwnMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('هل تريد حذف هذه الرسالة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.collection('chats').doc(_chatId).collection('messages').doc(messageId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': _uid,
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف الرسالة')));
    }
  }

  void _playIncomingSound(List<QueryDocumentSnapshot> docs) {
    final hasNewIncoming = docs.any((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isAdmin'] == true && !_seenMessageIds.contains(doc.id);
    });
    _seenMessageIds.addAll(docs.map((doc) => doc.id));
    final shouldPlay = _messageStreamInitialized && hasNewIncoming;
    _messageStreamInitialized = true;
    if (shouldPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      });
    }
  }

  Widget _buildBubble(Map<String, dynamic> d, bool isMe, bool isDark) {
    final text = d['text'] as String? ?? '';
    final isDeleted = d['isDeleted'] == true;
    final time = d['createdAt'] as Timestamp?;
    final timeStr = time != null
        ? '${time.toDate().hour.toString().padLeft(2, '0')}:${time.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: const Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isDeleted)
                    Text('تم حذف هذه الرسالة', style: GoogleFonts.tajawal(fontStyle: FontStyle.italic, color: isMe ? Colors.white70 : Colors.grey))
                  else if (text.isNotEmpty)
                    Text(text, textDirection: TextDirection.rtl, style: GoogleFonts.tajawal(fontSize: 14, height: 1.4, color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)))),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: GoogleFonts.tajawal(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: GoogleFonts.tajawal(fontSize: 14),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : () => _sendMessage(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _sending ? Colors.grey : AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _sending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
