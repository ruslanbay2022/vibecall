import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Resume a Web [AudioContext] inside a user-gesture handler so later
/// [AudioPlayer.play] calls are not blocked by autoplay policy.
Future<void> unlockWebAudio() async {
  final ctx = web.AudioContext();
  if (ctx.state == 'suspended') {
    await ctx.resume().toDart;
  }
  await ctx.close().toDart;
}
