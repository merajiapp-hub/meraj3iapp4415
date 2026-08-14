import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart' show navigatorKey;
import '../providers/notifications_provider.dart';
import '../screens/notification_details_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'meraj3i_main';
  static const _channelName = 'مراجعي — الإشعارات';
  static const _channelDesc = 'إشعارات تطبيق مراجعي';

  static const _tasksChannelId = 'meraj3i_tasks';
  static const _tasksChannelName = 'مراجعي — المهام';
  static const _tasksChannelDesc = 'تنبيهات المهام الدراسية';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        // عند الضغط على الإشعار من شريط الإشعارات — التطبيق مفتوح أو في الخلفية
        _handleNotificationTap(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse:
          _backgroundNotificationHandler,
    );

    // إنشاء قناة الإشعارات بأعلى أهمية
    await _createNotificationChannel();

    // طلب الصلاحيات على Android 13+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const tasksChannel = AndroidNotificationChannel(
      _tasksChannelId,
      _tasksChannelName,
      description: _tasksChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(channel);
    await androidPlugin.createNotificationChannel(tasksChannel);
  }

  // معالج الإشعار عند الضغط
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) {
      // التطبيق ربما لم يُكمل التهيئة — انتظر قليلاً ثم انتقل
      Future.delayed(const Duration(milliseconds: 1500), () {
        _navigateToNotification(payload);
      });
      return;
    }
    _navigateToNotification(payload);
  }

  void _navigateToNotification(String notificationId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final provider = Provider.of<NotificationsProvider>(context, listen: false);
    try {
      final notif = provider.notifications.firstWhere(
        (n) => n.id == notificationId,
      );
      provider.markAsRead(notificationId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationDetailsScreen(notification: notif),
        ),
      );
    } catch (e) {
      // الإشعار غير موجود محلياً — انتقل لصفحة الإشعارات
      debugPrint('Notification not found locally: $e');
    }
  }

  // ─── إشعار فوري ───────────────────────────────────────────────────────────
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        // عرض النص الكامل بدون اقتطاع
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'MERAJ3I',
        ),
        // إضافة أيقونة ملونة
        color: const Color(0xFF14B8A6),
        // الإشعار لا يُلغى تلقائياً عند الضغط
        autoCancel: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'meraj3i_notifications',
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ─── إشعار مجدوَل ─────────────────────────────────────────────────────────
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _tasksChannelId,
          _tasksChannelName,
          channelDescription: _tasksChannelDesc,
          importance: Importance.max,
          priority: Priority.high,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}

// معالج الإشعارات في الخلفية (يجب أن يكون دالة عامة على المستوى الأعلى)
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse details) {
  // معالجة بسيطة في الخلفية — التنقل سيتم عند فتح التطبيق
  debugPrint('Background notification tapped: ${details.payload}');
}
