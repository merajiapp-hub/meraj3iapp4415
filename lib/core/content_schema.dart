import 'package:cloud_firestore/cloud_firestore.dart';

String _normalizeText(dynamic value) => (value ?? '').toString().trim();

String _normalizeDriveUrl(String? rawUrl) {
  final value = (rawUrl ?? '').trim();
  if (value.isEmpty) return '';

  final fileId = RegExp(r'/file/d/([a-zA-Z0-9_-]+)|[?&]id=([a-zA-Z0-9_-]+)')
      .firstMatch(value)
      ?.group(1 ?? 2);

  if (fileId != null && fileId.isNotEmpty) {
    return 'https://drive.google.com/file/d/$fileId/view';
  }

  return value;
}

Map<String, dynamic> normalizeBookData({
  required String title,
  String? subject,
  String? stage,
  String? grade,
  String? category,
  String? url,
  String? uploaderId,
  bool isActive = true,
  bool isShared = false,
  Map<String, dynamic>? existing,
}) {
  final normalizedStage = _normalizeText(stage);
  final normalizedGrade = _normalizeText(grade);
  final normalizedCategory = _normalizeText(category);
  final normalizedSubject = _normalizeText(subject);
  final normalizedTitle = _normalizeText(title);
  final normalizedUrl = _normalizeDriveUrl(url);
  final fileId = RegExp(r'/file/d/([a-zA-Z0-9_-]+)|[?&]id=([a-zA-Z0-9_-]+)')
      .firstMatch(normalizedUrl)
      ?.group(1 ?? 2);

  return {
    'title': normalizedTitle,
    'name': normalizedTitle,
    'subject': normalizedSubject,
    'material': normalizedSubject,
    'section': normalizedStage,
    'stage': normalizedStage,
    'grade': normalizedGrade,
    'year': normalizedGrade,
    'category': normalizedCategory,
    'type': normalizedCategory,
    'bookType': normalizedCategory,
    'url': normalizedUrl,
    'drive_link': normalizedUrl,
    'pdfUrl': normalizedUrl,
    'driveUrl': normalizedUrl,
    'uploaderId': _normalizeText(uploaderId),
    'userId': _normalizeText(uploaderId),
    'is_active': isActive,
    'isActive': isActive,
    'isShared': isShared,
    'fileId': fileId ?? existing?['fileId'] ?? '',
    'driveId': fileId ?? existing?['driveId'] ?? '',
    'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
    'created_at': existing?['created_at'] ?? FieldValue.serverTimestamp(),
    'uploadDate': existing?['uploadDate'] ?? FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'openCount': existing?['openCount'] ?? 0,
  };
}

Map<String, dynamic> normalizeQuestionData({
  required String question,
  String? subject,
  String? stage,
  String? grade,
  List<String>? options,
  String? correctAnswer,
  bool isActive = true,
  Map<String, dynamic>? existing,
}) {
  final normalizedQuestion = _normalizeText(question);
  final normalizedSubject = _normalizeText(subject);
  final normalizedStage = _normalizeText(stage);
  final normalizedGrade = _normalizeText(grade);
  final normalizedOptions = (options ?? [])
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  final normalizedCorrect = _normalizeText(correctAnswer);

  return {
    'question': normalizedQuestion,
    'text': normalizedQuestion,
    'subject': normalizedSubject,
    'material': normalizedSubject,
    'section': normalizedStage,
    'stage': normalizedStage,
    'grade': normalizedGrade,
    'year': normalizedGrade,
    'options': normalizedOptions,
    'answers': normalizedOptions,
    'correctAnswer': normalizedCorrect,
    'correctAnswers': normalizedCorrect.isEmpty ? [] : [normalizedCorrect],
    'isActive': isActive,
    'is_active': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
    'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
  };
}

Map<String, dynamic> normalizeExamData({
  required String title,
  String? subject,
  String? stage,
  String? grade,
  int duration = 0,
  List<String>? questionIds,
  bool isActive = true,
  bool isPublished = true,
  Map<String, dynamic>? existing,
}) {
  final normalizedTitle = _normalizeText(title);
  final normalizedSubject = _normalizeText(subject);
  final normalizedStage = _normalizeText(stage);
  final normalizedGrade = _normalizeText(grade);

  return {
    'title': normalizedTitle,
    'subject': normalizedSubject,
    'material': normalizedSubject,
    'section': normalizedStage,
    'stage': normalizedStage,
    'grade': normalizedGrade,
    'year': normalizedGrade,
    'duration': duration,
    'questionIds': (questionIds ?? []).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    'questionCount': (questionIds ?? []).map((e) => e.trim()).where((e) => e.isNotEmpty).length,
    'isActive': isActive,
    'is_active': isActive,
    'isPublished': isPublished,
    'updatedAt': FieldValue.serverTimestamp(),
    'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
  };
}
