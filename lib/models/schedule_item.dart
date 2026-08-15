import 'dart:convert';
import 'package:flutter/material.dart';

class ScheduleItem {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final bool isCompleted;
  final bool notify;
  final bool isWeekly;
  final String? teacher;
  final String? room;
  final int notifyMinutesBefore;

  ScheduleItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCompleted = false,
    this.notify = true,
    this.isWeekly = false,
    this.teacher,
    this.room,
    this.notifyMinutesBefore = 10,
  });

  ScheduleItem copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    bool? isCompleted,
    bool? notify,
    bool? isWeekly,
    String? teacher,
    String? room,
    int? notifyMinutesBefore,
  }) {
    return ScheduleItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      notify: notify ?? this.notify,
      isWeekly: isWeekly ?? this.isWeekly,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      notifyMinutesBefore: notifyMinutesBefore ?? this.notifyMinutesBefore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'color': color.toARGB32(),
      'isCompleted': isCompleted,
      'notify': notify,
      'isWeekly': isWeekly,
      'teacher': teacher,
      'room': room,
      'notifyMinutesBefore': notifyMinutesBefore,
    };
  }

  factory ScheduleItem.fromMap(Map<String, dynamic> map) {
    return ScheduleItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      color: Color(map['color'] ?? 0xFF13A286),
      isCompleted: map['isCompleted'] ?? false,
      notify: map['notify'] ?? true,
      isWeekly: map['isWeekly'] ?? false,
      teacher: map['teacher'],
      room: map['room'],
      notifyMinutesBefore: map['notifyMinutesBefore'] ?? 10,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScheduleItem.fromJson(String source) =>
      ScheduleItem.fromMap(json.decode(source));
}
