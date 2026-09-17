import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/curved_header.dart';

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
  bool _chatReady = false;
  final Set<String> _seenMessageIds = <String>{};
  bool _messageStreamInitialized = false;
  bool _chatClosed = false;

  // Selection state
  final Set<String> _selectedMessageIds = <String>{};
  final Set<String> _ownMessageIds = <String>{};
  Timer? _selectionTimer;
  String? _longPressTargetId;
  bool get _selectionMode => _selectedMessageIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChat());
  }

  Future<void> _initializeChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    var attempts = 0;
    while (mounted && !auth.initialized && attempts < 80) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (!mounted) return;

    final user = auth.user ?? FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _uid = user.uid;
      _userName = user.displayName ?? user.email ?? 'مستخدم';
      _chatId = 'chat_${user.uid}';
    });

    try {
      await _ensureChatReady();
    } catch (error) {
      debugPrint('[Chat] Failed to initialize conversation: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر فتح المحادثة. تحقق من تسجيل الدخول وحاول مرة أخرى.',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _selectionTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ─── Long-press: 3 second timer to enter selection mode ───────────────
  void _startLongPress(String messageId) {
    _longPressTargetId = messageId;
    _selectionTimer?.cancel();
    _selectionTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _longPressTargetId != messageId) return;
      setState(() => _selectedMessageIds.add(messageId));
      _triggerHaptic();
    });
  }

  void _cancelLongPress() {
    _selectionTimer?.cancel();
    _longPressTargetId = null;
  }

  void _triggerHaptic() {
    // Visual feedback - no external package needed
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearMessageSelection() => setState(_selectedMessageIds.clear);

  void _selectAllOwnMessages() {
    setState(() {
      _selectedMessageIds
        ..clear()
        ..addAll(_ownMessageIds);
    });
  }

  bool get _allOwnSelected =>
      _ownMessageIds.isNotEmpty &&
      _ownMessageIds.every(_selectedMessageIds.contains);

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('حذف الرسائل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف الرسائل المحددة؟',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'سيتم حذف ${_selectedMessageIds.length} رسالة محددة.',
              style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ids = List<String>.from(_selectedMessageIds);
    try {
      for (var start = 0; start < ids.length; start += 450) {
        final batch = _db.batch();
        for (final id in ids.skip(start).take(450)) {
          batch.update(
            _db.collection('chats').doc(_chatId).collection('messages').doc(id),
            {
              'isDeleted': true,
              'deletedAt': FieldValue.serverTimestamp(),
              'deletedBy': _uid,
            },
          );
        }
        await batch.commit();
      }
      if (mounted) {
        _clearMessageSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الرسائل بنجاح', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حذف الرسائل، حاول مرة أخرى', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_uid.isEmpty) {
      await _initializeChat();
      if (_uid.isEmpty) return;
    }
    if (_chatClosed) return;
    if (!_chatReady) {
      await _ensureChatReady();
      if (!_chatReady || _chatClosed) return;
    }
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
      await _db.collection('chats').doc(_chatId).set({
        'lastMessage': text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userUnread': 0,
        'adminUnread': FieldValue.increment(1),
      }, SetOptions(merge: true));
      _ctrl.clear();
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر إرسال الرسالة (${e.code}). أعد المحاولة.',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إرسال الرسالة: $e', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _ensureChatReady() async {
    final chatRef = _db.collection('chats').doc(_chatId);
    final chat = await chatRef.get();
    if (!chat.exists) {
      await chatRef.set({
        'userId': _uid,
        'userName': _userName,
        'status': 'open',
        'userUnread': 0,
        'adminUnread': 0,
      });
    } else if (chat.data()?['userId'] == _uid) {
      await chatRef.update({'userUnread': 0});
    } else {
      throw StateError('لا يمكن الوصول إلى محادثة دعم مرتبطة بمستخدم آخر');
    }
    if (!mounted) return;
    setState(() {
      _chatClosed = chat.data()?['status'] == 'closed';
      _chatReady = true;
    });
    chatRef.snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() => _chatClosed = snapshot.data()?['status'] == 'closed');
    });
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
      // Play sound if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_uid.isEmpty) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isGuest || auth.user == null) {
        return Scaffold(
          body: Column(
            children: [
              const CurvedHeader(
                title: 'الدعم الفني',
                subtitle: 'فريق MERAJ3I',
                gradient: AppTheme.brandGradient,
                leadingIcon: Icons.support_agent_rounded,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'يجب تسجيل الدخول للوصول إلى الدعم الفني',
                    style: GoogleFonts.tajawal(),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      // KEY FIX: resizeToAvoidBottomInset = true (default) ensures scaffold
      // automatically shrinks body when keyboard appears, keeping input at bottom
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          CurvedHeader(
            title: _selectionMode
                ? '${_selectedMessageIds.length} محددة'
                : 'الدعم الفني',
            subtitle: 'فريق MERAJ3I',
            gradient: isDark ? AppTheme.deepBlueGradient : AppTheme.brandGradient,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
          children: [
            // Welcome Banner - only show when not in selection mode
            if (!_selectionMode)
              _buildWelcomeBanner(isDark),

            // Selection action bar
            if (_selectionMode)
              _buildSelectionBar(isDark),

            // Messages list - takes remaining space
            Expanded(child: _buildMessagesList(isDark)),

            // Input area - stays at bottom above keyboard
            if (_chatClosed)
              _buildClosedBanner(isDark)
            else
              _buildInputBar(isDark),
          ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.12),
            AppTheme.primaryColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor, size: 22),
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
    );
  }

  Widget _buildSelectionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEBF3FF),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '${_selectedMessageIds.length} رسالة محددة',
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _allOwnSelected ? _clearMessageSelection : _selectAllOwnMessages,
            child: Text(
              _allOwnSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل',
              style: GoogleFonts.tajawal(fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _deleteSelectedMessages,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: Text('حذف', style: GoogleFonts.tajawal(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    if (_chatId.isEmpty) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
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

        // Update own message IDs for selection
        _ownMessageIds
          ..clear()
          ..addAll(docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isAdmin'] != true && data['isDeleted'] != true;
          }).map((doc) => doc.id));

        _playIncomingSound(docs);

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 72,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'ابدأ محادثة مع فريق الدعم',
                  style: GoogleFonts.tajawal(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'نحن هنا لمساعدتك في أي وقت',
                  style: GoogleFonts.tajawal(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        // Auto-scroll to bottom on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final d = docs[index].data() as Map<String, dynamic>;
            final isMe = !(d['isAdmin'] as bool? ?? false);
            final canSelect = isMe && d['isDeleted'] != true;
            final selected = _selectedMessageIds.contains(docs[index].id);
            final messageId = docs[index].id;

            return GestureDetector(
              // In selection mode: tap to toggle, else do nothing
              onTap: _selectionMode && canSelect
                  ? () => _toggleMessageSelection(messageId)
                  : null,
              // Long press starts 3-second timer
              onLongPressStart: canSelect ? (_) => _startLongPress(messageId) : null,
              onLongPressEnd: canSelect ? (_) => _cancelLongPress() : null,
              onLongPressCancel: canSelect ? _cancelLongPress : null,
              child: _buildBubble(d, messageId, isMe, isDark, selected: selected),
            );
          },
        );
      },
    );
  }

  Widget _buildBubble(
    Map<String, dynamic> d,
    String messageId,
    bool isMe,
    bool isDark, {
    bool selected = false,
  }) {
    final text = d['text'] as String? ?? '';
    final isDeleted = d['isDeleted'] == true;
    final time = d['createdAt'] as Timestamp?;
    final timeStr = time != null
        ? '${time.toDate().hour.toString().padLeft(2, '0')}:${time.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: const Icon(Icons.support_agent_rounded, size: 14, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 6),
          ],
          // Checkbox for selection mode (own messages only)
          if (_selectionMode && isMe && !isDeleted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Checkbox(
                value: selected,
                onChanged: (_) => _toggleMessageSelection(messageId),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe && !isDeleted
                    ? LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isDeleted
                    ? Colors.grey.withValues(alpha: 0.2)
                    : isMe
                        ? null
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: selected
                    ? Border.all(color: AppTheme.primaryColor, width: 2.5)
                    : null,
                boxShadow: isDeleted
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isDeleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'تم حذف هذه الرسالة',
                          style: GoogleFonts.tajawal(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else if (text.isNotEmpty)
                    Text(
                      text,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        height: 1.4,
                        color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                  if (!isDeleted) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: isMe ? Colors.white70 : Colors.grey[500],
                      ),
                    ),
                  ],
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
    // NOTE: No manual viewInsets.bottom - Scaffold handles keyboard resize automatically
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              textDirection: TextDirection.rtl,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
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
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
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

  Widget _buildClosedBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Text(
        'تم إغلاق هذه المحادثة من الدعم الفني.',
        textAlign: TextAlign.center,
        style: GoogleFonts.tajawal(color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}
