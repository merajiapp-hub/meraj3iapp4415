import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/schedule_item.dart';

class ScheduleProvider extends ChangeNotifier {
  static const _prefsKey = 'schedule_items_v3';

  final Map<int, List<ScheduleItem>> _items = {
    1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [],
  }; // Key is weekday 1..7 (1 = Monday, 7 = Sunday)

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Map<int, List<ScheduleItem>> get items => _items;

  ScheduleProvider() {
    _initNotifications();
    _loadFromPrefs();
  }

  // ─── تهيئة الإشعارات ───────────────────────────────────
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
  }

  // ─── تحميل من الذاكرة ──────────────────────────────────
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList(_prefsKey) ?? [];
    for (int i = 1; i <= 7; i++) {
      _items[i] = [];
    }

    for (final s in saved) {
      try {
        final item = ScheduleItem.fromJson(s);
        _items[item.weekday]?.add(item);
      } catch (e) {
        debugPrint('Error loading schedule item: $e');
      }
    }

    _sortItems();
    notifyListeners();
  }

  void _sortItems() {
    for (int i = 1; i <= 7; i++) {
      _items[i]?.sort((a, b) {
        if (a.startTime.hour != b.startTime.hour) {
          return a.startTime.hour.compareTo(b.startTime.hour);
        }
        return a.startTime.minute.compareTo(b.startTime.minute);
      });
    }
  }

  // ─── حفظ في الذاكرة ────────────────────────────────────
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = [];
    for (final dayItems in _items.values) {
      for (final item in dayItems) {
        list.add(item.toJson());
      }
    }
    await prefs.setStringList(_prefsKey, list);
  }

  // ─── إحصائيات ──────────────────────────────────────────
  int getTotalSessions() {
    int total = 0;
    for (final dayItems in _items.values) {
      total += dayItems.length;
    }
    return total;
  }

  double getTotalHours() {
    double hours = 0;
    for (final dayItems in _items.values) {
      for (final item in dayItems) {
        final startMinutes = item.startTime.hour * 60 + item.startTime.minute;
        final endMinutes = item.endTime.hour * 60 + item.endTime.minute;
        int diff = endMinutes - startMinutes;
        if (diff < 0) diff += 24 * 60; // handle wrap around midnight
        hours += diff / 60.0;
      }
    }
    return hours;
  }

  // ─── جدولة إشعار ───────────────────────────────────────
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

  Future<void> _scheduleNotification(ScheduleItem item) async {
    if (!item.notify) return;

    DateTime nextInstance = _nextInstanceOfWeekdayAndTime(item.weekday, item.startTime);
    DateTime notifyTime = nextInstance.subtract(Duration(minutes: item.notifyMinutesBefore));
    
    if (notifyTime.isBefore(DateTime.now())) {
      notifyTime = notifyTime.add(const Duration(days: 7));
    }

    try {
      final tzTime = tz.TZDateTime.from(notifyTime, tz.local);
      final int notifId = item.id.hashCode.abs() % 100000;

      await _notifications.zonedSchedule(
        id: notifId,
        title: '📚 حصة ${item.title} تبدأ قريباً',
        body: 'بعد ${item.notifyMinutesBefore} دقيقة${item.teacher != null && item.teacher!.isNotEmpty ? " — ${item.teacher}" : ""}${item.room != null && item.room!.isNotEmpty ? " — ${item.room}" : ""}',
        scheduledDate: tzTime,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'schedule_channel',
            'الجدول الدراسي',
            channelDescription: 'إشعارات الحصص الدراسية',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, // Repeats weekly!
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> _cancelNotification(ScheduleItem item) async {
    final int notifId = item.id.hashCode.abs() % 100000;
    await _notifications.cancel(id: notifId);
  }

  // ─── العمليات الأساسية ──────────────────────────────────
  List<ScheduleItem> getItemsForDay(int weekday) {
    return _items[weekday] ?? [];
  }

  Future<void> addItem(ScheduleItem item) async {
    _items[item.weekday]?.add(item);
    _sortItems();
    notifyListeners();
    await _saveToPrefs();
    await _scheduleNotification(item);
  }

  Future<void> updateItem(ScheduleItem oldItem, ScheduleItem newItem) async {
    // Remove old
    _items[oldItem.weekday]?.removeWhere((i) => i.id == oldItem.id);
    await _cancelNotification(oldItem);

    // Add new
    _items[newItem.weekday]?.add(newItem);
    _sortItems();
    
    notifyListeners();
    await _saveToPrefs();
    await _scheduleNotification(newItem);
  }

  Future<void> removeItem(ScheduleItem item) async {
    _items[item.weekday]?.removeWhere((i) => i.id == item.id);
    notifyListeners();
    await _saveToPrefs();
    await _cancelNotification(item);
  }
}
