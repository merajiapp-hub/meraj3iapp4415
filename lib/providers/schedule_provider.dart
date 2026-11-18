import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/schedule_item.dart';
import '../data/notification_service.dart';
import '../providers/statistics_provider.dart';

/// مزود بيانات «جدولي الدراسي» المتكامل مع التزامن السحابي والتنبيهات الذكية
class ScheduleProvider extends ChangeNotifier {
  static const _prefsKey = 'schedule_items_v4';
  static const _tasksKey = 'schedule_tasks_v1';
  static const _vacationKey = 'schedule_vacation_mode';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // الحصص مصنفة حسب أيام الأسبوع (1 = الاثنين, 7 = الأحد)
  // وفي مراجعي: السبت = 6، الأحد = 7، الاثنين = 1، الثلاثاء = 2، الأربعاء = 3، الخميس = 4، الجمعة = 5
  final Map<int, List<ScheduleItem>> _items = {
    1: [],
    2: [],
    3: [],
    4: [],
    5: [],
    6: [],
    7: [],
  };

  final List<ScheduleTask> _tasks = [];
  bool _isVacationMode = false;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isVacationMode => _isVacationMode;
  List<ScheduleTask> get tasks => List.unmodifiable(_tasks);

  ScheduleProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _loadFromPrefs();
    await _syncWithFirestore();

    _isLoading = false;
    notifyListeners();
  }

  // ─── تحميل البيانات محلياً ────────────────────────────────────────────────
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVacationMode = prefs.getBool(_vacationKey) ?? false;

      // تحميل الحصص
      final List<String> saved = prefs.getStringList(_prefsKey) ?? [];
      for (int i = 1; i <= 7; i++) {
        _items[i] = [];
      }

      for (final s in saved) {
        try {
          final item = ScheduleItem.fromJson(s);
          _items[item.weekday]?.add(item);
        } catch (_) {}
      }

      // تحميل المهام
      final List<String> savedTasks = prefs.getStringList(_tasksKey) ?? [];
      _tasks.clear();
      for (final t in savedTasks) {
        try {
          _tasks.add(ScheduleTask.fromJson(t));
        } catch (_) {}
      }

      _sortItems();
    } catch (e) {
      debugPrint('[ScheduleProvider] Error loading local prefs: $e');
    }
  }

  // ─── مزامنة Firestore السحابية ───────────────────────────────────────────
  Future<void> _syncWithFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final colRef =
          _firestore.collection('users').doc(user.uid).collection('study_lessons');
      final snap = await colRef.get();

      if (snap.docs.isNotEmpty) {
        for (int i = 1; i <= 7; i++) {
          _items[i] = [];
        }
        for (final doc in snap.docs) {
          try {
            final item = ScheduleItem.fromMap(doc.data());
            _items[item.weekday]?.add(item);
          } catch (_) {}
        }
        _sortItems();
        await _saveToPrefs();
      } else if (getTotalSessions() > 0) {
        // رفع الحصص المحلية إلى Firestore لأول مرة
        for (final dayItems in _items.values) {
          for (final item in dayItems) {
            await colRef.doc(item.id).set(item.toMap(), SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      debugPrint('[ScheduleProvider] Firestore sync error: $e');
    }
  }

  // ─── حفظ البيانات محلياً ─────────────────────────────────────────────────
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> list = [];
      for (final dayItems in _items.values) {
        for (final item in dayItems) {
          list.add(item.toJson());
        }
      }
      await prefs.setStringList(_prefsKey, list);

      final taskList = _tasks.map((t) => t.toJson()).toList();
      await prefs.setStringList(_tasksKey, taskList);
      await prefs.setBool(_vacationKey, _isVacationMode);
    } catch (e) {
      debugPrint('[ScheduleProvider] Error saving to prefs: $e');
    }
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

  // ─── فحص تعارض التوقيت بين الحصص ────────────────────────────────────────
  bool hasConflict(ScheduleItem item, {String? excludeId}) {
    final dayItems = _items[item.weekday] ?? [];
    final newStart = item.startTime.hour * 60 + item.startTime.minute;
    final newEnd = item.endTime.hour * 60 + item.endTime.minute;

    for (final existing in dayItems) {
      if (existing.id == excludeId || existing.id == item.id) continue;
      if (existing.isCancelled) continue;

      final existStart = existing.startTime.hour * 60 + existing.startTime.minute;
      final existEnd = existing.endTime.hour * 60 + existing.endTime.minute;

      // تداخل الفترات
      if (newStart < existEnd && newEnd > existStart) {
        return true;
      }
    }
    return false;
  }

  // ─── فلاتر الفترة الصباحية والمسائية ──────────────────────────────────────
  List<ScheduleItem> getItemsForDay(int weekday) {
    return _items[weekday] ?? [];
  }

  List<ScheduleItem> getMorningItems(int weekday) {
    return (_items[weekday] ?? []).where((i) => i.isMorning).toList();
  }

  List<ScheduleItem> getEveningItems(int weekday) {
    return (_items[weekday] ?? []).where((i) => i.isEvening).toList();
  }

  // ─── معرفة الحصة القادمة والوقت المتبقي ──────────────────────────────────
  (ScheduleItem?, int)? getNextUpcomingSession() {
    final now = DateTime.now();
    final todayWeekday = now.weekday; // 1 = Monday .. 7 = Sunday
    final currentMinutes = now.hour * 60 + now.minute;

    final todayItems = _items[todayWeekday] ?? [];
    for (final item in todayItems) {
      if (item.isCancelled) continue;
      final startMin = item.startTime.hour * 60 + item.startTime.minute;
      final endMin = item.endTime.hour * 60 + item.endTime.minute;

      if (currentMinutes < endMin) {
        final diff = startMin - currentMinutes;
        return (item, diff); // إذا كان diff <= 0 فهي جارية الآن
      }
    }

    return null;
  }

  // ─── إضافة حصة جديدة ────────────────────────────────────────────────────
  Future<void> addItem(ScheduleItem item) async {
    _items[item.weekday]?.add(item);
    _sortItems();
    notifyListeners();

    await _saveToPrefs();

    if (!_isVacationMode && !item.isCancelled) {
      await _scheduleNotification(item);
    }

    // حفظ في Firestore إن وُجد مستخدم
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('study_lessons')
            .doc(item.id)
            .set(item.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ─── تعديل حصة ──────────────────────────────────────────────────────────
  Future<void> updateItem(ScheduleItem oldItem, ScheduleItem newItem) async {
    _items[oldItem.weekday]?.removeWhere((i) => i.id == oldItem.id);
    await _cancelNotification(oldItem);

    _items[newItem.weekday]?.add(newItem);
    _sortItems();
    notifyListeners();

    await _saveToPrefs();

    if (!_isVacationMode && !newItem.isCancelled) {
      await _scheduleNotification(newItem);
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('study_lessons')
            .doc(newItem.id)
            .set(newItem.toMap(), SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ─── حذف حصة ───────────────────────────────────────────────────────────
  Future<void> removeItem(ScheduleItem item) async {
    _items[item.weekday]?.removeWhere((i) => i.id == item.id);
    notifyListeners();

    await _saveToPrefs();
    await _cancelNotification(item);

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('study_lessons')
            .doc(item.id)
            .delete();
      } catch (_) {}
    }
  }

  // ─── نسخ حصة إلى يوم آخر ────────────────────────────────────────────────
  Future<void> copyToDay(ScheduleItem item, int targetDay) async {
    final newItem = item.copyWith(
      weekday: targetDay,
    );
    final uniqueItem = ScheduleItem(
      id: '${item.id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      title: newItem.title,
      description: newItem.description,
      weekday: targetDay,
      startTime: newItem.startTime,
      endTime: newItem.endTime,
      color: newItem.color,
      teacher: newItem.teacher,
      room: newItem.room,
      period: newItem.period,
      iconName: newItem.iconName,
      isExam: newItem.isExam,
      isCancelled: false,
      notify: newItem.notify,
      notifyMinutesBefore: newItem.notifyMinutesBefore,
      secondaryNotifyMinutes: newItem.secondaryNotifyMinutes,
      recurrence: newItem.recurrence,
    );
    await addItem(uniqueItem);
  }

  // ─── نسخ حصص يوم إلى أيام أخرى ───────────────────────────────────────────
  Future<void> copyDaySessions(int fromDay, List<int> targetDays) async {
    final sourceItems = List<ScheduleItem>.from(_items[fromDay] ?? []);
    for (final day in targetDays) {
      for (final item in sourceItems) {
        await copyToDay(item, day);
      }
    }
  }

  // ─── تبديل وضع الإلغاء المؤقت للحصة ──────────────────────────────────────
  Future<void> toggleCancel(ScheduleItem item) async {
    final updated = item.copyWith(isCancelled: !item.isCancelled);
    await updateItem(item, updated);
  }

  // ─── تبديل وضع الاختبار ─────────────────────────────────────────────────
  Future<void> toggleExam(ScheduleItem item) async {
    final updated = item.copyWith(isExam: !item.isExam);
    await updateItem(item, updated);
  }

  // ─── تبديل وضع العطلة (تعطيل التنبيهات) ──────────────────────────────────
  Future<void> toggleVacationMode() async {
    _isVacationMode = !_isVacationMode;
    notifyListeners();
    await _saveToPrefs();

    if (_isVacationMode) {
      for (final dayItems in _items.values) {
        for (final item in dayItems) {
          await _cancelNotification(item);
        }
      }
    } else {
      await rescheduleAllNotifications();
    }
  }

  // ─── إدارة الواجبات والمهام ──────────────────────────────────────────────
  Future<void> addTask(ScheduleTask task) async {
    _tasks.add(task);
    notifyListeners();
    await _saveToPrefs();
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final old = _tasks[index];
      _tasks[index] = ScheduleTask(
        id: old.id,
        title: old.title,
        subjectName: old.subjectName,
        dueDate: old.dueDate,
        isCompleted: !old.isCompleted,
        note: old.note,
      );
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await _saveToPrefs();
  }

  // ─── إحصائيات عامة ──────────────────────────────────────────────────────
  int getTodaySessionsCount(int weekday) {
    return (_items[weekday] ?? []).where((i) => !i.isCancelled).length;
  }

  double getTodayHours(int weekday) {
    double hours = 0;
    for (final item in (_items[weekday] ?? [])) {
      if (item.isCancelled) continue;
      hours += item.durationMinutes / 60.0;
    }
    return hours;
  }

  int getTotalSessions() {
    int total = 0;
    for (final dayItems in _items.values) {
      total += dayItems.where((i) => !i.isCancelled).length;
    }
    return total;
  }

  double getTotalHours() {
    double hours = 0;
    for (final dayItems in _items.values) {
      for (final item in dayItems) {
        if (!item.isCancelled) {
          hours += item.durationMinutes / 60.0;
        }
      }
    }
    return hours;
  }

  int getActiveRemindersCount() {
    if (_isVacationMode) return 0;
    int count = 0;
    for (final dayItems in _items.values) {
      count += dayItems.where((i) => i.notify && !i.isCancelled).length;
    }
    return count;
  }

  // ─── التنبيهات المحلية ──────────────────────────────────────────────────
  Future<void> _scheduleNotification(ScheduleItem item) async {
    await NotificationService().scheduleSessionNotifications(item);
  }

  Future<void> _cancelNotification(ScheduleItem item) async {
    await NotificationService().cancelSessionNotifications(item.id);
  }

  Future<void> rescheduleAllNotifications() async {
    if (_isVacationMode) return;
    for (final dayItems in _items.values) {
      for (final item in dayItems) {
        if (item.notify && !item.isCancelled) {
          await _scheduleNotification(item);
        }
      }
    }
  }

  Future<void> toggleItemCompletion(
    ScheduleItem item,
    BuildContext context,
  ) async {
    final dayItems = _items[item.weekday];
    if (dayItems == null) return;

    final index = dayItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      final oldItem = dayItems[index];
      final newItem = oldItem.copyWith(isCompleted: !oldItem.isCompleted);
      dayItems[index] = newItem;

      notifyListeners();
      await _saveToPrefs();

      if (context.mounted) {
        final stats = Provider.of<StatisticsProvider>(context, listen: false);
        if (newItem.isCompleted) {
          stats.incrementUserStat('completedTasks', value: 1);
          try {
            final player = AudioPlayer();
            await player.play(AssetSource('sounds/success.mp3'));
          } catch (_) {}
        } else {
          stats.decrementUserStat('completedTasks', value: 1);
        }
      }
    }
  }
}
