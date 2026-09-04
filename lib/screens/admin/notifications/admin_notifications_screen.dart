import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import '../../../services/admin_activity_service.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterCategory = 'all';
  bool _unreadOnly = false;

  static const _bg = Color(0xFF0F172A);
  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF8B5CF6);

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
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _buildAppBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ActivityLogTab(
              filterCategory: _filterCategory,
              unreadOnly: _unreadOnly,
              onFilterChanged: (cat, unread) =>
                  setState(() { _filterCategory = cat; _unreadOnly = unread; }),
            ),
            const _SendNotificationTab(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'مركز الإشعارات',
        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      actions: [
        // عداد غير المقروءة
        StreamBuilder<int>(
          stream: AdminActivityService.unreadCountStream(),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(left: 12, top: 14, bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: GoogleFonts.outfit(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: _accent,
        labelColor: _accent,
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.dashboard_rounded), text: 'سجل النشاط'),
          Tab(icon: Icon(Icons.send_rounded), text: 'إرسال إشعار'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  تاب سجل النشاط
// ═══════════════════════════════════════════════════════════════
class _ActivityLogTab extends StatelessWidget {
  final String filterCategory;
  final bool unreadOnly;
  final void Function(String category, bool unread) onFilterChanged;

  const _ActivityLogTab({
    required this.filterCategory,
    required this.unreadOnly,
    required this.onFilterChanged,
  });

  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF8B5CF6);

  static const _categories = [
    ('all', 'الكل', Icons.all_inclusive_rounded),
    ('users', 'المستخدمون', Icons.people_alt_rounded),
    ('notifications', 'الإشعارات', Icons.notifications_rounded),
    ('content', 'المحتوى', Icons.library_books_rounded),
    ('settings', 'الإعدادات', Icons.settings_rounded),
    ('exams', 'الاختبارات', Icons.quiz_rounded),
    ('general', 'عام', Icons.admin_panel_settings_rounded),
  ];

  Color _categoryColor(String category) {
    switch (category) {
      case 'users':         return const Color(0xFF3B82F6);
      case 'notifications': return const Color(0xFF8B5CF6);
      case 'content':       return const Color(0xFFF59E0B);
      case 'settings':      return const Color(0xFF64748B);
      case 'exams':         return const Color(0xFF06B6D4);
      default:              return const Color(0xFF10B981);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'userRegistered':        return Icons.person_add_rounded;
      case 'userSuspended':         return Icons.block_rounded;
      case 'userReactivated':       return Icons.check_circle_rounded;
      case 'userDeleted':           return Icons.delete_rounded;
      case 'userUpdated':           return Icons.edit_rounded;
      case 'notificationSent':      return Icons.send_rounded;
      case 'bookAdded':             return Icons.add_box_rounded;
      case 'bookUpdated':           return Icons.edit_document;
      case 'bookDeleted':           return Icons.delete_forever_rounded;
      case 'settingChanged':        return Icons.tune_rounded;
      case 'featureToggled':        return Icons.toggle_on_rounded;
      case 'maintenanceModeChanged': return Icons.build_rounded;
      case 'examAdded':             return Icons.quiz_rounded;
      case 'examDeleted':           return Icons.delete_sweep_rounded;
      default:                      return Icons.info_rounded;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // شريط الفلاتر
          _buildFilterBar(context),
          // أزرار الإجراءات الجماعية
          _buildActionBar(context),
          // قائمة الإشعارات
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot>>(
              stream: AdminActivityService.logsStream(
                category: filterCategory == 'all' ? null : filterCategory,
                unreadOnly: unreadOnly ? true : null,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _accent),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.redAccent, size: 56),
                          const SizedBox(height: 16),
                          Text(
                            'تعذّر تحميل سجل النشاط',
                            style: GoogleFonts.tajawal(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snap.error}',
                            style: GoogleFonts.tajawal(
                                fontSize: 12, color: Colors.white38),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final docs = snap.data ?? [];
                if (docs.isEmpty) {
                  return _buildEmpty();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  itemCount: docs.length,
                  itemBuilder: (context, i) => _buildCard(context, docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        children: [
          // الفئات
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                final isSelected = filterCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => onFilterChanged(cat.$1, unreadOnly),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _accent.withValues(alpha: 0.2) : _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? _accent : Colors.white12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.$3,
                              size: 14,
                              color: isSelected ? _accent : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            cat.$2,
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: isSelected ? _accent : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // فلتر غير المقروءة
          GestureDetector(
            onTap: () => onFilterChanged(filterCategory, !unreadOnly),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: unreadOnly ? Colors.orange.withValues(alpha: 0.15) : _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: unreadOnly ? Colors.orange : Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_unread_rounded,
                      size: 14,
                      color: unreadOnly ? Colors.orange : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'غير المقروءة فقط',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: unreadOnly ? Colors.orange : Colors.grey,
                      fontWeight: unreadOnly ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.done_all_rounded,
            label: 'تحديد الكل كمقروء',
            color: Colors.green,
            onTap: () async {
              await AdminActivityService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ تم تحديد الكل كمقروء', style: TextStyle(fontFamily: 'Tajawal')),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.cleaning_services_rounded,
            label: 'مسح القديمة (30 يوم)',
            color: Colors.orange,
            onTap: () async {
              final count = await AdminActivityService.clearOlderThan(30);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ تم حذف $count سجل قديم', style: const TextStyle(fontFamily: 'Tajawal')),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final isRead = d['isRead'] as bool? ?? false;
    final type = d['type'] as String? ?? 'generalActivity';
    final category = d['category'] as String? ?? 'general';
    final color = _categoryColor(category);
    final icon = _typeIcon(type);
    final createdAt = d['createdAt'] as Timestamp?;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      onDismissed: (_) => AdminActivityService.deleteLog(doc.id),
      child: GestureDetector(
        onTap: () {
          if (!isRead) AdminActivityService.markAsRead(doc.id);
          _showDetail(context, d, color, icon, createdAt);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isRead ? _surface : _surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.white.withValues(alpha: 0.06) : color.withValues(alpha: 0.4),
              width: isRead ? 1 : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الأيقونة
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(child: Icon(icon, color: color, size: 22)),
                      if (!isRead)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // المحتوى
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              d['title'] as String? ?? '',
                              style: GoogleFonts.tajawal(
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // نوع النشاط
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getCategoryLabel(category),
                              style: GoogleFonts.tajawal(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['description'] as String? ?? '',
                        style: GoogleFonts.tajawal(
                          fontSize: 12.5,
                          color: Colors.white60,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              d['adminName'] as String? ?? '',
                              style: GoogleFonts.tajawal(
                                  fontSize: 11, color: Colors.white38),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.access_time_rounded,
                              size: 12, color: Colors.white30),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(createdAt),
                            style: GoogleFonts.tajawal(
                                fontSize: 10, color: Colors.white30),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded,
              size: 80, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),
          Text(
            'لا توجد سجلات نشاط',
            style: GoogleFonts.tajawal(
                fontSize: 18, color: Colors.white.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا جميع الأنشطة الإدارية فور حدوثها',
            style: GoogleFonts.tajawal(
                fontSize: 13, color: Colors.white.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> d, Color color,
      IconData icon, Timestamp? createdAt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['title'] ?? '',
                          style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white)),
                      Text(_getCategoryLabel(d['category'] ?? 'general'),
                          style: GoogleFonts.tajawal(
                              fontSize: 13, color: color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(Icons.description_rounded, 'الوصف', d['description'] ?? ''),
            _DetailRow(Icons.person_rounded, 'المسؤول', d['adminName'] ?? ''),
            if ((d['targetUserName'] ?? '').toString().isNotEmpty)
              _DetailRow(Icons.person_pin_rounded, 'المستخدم المرتبط', d['targetUserName'] ?? ''),
            _DetailRow(Icons.calendar_today_rounded, 'التاريخ والوقت', _formatDate(createdAt)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'users':         return 'المستخدمون';
      case 'notifications': return 'الإشعارات';
      case 'content':       return 'المحتوى';
      case 'settings':      return 'الإعدادات';
      case 'exams':         return 'الاختبارات';
      default:              return 'عام';
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'غير معروف';
    final d = ts.toDate().toLocal();
    return intl.DateFormat('d MMM yyyy، h:mm a', 'ar').format(d);
  }
}

// ═══════════════════════════════════════════════════════════════
//  تاب إرسال إشعار
// ═══════════════════════════════════════════════════════════════
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

  String _sendType = 'all';
  String _selectedTopic = 'all';
  String _notifType = 'general';
  bool _isSending = false;

  static const _surface = Color(0xFF1E293B);
  static const _accent = Color(0xFF8B5CF6);

  final _topics = ['all', 'students', 'teachers', 'bac', 'bem'];
  final _topicLabels = {
    'all': 'جميع المستخدمين',
    'students': 'الطلاب',
    'teachers': 'المعلمون',
    'bac': 'طلاب البكالوريا',
    'bem': 'طلاب البيام',
  };
  final _notifTypes = {
    'general': ('عام', Icons.notifications_rounded),
    'update': ('تحديث', Icons.system_update_rounded),
    'reminder': ('تذكير', Icons.alarm_rounded),
    'system': ('نظام', Icons.settings_rounded),
    'result': ('نتيجة', Icons.emoji_events_rounded),
  };

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
      final notifData = {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _notifType,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'targetType': _sendType,
      };

      if (_sendType == 'uid') {
        notifData['targetUid'] = _uidCtrl.text.trim();
      } else {
        notifData['targetTopic'] = _selectedTopic;
      }

      await FirebaseFirestore.instance.collection('app_notifications').add(notifData);

      // تسجيل النشاط في سجل الإدارة
      await AdminActivityService.log(
        type: AdminActivityType.notificationSent,
        title: 'تم إرسال إشعار: ${_titleCtrl.text.trim()}',
        description:
            'الرسالة: ${_bodyCtrl.text.trim()} — الهدف: ${_sendType == "uid" ? "مستخدم (${_uidCtrl.text.trim()})" : _topicLabels[_selectedTopic]}',
        metadata: {
          'notifTitle': _titleCtrl.text.trim(),
          'notifBody': _bodyCtrl.text.trim(),
          'target': _sendType == 'uid' ? _uidCtrl.text.trim() : _selectedTopic,
          'sendType': _sendType,
          'notifType': _notifType,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الإشعار وتسجيل النشاط بنجاح',
                style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.green,
          ),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _uidCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإرسال: تحقق من اتصالك بالإنترنت ($e)',
                style: const TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع الإرسال
            _sectionTitle('الجمهور المستهدف'),
            const SizedBox(height: 10),
            Row(
              children: [
                _RadioCard(
                  label: 'إشعار عام',
                  icon: Icons.groups_rounded,
                  value: 'all',
                  groupValue: _sendType,
                  onChanged: (v) => setState(() => _sendType = v!),
                ),
                const SizedBox(width: 10),
                _RadioCard(
                  label: 'مستخدم محدد',
                  icon: Icons.person_pin_rounded,
                  value: 'uid',
                  groupValue: _sendType,
                  onChanged: (v) => setState(() => _sendType = v!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_sendType == 'all') ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _topics.map((t) => ChoiceChip(
                  label: Text(_topicLabels[t]!,
                      style: GoogleFonts.tajawal(fontSize: 12)),
                  selected: _selectedTopic == t,
                  selectedColor: _accent.withValues(alpha: 0.25),
                  labelStyle: TextStyle(
                    color: _selectedTopic == t ? _accent : Colors.grey,
                  ),
                  backgroundColor: _surface,
                  onSelected: (_) => setState(() => _selectedTopic = t),
                  side: BorderSide(
                    color: _selectedTopic == t ? _accent : Colors.white12,
                  ),
                )).toList(),
              ),
            ] else ...[
              TextFormField(
                controller: _uidCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('UID المستخدم المحدد', Icons.fingerprint_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'أدخل UID صالح' : null,
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle('محتوى الإشعار'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('عنوان الإشعار', Icons.title_rounded),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('نص الإشعار', Icons.message_rounded),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'النص مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _sectionTitle('نوع الإشعار'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _notifTypes.entries.map((e) => ChoiceChip(
                avatar: Icon(e.value.$2, size: 14,
                    color: _notifType == e.key ? _accent : Colors.grey),
                label: Text(e.value.$1,
                    style: GoogleFonts.tajawal(fontSize: 12)),
                selected: _notifType == e.key,
                selectedColor: _accent.withValues(alpha: 0.25),
                labelStyle: TextStyle(
                  color: _notifType == e.key ? _accent : Colors.grey,
                ),
                backgroundColor: _surface,
                onSelected: (_) => setState(() => _notifType = e.key),
                side: BorderSide(
                    color: _notifType == e.key ? _accent : Colors.white12),
              )).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSending ? 'جارٍ الإرسال...' : 'إرسال الإشعار',
                  style: GoogleFonts.tajawal(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _isSending ? null : _send,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.purpleAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم تسجيل هذا الإشعار تلقائياً في سجل نشاط الإدارة.',
                      style: GoogleFonts.tajawal(
                          fontSize: 12, color: Colors.purpleAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.tajawal(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white70,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Widgets مساعدة
// ═══════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, color: color, size: 16),
      label: Text(
        label,
        style: GoogleFonts.tajawal(fontSize: 11, color: color),
      ),
      onPressed: onTap,
    );
  }
}

class _RadioCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : Colors.white12,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
                  size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.tajawal(fontSize: 11, color: Colors.white38),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.tajawal(
                    fontSize: 14, color: Colors.white, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
