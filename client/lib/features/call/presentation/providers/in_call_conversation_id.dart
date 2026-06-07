import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';

part 'in_call_conversation_id.g.dart';

@Riverpod(keepAlive: true)
class InCallConversationId extends _$InCallConversationId {
  String? _cachedPeerUserId;
  String? _cachedConversationId;

  @override
  Future<String?> build() async {
    final callState = ref.watch(callControllerProvider);
    final peerUserId =
        callState is CallStateActive ? callState.peerUserId : null;

    if (peerUserId == null || peerUserId.isEmpty) {
      _cachedPeerUserId = null;
      _cachedConversationId = null;
      return null;
    }

    if (_cachedPeerUserId == peerUserId && _cachedConversationId != null) {
      return _cachedConversationId;
    }

    final conversationId = await ref
        .read(chatRepositoryProvider)
        .ensureConversation(peerUserId);
    _cachedPeerUserId = peerUserId;
    _cachedConversationId = conversationId;
    return conversationId;
  }
}
