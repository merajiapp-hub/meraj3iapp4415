import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_item.dart';
import '../data/notification_service.dart';

class ScheduleProvider extends ChangeNotifier {
  static const _prefsKey = 'schedule_items_v3';

  final Map<int, List<ScheduleItem>> _items = {
    1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [],
  }; // Key is weekday 1..7 (1 = Monday, 7 = Sunday)

  ScheduleProvider() {
    _loadFromPrefs();
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

  Future<void> _scheduleNotification(ScheduleItem item) async {
    await NotificationService().scheduleSessionNotifications(item);
  }

  Future<void> _cancelNotification(ScheduleItem item) async {
    await NotificationService().cancelSessionNotifications(item.id);
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
