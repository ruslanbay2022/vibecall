import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/platform/web_audio_unlock.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_notification_logic.dart';

part 'chat_message_sound.g.dart';

const _messageSoundAsset = 'sounds/message_notification.wav';
const _recentIdsCapacity = 50;

@Riverpod(keepAlive: true)
class ChatMessageSound extends _$ChatMessageSound {
  AudioPlayer? _player;
  final LinkedHashSet<String> _recentMessageIds = LinkedHashSet<String>();
  StreamSubscription? _subscription;

  @override
  void build() {
    final repo = ref.watch(chatRepositoryProvider);
    final activeConvId = ref.watch(activeChatConversationProvider);

    _subscription?.cancel();
    _subscription = repo.globalIncomingMessageStream().listen(
      (message) async {
        final currentUserId = repo.currentUserId;
        final shouldPlay = shouldPlayMessageSound(
          senderId: message.senderId,
          currentUserId: currentUserId,
          conversationId: message.conversationId,
          activeConversationId: activeConvId,
          messageId: message.id,
          recentMessageIds: _recentMessageIds,
          readAt: message.readAt,
        );

        if (shouldPlay) {
          _addToRecent(message.id);
          await _playSound();
        }
      },
      onError: (_) {},
    );

    ref.onDispose(() {
      _subscription?.cancel();
      _player?.dispose();
    });
  }

  void _addToRecent(String messageId) {
    _recentMessageIds.add(messageId);
    while (_recentMessageIds.length > _recentIdsCapacity) {
      _recentMessageIds.remove(_recentMessageIds.first);
    }
  }

  Future<void> _playSound() async {
    try {
      if (kIsWeb) {
        await AudioCache.instance.clear(_messageSoundAsset);
      }
      _player ??= AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.release);
      await _player!.setVolume(0.7);
      await _player!.play(AssetSource(_messageSoundAsset));
    } catch (e, stackTrace) {
      debugPrint('chat message sound failed: $e\n$stackTrace');
    }
  }

  Future<void> unlockForNextSound() => unlockWebAudio();
}
