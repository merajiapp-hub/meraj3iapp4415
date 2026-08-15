import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/schedule_item.dart';

class ScheduleProvider extends ChangeNotifier {
  static const _prefsKey = 'schedule_items_v2';

  final Map<DateTime, List<ScheduleItem>> _items = {};
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Map<DateTime, List<ScheduleItem>> get items => _items;

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
    _items.clear();
    for (final s in saved) {
      try {
        final item = ScheduleItem.fromJson(s);
        final date = DateTime(
            item.startTime.year, item.startTime.month, item.startTime.day);
        _items[date] ??= [];
        _items[date]!.add(item);
      } catch (e) {
        debugPrint('Error loading schedule item: $e');
      }
    }
    // ترتيب كل يوم حسب وقت البداية
    for (final key in _items.keys) {
      _items[key]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    notifyListeners();
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

  // ─── جدولة إشعار ───────────────────────────────────────
  Future<void> _scheduleNotification(ScheduleItem item) async {
    if (!item.notify) return;

    final notifyTime = item.startTime
        .subtract(Duration(minutes: item.notifyMinutesBefore));
    if (notifyTime.isBefore(DateTime.now())) return;

    try {
      final tzTime = tz.TZDateTime.from(notifyTime, tz.local);
      final int notifId = item.id.hashCode.abs() % 100000;

      await _notifications.zonedSchedule(
        id: notifId,
        title: '📚 حصة ${item.title} تبدأ قريباً',
        body: 'بعد ${item.notifyMinutesBefore} دقيقة${item.teacher != null ? " — ${item.teacher}" : ""}${item.room != null ? " — ${item.room}" : ""}',
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
  List<ScheduleItem> getItemsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final directItems = _items[date] ?? [];

    // إضافة الحصص الأسبوعية المتكررة
    final weeklyItems = <ScheduleItem>[];
    for (final entry in _items.entries) {
      for (final item in entry.value) {
        if (item.isWeekly &&
            entry.key != date &&
            entry.key.weekday == day.weekday) {
          // إنشاء نسخة بتاريخ اليوم المطلوب
          final diff = day.difference(entry.key);
          weeklyItems.add(item.copyWith(
            startTime: item.startTime.add(diff),
            endTime: item.endTime.add(diff),
          ));
        }
      }
    }

    final all = [...directItems, ...weeklyItems];
    all.sort((a, b) => a.startTime.compareTo(b.startTime));
    return all;
  }

  Future<void> addItem(ScheduleItem item) async {
    final date =
        DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
    _items[date] ??= [];
    _items[date]!.add(item);
    _items[date]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
    await _saveToPrefs();
    await _scheduleNotification(item);
  }

  Future<void> updateItem(ScheduleItem oldItem, ScheduleItem newItem) async {
    final oldDate = DateTime(oldItem.startTime.year, oldItem.startTime.month,
        oldItem.startTime.day);
    final newDate = DateTime(newItem.startTime.year, newItem.startTime.month,
        newItem.startTime.day);

    // حذف من الموقع القديم
    if (_items[oldDate] != null) {
      _items[oldDate]!.removeWhere((i) => i.id == oldItem.id);
      if (_items[oldDate]!.isEmpty) _items.remove(oldDate);
    }

    // إضافة في الموقع الجديد
    _items[newDate] ??= [];
    _items[newDate]!.add(newItem);
    _items[newDate]!.sort((a, b) => a.startTime.compareTo(b.startTime));

    notifyListeners();
    await _saveToPrefs();
    await _cancelNotification(oldItem);
    await _scheduleNotification(newItem);
  }

  Future<void> removeItem(ScheduleItem item) async {
    final date =
        DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
    if (_items[date] != null) {
      _items[date]!.removeWhere((i) => i.id == item.id);
      if (_items[date]!.isEmpty) _items.remove(date);
      notifyListeners();
      await _saveToPrefs();
      await _cancelNotification(item);
    }
  }

  Future<void> toggleItemCompletion(ScheduleItem item) async {
    final date =
        DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
    if (_items[date] != null) {
      final index = _items[date]!.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[date]![index] =
            item.copyWith(isCompleted: !item.isCompleted);
        notifyListeners();
        await _saveToPrefs();
      }
    }
  }
}

