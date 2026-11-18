import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CountdownEvent {
  const CountdownEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.targetDate,
    this.timezone = 'GMT',
    required this.cardColor,
    required this.iconName,
    this.isActive = true,
    required this.dueMessage,
    required this.endMessage,
    this.showEndMessage = true,
    this.autoHide = false,
    this.hideAfterDays = 7,
    this.order = 0,
  });

  final String id;
  final String title;
  final String type; // 'vacation', 'exam', 'competition'
  final String description;
  final DateTime targetDate;
  final String timezone;
  final String cardColor;
  final String iconName;
  final bool isActive;
  final String dueMessage;
  final String endMessage;
  final bool showEndMessage;
  final bool autoHide;
  final int hideAfterDays;
  final int order;

  factory CountdownEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CountdownEvent(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      type: data['type']?.toString() ?? 'exam',
      description: data['description']?.toString() ?? '',
      targetDate: parseDate(data['targetDate']),
      timezone: data['timezone']?.toString() ?? 'GMT',
      cardColor: data['cardColor']?.toString() ?? '#0F766E',
      iconName: data['iconName']?.toString() ?? 'school',
      isActive: data['isActive'] != false,
      dueMessage: data['dueMessage']?.toString() ?? 'حان الموعد! بالتوفيق لجميع المشاركين',
      endMessage: data['endMessage']?.toString() ?? 'انتهى الموعد، نتمنى التوفيق والنجاح للجميع',
      showEndMessage: data['showEndMessage'] != false,
      autoHide: data['autoHide'] == true,
      hideAfterDays: (data['hideAfterDays'] as num?)?.toInt() ?? 7,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Color get parsedColor {
    try {
      final hex = cardColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        return Color(int.parse('0x$hex'));
      }
    } catch (_) {}
    return const Color(0xFF0F766E);
  }

  IconData get iconData {
    switch (iconName) {
      case 'beach_access':
        return Icons.beach_access_rounded;
      case 'wb_sunny':
        return Icons.wb_sunny_rounded;
      case 'pool':
        return Icons.pool_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'history_edu':
        return Icons.history_edu_rounded;
      case 'engineering':
        return Icons.engineering_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'edit_note':
        return Icons.edit_note_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'timer':
        return Icons.timer_rounded;
      default:
        return type == 'vacation' ? Icons.beach_access_rounded : Icons.school_rounded;
    }
  }

  Duration get remainingDuration {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = targetDate.toUtc();
    return targetUtc.difference(nowUtc);
  }

  bool get isDueToday {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = targetDate.toUtc();
    return nowUtc.year == targetUtc.year &&
        nowUtc.month == targetUtc.month &&
        nowUtc.day == targetUtc.day;
  }

  bool get isEnded {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = targetDate.toUtc();
    return nowUtc.isAfter(targetUtc) && !isDueToday;
  }

  bool get isUpcoming {
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = targetDate.toUtc();
    return nowUtc.isBefore(targetUtc) && !isDueToday;
  }

  bool get shouldHide {
    if (!autoHide || !isEnded) return false;
    final nowUtc = DateTime.now().toUtc();
    final targetUtc = targetDate.toUtc();
    final diffDays = nowUtc.difference(targetUtc).inDays;
    return diffDays >= hideAfterDays;
  }
}
