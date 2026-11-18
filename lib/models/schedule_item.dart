import 'dart:convert';
import 'package:flutter/material.dart';

/// نموذج بيانات الحصة الدراسية المطور لـ «جدولي الدراسي»
class ScheduleItem {
  final String id;
  final String title; // اسم المادة الدراسية
  final String description; // وصف أو ملاحظات
  final int weekday; // 1 = الاثنين, 7 = الأحد (السبت = 6, الأحد = 7, الجمعة = 5)
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  final String? teacher; // اسم الأستاذ
  final String? room; // القاعة أو المكان
  final String period; // 'morning' (الصباح) أو 'evening' (المساء)
  final String iconName; // أيقونة المادة (e.g. 'calculate', 'science', 'book', ...)
  final bool isExam; // هل هي حصة اختبار / امتحان
  final bool isCancelled; // هل تم إلغاؤها مؤقتاً
  final bool notify; // تفعيل التذكير
  final int notifyMinutesBefore; // مدة التذكير الأولى بالدقائق (مثلاً 15)
  final int? secondaryNotifyMinutes; // تذكير ثانٍ اختياري (مثلاً 5)
  final String recurrence; // 'weekly', 'once'
  final bool isCompleted;

  ScheduleItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.teacher,
    this.room,
    String? period,
    this.iconName = 'menu_book',
    this.isExam = false,
    this.isCancelled = false,
    this.notify = true,
    this.notifyMinutesBefore = 15,
    this.secondaryNotifyMinutes,
    this.recurrence = 'weekly',
    this.isCompleted = false,
  }) : period = period ?? (startTime.hour < 13 ? 'morning' : 'evening');

  /// هل الحصة صباحية
  bool get isMorning => period == 'morning';

  /// هل الحصة مسائية
  bool get isEvening => period == 'evening';

  /// حساب مدة الحصة بالدقائق
  int get durationMinutes {
    final start = startTime.hour * 60 + startTime.minute;
    final end = endTime.hour * 60 + endTime.minute;
    int diff = end - start;
    if (diff < 0) diff += 24 * 60;
    return diff;
  }

  /// نص منسق لمدة الحصة
  String get formattedDuration {
    final mins = durationMinutes;
    final hours = mins ~/ 60;
    final remMins = mins % 60;
    if (hours > 0 && remMins > 0) {
      return '$hours س و $remMins د';
    } else if (hours > 0) {
      return hours == 1 ? 'ساعة واحدة' : (hours == 2 ? 'ساعتان' : '$hours ساعات');
    } else {
      return '$remMins دقيقة';
    }
  }

  ScheduleItem copyWith({
    String? title,
    String? description,
    int? weekday,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color? color,
    String? teacher,
    String? room,
    String? period,
    String? iconName,
    bool? isExam,
    bool? isCancelled,
    bool? notify,
    int? notifyMinutesBefore,
    int? secondaryNotifyMinutes,
    String? recurrence,
    bool? isCompleted,
  }) {
    return ScheduleItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      period: period ?? this.period,
      iconName: iconName ?? this.iconName,
      isExam: isExam ?? this.isExam,
      isCancelled: isCancelled ?? this.isCancelled,
      notify: notify ?? this.notify,
      notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
      secondaryNotifyMinutes:
          secondaryNotifyMinutes ?? this.secondaryNotifyMinutes,
      recurrence: recurrence ?? this.recurrence,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'weekday': weekday,
      'startHour': startTime.hour,
      'startMinute': startTime.minute,
      'endHour': endTime.hour,
      'endMinute': endTime.minute,
      'color': color.toARGB32(),
      'teacher': teacher,
      'room': room,
      'period': period,
      'iconName': iconName,
      'isExam': isExam,
      'isCancelled': isCancelled,
      'notify': notify,
      'notifyMinutesBefore': notifyMinutesBefore,
      'secondaryNotifyMinutes': secondaryNotifyMinutes,
      'recurrence': recurrence,
      'isCompleted': isCompleted,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    final startH = (map['startHour'] as num?)?.toInt() ?? 8;
    final startM = (map['startMinute'] as num?)?.toInt() ?? 0;
    final endH = (map['endHour'] as num?)?.toInt() ?? 9;
    final endM = (map['endMinute'] as num?)?.toInt() ?? 0;

    return ScheduleItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      weekday: (map['weekday'] as num?)?.toInt() ?? 1,
      startTime: TimeOfDay(hour: startH, minute: startM),
      endTime: TimeOfDay(hour: endH, minute: endM),
      color: Color((map['color'] as num?)?.toInt() ?? 0xFF0D9488),
      teacher: map['teacher']?.toString(),
      room: map['room']?.toString(),
      period: map['period']?.toString() ?? (startH < 13 ? 'morning' : 'evening'),
      iconName: map['iconName']?.toString() ?? 'menu_book',
      isExam: map['isExam'] == true,
      isCancelled: map['isCancelled'] == true,
      notify: map['notify'] != false,
      notifyMinutesBefore: (map['notifyMinutesBefore'] as num?)?.toInt() ?? 15,
      secondaryNotifyMinutes: (map['secondaryNotifyMinutes'] as num?)?.toInt(),
      recurrence: map['recurrence']?.toString() ?? 'weekly',
      isCompleted: map['isCompleted'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleItem.fromJson(String source) =>
      ScheduleItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// نموذج الواجبات والمهام الدراسية المرتبطة بالجدول
class ScheduleTask {
  final String id;
  final String title;
  final String subjectName;
  final DateTime dueDate;
  final bool isCompleted;
  final String? note;

  const ScheduleTask({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.dueDate,
    this.isCompleted = false,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subjectName': subjectName,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'note': note,
    };
  }

  factory ScheduleTask.fromMap(Map<String, dynamic> map) {
    return ScheduleTask(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      dueDate: DateTime.tryParse(map['dueDate']?.toString() ?? '') ?? DateTime.now(),
      isCompleted: map['isCompleted'] == true,
      note: map['note']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleTask.fromJson(String source) =>
      ScheduleTask.fromMap(json.decode(source) as Map<String, dynamic>);
}
