import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';

class ChatNotificationListener extends ConsumerWidget {
  final Widget child;

  const ChatNotificationListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(chatMessageSoundProvider);
    return child;
  }
}
