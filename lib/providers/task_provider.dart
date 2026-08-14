import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/notification_service.dart';

class StudyTask {
  final String id;
  final String title;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  bool isCompleted;
  final int notificationId;

  StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.startTime,
    required this.endTime,
    this.isCompleted = false,
    required this.notificationId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'isCompleted': isCompleted,
    'notificationId': notificationId,
  };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
    id: json['id'],
    title: json['title'],
    subject: json['subject'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    isCompleted: json['isCompleted'] ?? false,
    notificationId: json['notificationId'] ?? 0,
  );
}

class TaskProvider extends ChangeNotifier {
  List<StudyTask> _tasks = [];
  List<StudyTask> get tasks => _tasks;

  final List<String> subjects = [
    'اللغة العربية',
    'اللغة الفرنسية',
    'اللغة الإنجليزية',
    'الرياضيات',
    'العلوم الطبيعية',
    'التربية الإسلامية',
    'التربية المدنية',
    'التاريخ',
    'الجغرافيا',
    'الفيزياء',
    'الفلسفة',
    'أخرى',
  ];

  int _nextNotifId = 1000;

  TaskProvider() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('study_tasks');
    final savedId = prefs.getInt('next_notif_id');
    if (savedId != null) _nextNotifId = savedId;
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      _tasks = decoded.map((e) => StudyTask.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await prefs.setString('study_tasks', encoded);
    await prefs.setInt('next_notif_id', _nextNotifId);
  }

  Future<void> addTask(StudyTask task) async {
    _tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();

    // جدولة إشعار عند انتهاء وقت المهمة
    final studyReminders = await _areStudyRemindersEnabled();
    if (studyReminders && task.endTime.isAfter(DateTime.now())) {
      await NotificationService().scheduleNotification(
        id: task.notificationId,
        title: '⏰ انتهى وقت المهمة',
        body: '${task.title} — ${task.subject}',
        scheduledDate: task.endTime,
      );
    }
  }

  Future<void> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _saveTasks();
      notifyListeners();

      // إرسال إشعار فوري عند إتمام المهمة
      if (_tasks[index].isCompleted) {
        final task = _tasks[index];
        await NotificationService().cancelNotification(task.notificationId);
        final studyReminders = await _areStudyRemindersEnabled();
        if (studyReminders) {
          await NotificationService().showInstantNotification(
            id: task.notificationId + 9000,
            title: '✅ أنجزت مهمتك!',
            body: '${task.title} — ${task.subject}، عمل رائع! 💪',
          );
        }
      }
    }
  }

  Future<void> deleteTask(String id) async {
    final task = _tasks.firstWhere(
      (t) => t.id == id,
      orElse: () => StudyTask(
        id: '',
        title: '',
        subject: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        notificationId: -1,
      ),
    );
    if (task.id.isNotEmpty) {
      await NotificationService().cancelNotification(task.notificationId);
    }
    _tasks.removeWhere((t) => t.id == id);
    await _saveTasks();
    notifyListeners();
  }

  int getNextNotifId() {
    return _nextNotifId++;
  }

  Future<bool> _areStudyRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_study_reminders') ?? true;
  }

  void clearAll() {
    for (var task in _tasks) {
      if (task.id.isNotEmpty) {
        NotificationService().cancelNotification(task.notificationId);
      }
    }
    _tasks.clear();
    notifyListeners();
  }
}
