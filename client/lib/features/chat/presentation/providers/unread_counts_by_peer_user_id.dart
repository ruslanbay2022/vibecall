import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_notification_logic.dart';
import 'package:vibecall/features/chat/presentation/providers/conversations_controller.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

part 'unread_counts_by_peer_user_id.g.dart';

@riverpod
Map<String, int> unreadCountsByPeerUserId(Ref ref) {
  final unreadByConversation =
      ref.watch(unreadCountsControllerProvider).value ?? {};
  final conversations =
      ref.watch(conversationsControllerProvider).value ?? [];
  final activeConversationId = ref.watch(activeChatConversationProvider);

  return mapUnreadCountsByPeerUserId(
    unreadByConversationId: unreadByConversation,
    conversations: conversations,
    activeConversationId: activeConversationId,
  );
}
