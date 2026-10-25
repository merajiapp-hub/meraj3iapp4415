class AnnouncementData {
  static bool isActive(Map<String, dynamic> data) {
    final value = data['isActive'] ?? data['is_active'];
    return value == null || value == true;
  }

  static String body(Map<String, dynamic> data, {String fallback = ''}) {
    final body = data['body']?.toString();
    if (body != null && body.trim().isNotEmpty) return body;
    final message = data['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message;
    return fallback;
  }
}
