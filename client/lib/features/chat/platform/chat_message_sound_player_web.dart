import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibecall/features/call/platform/web_audio_unlock.dart';
import 'package:web/web.dart' as web;

const _assetPath = 'assets/sounds/message_notification.wav';

Uint8List? _wavBytes;
Future<void>? _loadFuture;
web.HTMLAudioElement? _audioElement;
String? _objectUrl;

Future<void> ensureChatMessageSoundLoaded() {
  return _loadFuture ??= _loadBytes();
}

Future<void> _loadBytes() async {
  final data = await rootBundle.load(_assetPath);
  _wavBytes = data.buffer.asUint8List();
}

Future<void> playChatMessageSound() async {
  await ensureChatMessageSoundLoaded();
  final bytes = _wavBytes;
  if (bytes == null) return;

  try {
    await unlockWebAudio();

    final blob = web.Blob(
      <web.BlobPart>[bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/wav'),
    );
    final nextUrl = web.URL.createObjectURL(blob);
    final audio = _audioElement ??= web.HTMLAudioElement();

    final previousUrl = _objectUrl;
    _objectUrl = nextUrl;

    audio.pause();
    audio.currentTime = 0;
    audio.volume = 0.7;
    audio.src = nextUrl;
    audio.load();

    await audio.play().toDart;

    if (previousUrl != null) {
      web.URL.revokeObjectURL(previousUrl);
    }
  } catch (e, stackTrace) {
    debugPrint('chat message sound web play failed: $e\n$stackTrace');
    rethrow;
  }
}

Future<void> disposeChatMessageSoundPlayer() async {
  final audio = _audioElement;
  _audioElement = null;
  if (audio != null) {
    audio.pause();
    audio.src = '';
  }
  final url = _objectUrl;
  _objectUrl = null;
  if (url != null) {
    web.URL.revokeObjectURL(url);
  }
  _wavBytes = null;
  _loadFuture = null;
}
