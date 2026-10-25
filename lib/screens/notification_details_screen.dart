import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notifications_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'announcements_screen.dart';
import 'honor_certificate_screen.dart';
import 'news_screen.dart';
import 'direct_chat_screen.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final AppNotificationModel notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  Future<void> _openExternalLink(BuildContext context) async {
    final uri = Uri.tryParse(notification.targetId ?? '');
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !const {'http', 'https'}.contains(uri.scheme.toLowerCase())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('رابط الإشعار غير صالح.')));
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر فتح الرابط.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'تفاصيل الإشعار',
          style: GoogleFonts.tajawal(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'notif_icon_${notification.id}',
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: notification.typeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.typeIcon,
                  size: 64,
                  color: notification.typeColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              notification.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 64),
              decoration: BoxDecoration(
                color: notification.typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: notification.typeColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    notification.typeIcon,
                    size: 16,
                    color: notification.typeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    notification.typeLabel,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: notification.typeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.body,
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat(
                          'yyyy/MM/dd - hh:mm a',
                        ).format(notification.timestamp),
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (notification.targetType != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (notification.targetType == 'externalUrl') {
                            await _openExternalLink(context);
                            return;
                          }
                          final page = switch (notification.targetType) {
                            'news' => NewsScreen(
                              selectedId: notification.targetId,
                            ),
                            'announcement' => AnnouncementsScreen(
                              selectedId: notification.targetId,
                            ),
                            'chat' => const DirectChatScreen(),
                            'certificate' =>
                              notification.targetId == null
                                  ? null
                                  : HonorCertificateScreen(
                                      certificateId: notification.targetId!,
                                    ),
                            _ => null,
                          };
                          if (page != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => page),
                            );
                          }
                        },
                        icon: Icon(notification.typeIcon, size: 18),
                        label: Text(
                          notification.targetType == 'news'
                              ? 'فتح الأخبار'
                              : notification.targetType == 'announcement'
                              ? 'فتح الإعلانات'
                              : notification.targetType == 'chat'
                              ? 'فتح المحادثة'
                              : notification.targetType == 'certificate'
                              ? 'عرض الشهادة'
                              : notification.targetType == 'externalUrl'
                              ? 'فتح رابط الشهادة'
                              : 'فتح الصفحة',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
