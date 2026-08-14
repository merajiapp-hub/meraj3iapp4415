import 'package:flutter/material.dart';
import '../models/schedule_item.dart';

class ScheduleProvider extends ChangeNotifier {
  final Map<DateTime, List<ScheduleItem>> _items = {};

  Map<DateTime, List<ScheduleItem>> get items => _items;

  List<ScheduleItem> getItemsForDay(DateTime day) {
    // نأخذ فقط اليوم والشهر والسنة للمقارنة
    final date = DateTime(day.year, day.month, day.day);
    return _items[date] ?? [];
  }

  void addItem(ScheduleItem item) {
    final date = DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
    if (_items[date] == null) {
      _items[date] = [];
    }
    _items[date]!.add(item);
    
    // ترتيب حسب وقت البداية
    _items[date]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    notifyListeners();
  }

  void removeItem(ScheduleItem item) {
    final date = DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
    if (_items[date] != null) {
      _items[date]!.removeWhere((i) => i.id == item.id);
      if (_items[date]!.isEmpty) {
        _items.remove(date);
      }
      notifyListeners();
    }
  }

  void toggleItemCompletion(ScheduleItem item) {
    final date = DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
    if (_items[date] != null) {
      final index = _items[date]!.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[date]![index] = item.copyWith(isCompleted: !item.isCompleted);
        notifyListeners();
      }
    }
  }
}
