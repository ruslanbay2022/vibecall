import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibecall/features/call/platform/web_audio_unlock.dart';
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
  _playChain = _playChain
      .catchError((Object e, StackTrace st) {
        debugPrint('chat message sound chain error: $e\n$st');
      })
      .then((_) => _playOnce());
  return _playChain;
}

Future<void> _playOnce() async {
  await ensureChatMessageSoundLoaded();
  final bytes = _wavBytes;
  if (bytes == null) return;

  web.HTMLAudioElement? audio;
  String? objectUrl;

  try {
    await unlockWebAudio();

    final blob = web.Blob(
      <web.BlobPart>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/wav'),
    );
    objectUrl = web.URL.createObjectURL(blob);
    audio = web.HTMLAudioElement()
      ..volume = 0.7
      ..src = objectUrl;

    audio.load();
    await audio.play().toDart;
  } catch (e, stackTrace) {
    debugPrint('chat message sound web play failed: $e\n$stackTrace');
  } finally {
    audio?.pause();
    if (audio != null) {
      audio.src = '';
    }
    if (objectUrl != null) {
      web.URL.revokeObjectURL(objectUrl);
    }
  }
}

Future<void> disposeChatMessageSoundPlayer() async {
  _wavBytes = null;
  _loadFuture = null;
}
