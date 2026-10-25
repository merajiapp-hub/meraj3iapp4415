import 'package:flutter_test/flutter_test.dart';
import 'package:meraj3i/models/support_chat_state.dart';

void main() {
  test('a user message unread by admins is not shown as an admin reply', () {
    expect(
      SupportChatState.unreadRepliesForUser({
        'adminUnread': 1,
        'userUnread': 0,
      }),
      0,
    );
  });

  test('an actual admin reply unread by the user is shown', () {
    expect(
      SupportChatState.unreadRepliesForUser({
        'adminUnread': 0,
        'userUnread': 2,
      }),
      2,
    );
  });

  test('missing user reply state is treated as no unread replies', () {
    expect(SupportChatState.unreadRepliesForUser(null), 0);
  });
}
