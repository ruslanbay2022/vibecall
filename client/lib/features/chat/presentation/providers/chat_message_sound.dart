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
  String? _activeConversationId;
  var _listening = false;

  @override
  void build() {
    ref.watch(chatRepositoryProvider);

    ref.listen(activeChatConversationProvider, (_, next) {
      _activeConversationId = next;
    });
    _activeConversationId = ref.read(activeChatConversationProvider);

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
    try {
      if (!ref.mounted) return;

      final repo = ref.read(chatRepositoryProvider);
      final shouldPlay = shouldPlayMessageSound(
        senderId: message.senderId,
        currentUserId: repo.currentUserId,
        conversationId: message.conversationId,
        activeConversationId: _activeConversationId,
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
  Future<void> play() async {
    try {
      if (kIsWeb) {
        await AudioCache.instance.clear(_messageSoundAsset);
      }

      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.7);
      await player.play(AssetSource(_messageSoundAsset));

      if (kIsWeb) {
        unawaited(_disposeAfterDelay(player));
      } else {
        unawaited(_disposeAfterComplete(player));
      }
    } catch (e, stackTrace) {
      debugPrint('chat message sound failed: $e\n$stackTrace');
    }
  }

  Future<void> _disposeAfterDelay(AudioPlayer player) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    try {
      await player.dispose();
    } catch (_) {}
  }

  Future<void> _disposeAfterComplete(AudioPlayer player) async {
    try {
      await player.onPlayerComplete.first
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  Future<void> dispose() async {}
}
