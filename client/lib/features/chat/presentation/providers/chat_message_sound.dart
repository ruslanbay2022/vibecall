import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/platform/web_audio_unlock.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/domain/message.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_notification_logic.dart';

part 'chat_message_sound.g.dart';

const _messageSoundAsset = 'sounds/message_notification.wav';
const _recentIdsCapacity = 50;

@Riverpod(keepAlive: true)
class ChatMessageSound extends _$ChatMessageSound {
  final _session = _MessageSoundSession();
  final LinkedHashSet<String> _recentMessageIds = LinkedHashSet<String>();

  @override
  void build() {
    ref.watch(chatRepositoryProvider);
    ref.onDispose(() {
      unawaited(_session.dispose());
    });
  }

  void onIncomingMessage(Message message) {
    try {
      if (!ref.mounted) return;

      final repo = ref.read(chatRepositoryProvider);
      final activeConvId = ref.read(activeChatConversationProvider);
      final shouldPlay = shouldPlayMessageSound(
        senderId: message.senderId,
        currentUserId: repo.currentUserId,
        conversationId: message.conversationId,
        activeConversationId: activeConvId,
        messageId: message.id,
        recentMessageIds: _recentMessageIds,
        readAt: message.readAt,
      );

      if (!shouldPlay) return;

      _addToRecent(message.id);
      unawaited(_session.play());
    } catch (e, stackTrace) {
      debugPrint('chat message sound handler failed: $e\n$stackTrace');
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

class _MessageSoundSession {
  AudioPlayer? _player;
  Future<void> _playChain = Future<void>.value();

  Future<void> play() {
    _playChain = _playChain.then((_) => _playOnce());
    return _playChain;
  }

  Future<void> _playOnce() async {
    try {
      if (kIsWeb) {
        await AudioCache.instance.clear(_messageSoundAsset);
      }

      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.7);
      await player.play(AssetSource(_messageSoundAsset));

      if (kIsWeb) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      } else {
        try {
          await player.onPlayerComplete.first
              .timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
    } catch (e, stackTrace) {
      debugPrint('chat message sound failed: $e\n$stackTrace');
      if (kIsWeb) {
        try {
          await _player?.dispose();
        } catch (_) {}
        _player = null;
      }
    }
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
