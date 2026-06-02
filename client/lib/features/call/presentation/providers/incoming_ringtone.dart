import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/platform/web_audio_unlock.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';

part 'incoming_ringtone.g.dart';

const _ringAsset = 'sounds/incoming_ring.wav';

/// Plays looped ringtone while [CallStateIncoming] is active.
@Riverpod(keepAlive: true)
class IncomingRingtone extends _$IncomingRingtone {
  final _session = _RingtoneSession();

  @override
  void build() {
    ref.onDispose(_session.dispose);

    ref.listen(callControllerProvider, (previous, next) {
      if (next is CallStateIncoming) {
        unawaited(_session.start());
      } else if (previous is CallStateIncoming) {
        unawaited(_session.stop());
      }
    });
  }

  /// Call from a button handler (user gesture) to allow the next ring on Web.
  Future<void> unlockForNextRing() => unlockWebAudio();
}

class _RingtoneSession {
  AudioPlayer? _player;
  bool _starting = false;

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;

    final player = AudioPlayer();
    _player = player;
    await player.setReleaseMode(ReleaseMode.loop);
    return player;
  }

  Future<void> start() async {
    if (_starting) return;
    _starting = true;
    try {
      // audioplayers 6.x calls File.existsSync on cache hits — crashes on Web.
      if (kIsWeb) {
        await AudioCache.instance.clear(_ringAsset);
      }
      final player = await _ensurePlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(1);
      await player.play(AssetSource(_ringAsset));
    } catch (e, stackTrace) {
      debugPrint('incoming ringtone start failed: $e\n$stackTrace');
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e, stackTrace) {
      debugPrint('incoming ringtone stop failed: $e\n$stackTrace');
    }
  }

  Future<void> dispose() async {
    final player = _player;
    _player = null;
    if (player == null) return;
    try {
      await player.dispose();
    } catch (_) {}
  }
}
