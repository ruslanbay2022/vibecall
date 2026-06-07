import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_chat_conversation.g.dart';

@Riverpod(keepAlive: true)
class ActiveChatConversation extends _$ActiveChatConversation {
  @override
  String? build() => null;

  void set(String? conversationId) => state = conversationId;
}
