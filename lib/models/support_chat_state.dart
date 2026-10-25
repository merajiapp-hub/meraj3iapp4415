class SupportChatState {
  const SupportChatState._();

  static int unreadRepliesForUser(Map<String, dynamic>? chat) {
    final unread = chat?['userUnread'];
    return unread is num ? unread.toInt() : 0;
  }
}
