import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';

part 'incoming_ringtone.g.dart';

const _ringAsset = 'sounds/incoming_ring.wav';

/// Plays looped ringtone while [CallStateIncoming] is active.
@Riverpod(keepAlive: true)
void incomingRingtone(Ref ref) {
  final player = AudioPlayer()..setReleaseMode(ReleaseMode.loop);

  ref.onDispose(() async {
    await player.stop();
    await player.dispose();
  });

  ref.listen(callControllerProvider, (previous, next) {
    if (next is CallStateIncoming) {
      unawaited(_playRing(player));
    } else if (previous is CallStateIncoming) {
      unawaited(player.stop());
    }
  });
}

Future<void> _playRing(AudioPlayer player) async {
  try {
    await player.stop();
    await player.play(AssetSource(_ringAsset));
  } catch (_) {
    // Web autoplay may block until user gesture; overlay still works.
  }
}
