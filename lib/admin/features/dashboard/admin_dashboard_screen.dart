import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/admin_colors.dart';
import '../../shared/services/admin_notification_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _totalUsers = 0;
  int _totalNotifications = 0;
  int _totalReviews = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore.collection('admin_notifications').where('read', isEqualTo: false).count().get(),
        _firestore.collection('reviews').count().get(),
      ]);

      if (mounted) {
        setState(() {
          _totalUsers = results[0].count ?? 0;
          _totalNotifications = results[1].count ?? 0;
          _totalReviews = results[2].count ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل الإحصائيات: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AdminColors.error),
            const SizedBox(height: 16),
            Text(_error!, style: GoogleFonts.tajawal(color: AdminColors.error)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _isLoading = true; _error = null; });
                _loadStats();
              },
              icon: const Icon(Icons.refresh),
              label: Text('إعادة المحاولة', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(22),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B4FC8), Color(0xFF1B76FF), Color(0xFF0E4EA8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F2D6AF0),
                    blurRadius: 20,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -35,
                    top: -22,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -12,
                    bottom: -38,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'مؤشرات الأداء',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لوحة الإدارة',
                              style: GoogleFonts.tajawal(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'نظرة عامة على أداء التطبيق والعمليات',
                              style: GoogleFonts.tajawal(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'اليوم',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() { _isLoading = true; _error = null; });
                              _loadStats();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text('تحديث', style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AdminColors.primaryDeep,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 1;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.7,
                  children: [
                    _StatCard(
                      title: 'المستخدمون',
                      value: _totalUsers.toString(),
                      icon: Icons.people_alt_rounded,
                      color: AdminColors.primary,
                      subtitle: 'مستخدم مسجل',
                    ),
                    _StatCard(
                      title: 'الإشعارات',
                      value: _totalNotifications.toString(),
                      icon: Icons.notifications_active_rounded,
                      color: AdminColors.warning,
                      subtitle: 'غير مقروءة',
                    ),
                    _StatCard(
                      title: 'التقييمات',
                      value: _totalReviews.toString(),
                      icon: Icons.star_rounded,
                      color: AdminColors.success,
                      subtitle: 'إجمالي التقييمات',
                    ),
                    _StatCard(
                      title: 'الكتب',
                      value: '128',
                      icon: Icons.menu_book_rounded,
                      color: AdminColors.info,
                      subtitle: 'عناوين متاحة',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'آخر النشاطات',
                  style: GoogleFonts.tajawal(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Live',
                    style: GoogleFonts.tajawal(
                      color: AdminColors.primaryDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RecentActivityList(),
            const SizedBox(height: 24),
            Text(
              'إشعارات النظام',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AdminColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _RecentAdminNotifications(),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.borderSoft, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AdminColors.shadowSoft,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: AdminColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.tajawal(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textDark,
                    height: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: color,
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

// ── Recent Activity List (Real-Time Stream) ───────────────────────────────────
class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin_activity')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AdminColors.info),
                  const SizedBox(width: 12),
                  Text(
                    'لا توجد نشاطات حتى الآن',
                    style: GoogleFonts.tajawal(color: AdminColors.textLight),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.history_outlined, color: AdminColors.textLight),
                  const SizedBox(width: 12),
                  Text(
                    'لا توجد نشاطات مسجلة بعد',
                    style: GoogleFonts.tajawal(color: AdminColors.textLight),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _ActivityTile(data: data);
            },
          );
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ActivityTile({required this.data});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'login': return Icons.login;
      case 'new_user': return Icons.person_add_outlined;
      case 'new_book': return Icons.book_outlined;
      case 'delete': return Icons.delete_outline;
      default: return Icons.circle_outlined;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'login': return AdminColors.info;
      case 'new_user': return AdminColors.success;
      case 'new_book': return AdminColors.primary;
      case 'delete': return AdminColors.error;
      default: return AdminColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String?;
    final title = data['title'] as String? ?? 'نشاط جديد';
    final message = data['message'] as String? ?? '';
    final ts = data['createdAt'];
    final time = ts is Timestamp
        ? _formatTime(ts.toDate())
        : '—';

    final color = _colorForType(type);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(_iconForType(type), color: color, size: 20),
      ),
      title: Text(title, style: GoogleFonts.tajawal(fontWeight: FontWeight.w600)),
      subtitle: Text(message, style: GoogleFonts.tajawal(color: AdminColors.textLight, fontSize: 13)),
      trailing: Text(time, style: GoogleFonts.tajawal(color: AdminColors.textLight, fontSize: 12)),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// ── Recent Admin Notifications (Real-Time Stream) ────────────────────────────
class _RecentAdminNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.borderSoft, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AdminColors.shadowSoft,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: AdminNotificationService().getNotificationsStream(limit: 5),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.notifications_none_outlined, color: AdminColors.textLight),
                  const SizedBox(width: 12),
                  Text('لا توجد إشعارات', style: GoogleFonts.tajawal(color: AdminColors.textLight)),
                ],
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final isRead = data['read'] as bool? ?? false;
              final severity = data['severity'] as String? ?? 'info';
              final title = data['title'] as String? ?? 'إشعار جديد';
              final message = data['message'] as String? ?? '';

              Color sevColor;
              IconData sevIcon;
              switch (severity) {
                case 'warning': sevColor = AdminColors.warning; sevIcon = Icons.warning_amber_outlined; break;
                case 'error': sevColor = AdminColors.error; sevIcon = Icons.error_outline; break;
                case 'success': sevColor = AdminColors.success; sevIcon = Icons.check_circle_outline; break;
                default: sevColor = AdminColors.info; sevIcon = Icons.info_outline;
              }

              return ListTile(
                tileColor: isRead ? null : sevColor.withValues(alpha: 0.04),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(sevIcon, color: sevColor, size: 20),
                ),
                title: Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(message, style: GoogleFonts.tajawal(color: AdminColors.textLight, fontSize: 13)),
                trailing: !isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  AdminNotificationService().markAsRead(docs[i].id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
