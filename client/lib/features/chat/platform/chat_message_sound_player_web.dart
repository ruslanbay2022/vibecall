import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

const _assetPath = 'assets/sounds/message_notification.wav';

Uint8List? _wavBytes;
Future<void>? _loadFuture;
Future<void> _playChain = Future<void>.value();

Future<void> ensureChatMessageSoundLoaded() {
  return _loadFuture ??= _loadBytes();
}

Future<void> _loadBytes() async {
  final data = await rootBundle.load(_assetPath);
  _wavBytes = data.buffer.asUint8List();
}

Future<void> playChatMessageSound() {
  _playChain = _playChain.then((_) => _playOnce());
  return _playChain;
}

Future<void> _playOnce() async {
  await ensureChatMessageSoundLoaded();
  final bytes = _wavBytes;
  if (bytes == null) return;

  final blob = web.Blob(
    <web.BlobPart>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'audio/wav'),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final audio = web.HTMLAudioElement();

  try {
    audio.src = objectUrl;
    audio.volume = 0.7;
    await audio.play().toDart;
    await Future<void>.delayed(const Duration(milliseconds: 320));
  } finally {
    audio.pause();
    audio.src = '';
    web.URL.revokeObjectURL(objectUrl);
  }
}

Future<void> disposeChatMessageSoundPlayer() async {
  _wavBytes = null;
  _loadFuture = null;
}
