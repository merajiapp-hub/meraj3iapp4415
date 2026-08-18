import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart' show navigatorKey;
import '../providers/notifications_provider.dart';
import '../screens/notification_details_screen.dart';
import '../models/schedule_item.dart';

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

  // ─── إشعارات الجدول الدراسي الثلاثية ────────────────────────────────────────

  DateTime _nextInstanceOfWeekdayAndTime(int weekday, TimeOfDay time) {
    DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Adjust to next target weekday
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> scheduleSessionNotifications(ScheduleItem item) async {
    // دائماً نلغي القديم قبل جدولة جديد لتجنب التكرار
    await cancelSessionNotifications(item.id);

    if (!item.notify) return;

    final int baseId = (item.id.hashCode.abs() % 100000) * 10;
    
    final nextStart = _nextInstanceOfWeekdayAndTime(item.weekday, item.startTime);
    final nextEnd = _nextInstanceOfWeekdayAndTime(item.weekday, item.endTime);

    // 1. إشعار التذكير قبل الموعد بـ 10 دقائق (أو حسب الإعداد)
    DateTime prepTime = nextStart.subtract(Duration(minutes: item.notifyMinutesBefore));
    if (prepTime.isBefore(DateTime.now())) {
      prepTime = prepTime.add(const Duration(days: 7));
    }

    // 2. إشعار وقت البدء
    DateTime startTime = nextStart;
    if (startTime.isBefore(DateTime.now())) {
      startTime = startTime.add(const Duration(days: 7));
    }

    // 3. إشعار وقت الانتهاء
    DateTime endTime = nextEnd;
    if (endTime.isBefore(DateTime.now())) {
      endTime = endTime.add(const Duration(days: 7));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meraj3i_schedule',
        'الجدول الدراسي',
        channelDescription: 'تنبيهات مواعيد الحصص الأسبوعية',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      // جدولة تنبيه الاستعداد (BaseID + 0)
      if (item.notifyMinutesBefore > 0) {
        await _plugin.zonedSchedule(
          id: baseId,
          title: '🔔 تذكير بالحصة',
          body: 'ستبدأ حصة "${item.title}" بعد ${item.notifyMinutesBefore} دقيقة',
          scheduledDate: tz.TZDateTime.from(prepTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }

      // جدولة تنبيه البدء (BaseID + 1)
      await _plugin.zonedSchedule(
        id: baseId + 1,
        title: '📚 بدأت الحصة الآن',
        body: 'حان وقت البدء في حصة "${item.title}"',
        scheduledDate: tz.TZDateTime.from(startTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // جدولة تنبيه الانتهاء (BaseID + 2)
      await _plugin.zonedSchedule(
        id: baseId + 2,
        title: '✅ انتهت الحصة',
        body: 'أحسنت، لقد أكملت الوقت المحدد لحصة "${item.title}"',
        scheduledDate: tz.TZDateTime.from(endTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Error scheduling session notifications: $e');
    }
  }

  Future<void> cancelSessionNotifications(String sessionId) async {
    final int baseId = (sessionId.hashCode.abs() % 100000) * 10;
    await _plugin.cancel(id: baseId);     // Prep
    await _plugin.cancel(id: baseId + 1); // Start
    await _plugin.cancel(id: baseId + 2); // End
  }
}

// معالج الإشعارات في الخلفية (يجب أن يكون دالة عامة على المستوى الأعلى)
@pragma('vm:entry-point')
void _backgroundNotificationHandler(NotificationResponse details) {
  // معالجة بسيطة في الخلفية — التنقل سيتم عند فتح التطبيق
  debugPrint('Background notification tapped: ${details.payload}');
}
