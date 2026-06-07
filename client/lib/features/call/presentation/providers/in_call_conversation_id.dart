import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';

part 'in_call_conversation_id.g.dart';

@riverpod
class InCallConversationId extends _$InCallConversationId {
  @override
  Future<String?> build() async {
    final callState = ref.watch(callControllerProvider);
    if (callState is! CallStateActive) return null;

    final peerUserId = callState.peerUserId;
    if (peerUserId.isEmpty) return null;

    final repo = ref.read(chatRepositoryProvider);
    return repo.ensureConversation(peerUserId);
  }
}
