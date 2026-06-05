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
  StreamSubscription<Message>? _subscription;
  var _listening = false;

  @override
  void build() {
    ref.watch(chatRepositoryProvider);

    if (!_listening) {
      _listening = true;
      final repo = ref.read(chatRepositoryProvider);
      _subscription = repo.globalIncomingMessageStream().listen(
        _onIncomingMessage,
        onError: (error, stackTrace) {
          debugPrint('chat message sound stream error: $error\n$stackTrace');
        },
      );
    }

    ref.onDispose(() {
      _listening = false;
      _subscription?.cancel();
      _subscription = null;
      unawaited(_session.dispose());
    });
  }

  void _onIncomingMessage(Message message) {
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
  bool _playing = false;

  Future<void> play() async {
    if (_playing) {
      try {
        await _player?.stop();
      } catch (_) {}
    }
    _playing = true;
    try {
      if (kIsWeb) {
        await AudioCache.instance.clear(_messageSoundAsset);
      }
      final player = await _ensurePlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.7);
      await player.play(AssetSource(_messageSoundAsset));
    } catch (e, stackTrace) {
      debugPrint('chat message sound failed: $e\n$stackTrace');
      if (kIsWeb) {
        await _resetPlayer();
      }
    } finally {
      _playing = false;
    }
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;

    final player = AudioPlayer();
    _player = player;
    return player;
  }

  Future<void> _resetPlayer() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  Future<void> dispose() async {
    await _resetPlayer();
  }
}
