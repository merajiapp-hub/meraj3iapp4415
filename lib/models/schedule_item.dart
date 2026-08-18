import 'dart:convert';
import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String title;
  final String description;
  final int weekday; // 1 = Monday, 7 = Sunday
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final Color color;
  final String? teacher;
  final String? room;
  final bool notify;
  final int notifyMinutesBefore;

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
    this.notify = true,
    this.notifyMinutesBefore = 10,
  });

  ScheduleItem copyWith({
    String? title,
    String? description,
    int? weekday,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    Color? color,
    String? teacher,
    String? room,
    bool? notify,
    int? notifyMinutesBefore,
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
      notify: notify ?? this.notify,
      notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
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
      'notify': notify,
      'notifyMinutesBefore': notifyMinutesBefore,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      weekday: map['weekday'] ?? 1,
      startTime: TimeOfDay(hour: map['startHour'] ?? 8, minute: map['startMinute'] ?? 0),
      endTime: TimeOfDay(hour: map['endHour'] ?? 9, minute: map['endMinute'] ?? 0),
      color: Color(map['color'] ?? 0xFF13A286),
      teacher: map['teacher'],
      room: map['room'],
      notify: map['notify'] ?? true,
      notifyMinutesBefore: map['notifyMinutesBefore'] ?? 10,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleItem.fromJson(String source) => ScheduleItem.fromMap(json.decode(source));
}
