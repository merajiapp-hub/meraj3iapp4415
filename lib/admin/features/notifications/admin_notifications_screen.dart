import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/admin_colors.dart';
import '../../shared/services/admin_notification_service.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مركز الإشعارات',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textDark,
                    ),
                  ),
                  Text(
                    'جميع الإشعارات الإدارية بشكل حي (Real-Time)',
                    style: GoogleFonts.tajawal(
                      color: AdminColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => AdminNotificationService().markAllAsRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: Text('تعليم الكل كمقروء', style: GoogleFonts.tajawal()),
                style: TextButton.styleFrom(
                  foregroundColor: AdminColors.primary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Notifications Stream ────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AdminNotificationService().getNotificationsStream(limit: 100),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AdminColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'خطأ أثناء تحميل الإشعارات',
                        style: GoogleFonts.tajawal(color: AdminColors.error),
                      ),
                    ],
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_outlined,
                          size: 64,
                          color: AdminColors.textLight.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات حتى الآن',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          color: AdminColors.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return _NotificationCard(
                    docId: doc.id,
                    data: data,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _NotificationCard({required this.docId, required this.data});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'warning': return AdminColors.warning;
      case 'error': return AdminColors.error;
      case 'success': return AdminColors.success;
      case 'critical': return const Color(0xFF7C3AED);
      default: return AdminColors.info;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'warning': return Icons.warning_amber_outlined;
      case 'error': return Icons.error_outline;
      case 'success': return Icons.check_circle_outline;
      case 'critical': return Icons.gpp_bad_outlined;
      default: return Icons.info_outline;
    }
  }

  String _formatTime(dynamic ts) {
    if (ts is! Timestamp) return '—';
    final dt = ts.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final isRead = data['read'] as bool? ?? false;
    final severity = data['severity'] as String? ?? 'info';
    final priority = data['priority'] as String? ?? 'normal';
    final title = data['title'] as String? ?? 'إشعار';
    final message = data['message'] as String? ?? '';
    final ts = data['createdAt'];

    final color = _severityColor(severity);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          right: BorderSide(
            color: isRead ? Colors.transparent : color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_severityIcon(severity), color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.tajawal(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  color: AdminColors.textDark,
                ),
              ),
            ),
            if (priority == 'high' || priority == 'critical')
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priority == 'critical' ? 'حرج' : 'عالي',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: AdminColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.tajawal(
                  color: AdminColors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(ts),
              style: GoogleFonts.tajawal(
                  fontSize: 11, color: AdminColors.textLight),
            ),
          ],
        ),
        trailing: !isRead
            ? IconButton(
                icon: const Icon(Icons.done, color: AdminColors.success),
                tooltip: 'تعليم كمقروء',
                onPressed: () =>
                    AdminNotificationService().markAsRead(docId),
              )
            : const Icon(Icons.check_circle_outline,
                color: AdminColors.success, size: 18),
      ),
    );
  }
}
