import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';

class ChatNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const ChatNotificationListener({super.key, required this.child});

  @override
  ConsumerState<ChatNotificationListener> createState() =>
      _ChatNotificationListenerState();
}

class _ChatNotificationListenerState extends ConsumerState<ChatNotificationListener> {
  var _webAudioUnlocked = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(chatMessageSoundProvider);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _unlockWebAudioOnce(),
      child: widget.child,
    );
  }

  void _unlockWebAudioOnce() {
    if (_webAudioUnlocked) return;
    _webAudioUnlocked = true;
    unawaited(
      ref.read(chatMessageSoundProvider.notifier).unlockForNextSound(),
    );
  }
}
