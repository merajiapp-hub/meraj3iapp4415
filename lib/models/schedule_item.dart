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

  ScheduleItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.color,
    this.isCompleted = false,
    this.notify = true,
  });

  ScheduleItem copyWith({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    bool? isCompleted,
    bool? notify,
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
    );
  }
}
