import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/platform/web_audio_unlock.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/platform/chat_message_sound_player.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_notification_logic.dart';
import 'package:vibecall/features/chat/presentation/providers/in_call_open_chat.dart';

part 'chat_message_sound.g.dart';

const _recentIdsCapacity = 50;

@Riverpod(keepAlive: true)
class ChatMessageSound extends _$ChatMessageSound {
  final LinkedHashSet<String> _recentMessageIds = LinkedHashSet<String>();

  @override
  void build() {
    ref.watch(chatRepositoryProvider);
    unawaited(ensureChatMessageSoundLoaded());
    ref.onDispose(() {
      unawaited(disposeChatMessageSoundPlayer());
    });
  }

  void onIncomingMessage(Message message) {
    try {
      if (!ref.mounted) return;

      final repo = ref.read(chatRepositoryProvider);
      final inCallId = ref.read(inCallOpenChatProvider);

      final shouldPlay = shouldPlayMessageSound(
        senderId: message.senderId,
        currentUserId: repo.currentUserId,
        messageId: message.id,
        recentMessageIds: _recentMessageIds,
        readAt: message.readAt,
        inCallConversationId: inCallId,
        messageConversationId: message.conversationId,
      );

      if (!shouldPlay) return;

      unawaited(_playAndRemember(message.id));
    } catch (e, stackTrace) {
      debugPrint('chat message sound handler failed: $e\n$stackTrace');
    }
  }

  Future<void> _playAndRemember(String messageId) async {
    try {
      await playChatMessageSound();
      _addToRecent(messageId);
    } catch (e, stackTrace) {
      debugPrint('chat message sound failed: $e\n$stackTrace');
    }
  }

  void _addToRecent(String messageId) {
    _recentMessageIds.add(messageId);
    while (_recentMessageIds.length > _recentIdsCapacity) {
      _recentMessageIds.remove(_recentMessageIds.first);
    }
  }

  Future<void> unlockForNextSound() => unlockWebAudio();
}
