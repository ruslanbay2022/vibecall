import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.AudioContext? _sharedContext;

/// Resume a shared Web [AudioContext] inside a user-gesture handler so later
/// notification sounds are not blocked by autoplay policy.
Future<void> unlockWebAudio() async {
  _sharedContext ??= web.AudioContext();
  if (_sharedContext!.state == 'suspended') {
    await _sharedContext!.resume().toDart;
  }
}
