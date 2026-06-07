import 'package:audioplayers/audioplayers.dart';

final _source = AssetSource('sounds/message_notification.wav');

AudioPlayer? _player;

Future<void> ensureChatMessageSoundLoaded() async {}

Future<void> playChatMessageSound() async {
  final player = _player ??= AudioPlayer();
  await player.stop();
  await player.setReleaseMode(ReleaseMode.stop);
  await player.setVolume(0.7);
  await player.play(_source);
}

Future<void> disposeChatMessageSoundPlayer() async {
  final player = _player;
  _player = null;
  if (player == null) return;
  try {
    await player.dispose();
  } catch (_) {}
}
