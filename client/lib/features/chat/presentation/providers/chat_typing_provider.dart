import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/data/chat_typing.dart';

part 'chat_typing_provider.g.dart';

@Riverpod(keepAlive: true)
ChatTyping chatTyping(Ref ref) => SupabaseChatTyping();
