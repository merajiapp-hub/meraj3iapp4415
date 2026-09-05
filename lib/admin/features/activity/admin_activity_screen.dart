import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/admin_colors.dart';
import '../../shared/services/admin_activity_service.dart';

class AdminActivityScreen extends StatelessWidget {
  const AdminActivityScreen({super.key});

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
                    'سجل النشاطات (Activity Log)',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textDark,
                    ),
                  ),
                  Text(
                    'مراقبة جميع الحركات والأحداث داخل النظام بشكل حي',
                    style: GoogleFonts.tajawal(
                      color: AdminColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 18),
                label: Text('تصفية', style: GoogleFonts.tajawal()),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // ── Activity Stream ───────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: AdminActivityService().getActivityStream(limit: 100),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AdminColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'خطأ أثناء تحميل النشاطات',
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
                      Icon(Icons.history_outlined, size: 64, color: AdminColors.textLight.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد أي نشاط مسجل',
                        style: GoogleFonts.tajawal(
                          fontSize: 18,
                          color: AdminColors.textLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _ActivityTimelineItem(
                    data: data,
                    isLast: i == docs.length - 1,
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

class _ActivityTimelineItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;

  const _ActivityTimelineItem({required this.data, this.isLast = false});

  IconData _iconForType(String? type) {
    switch (type) {
      case 'login': return Icons.login;
      case 'new_user': return Icons.person_add_outlined;
      case 'new_book': return Icons.book_outlined;
      case 'delete': return Icons.delete_outline;
      case 'update': return Icons.update_outlined;
      default: return Icons.circle_outlined;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'login': return AdminColors.info;
      case 'new_user': return AdminColors.success;
      case 'new_book': return AdminColors.primary;
      case 'delete': return AdminColors.error;
      case 'update': return AdminColors.warning;
      default: return AdminColors.textLight;
    }
  }

  String _formatTime(dynamic ts) {
    if (ts is! Timestamp) return '—';
    final dt = ts.toDate();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$y-$mo-$d $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String?;
    final title = data['title'] as String? ?? 'نشاط غير معروف';
    final message = data['message'] as String? ?? '';
    final userName = data['userName'] as String? ?? 'مستخدم مجهول';
    final browser = data['browser'] as String? ?? 'غير معروف';
    final os = data['os'] as String? ?? 'غير معروف';
    final ts = data['createdAt'];

    final color = _colorForType(type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line and Dot
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconForType(type), color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textDark,
                          ),
                        ),
                        Text(
                          _formatTime(ts),
                          style: GoogleFonts.tajawal(
                            color: AdminColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: GoogleFonts.tajawal(
                        color: AdminColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AdminColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          userName,
                          style: GoogleFonts.tajawal(
                            color: AdminColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.computer_outlined, size: 14, color: AdminColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          '$os - $browser',
                          style: GoogleFonts.tajawal(
                            color: AdminColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
