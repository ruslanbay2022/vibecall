import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'in_call_open_chat.g.dart';

@Riverpod(keepAlive: true)
class InCallOpenChat extends _$InCallOpenChat {
  @override
  String? build() => null;

  void set(String? conversationId) => state = conversationId;
}
