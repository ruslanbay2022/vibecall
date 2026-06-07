import 'package:vibecall/app/router.dart';

/// In-call chat is only considered open while the active call route is visible.
String? inCallOpenChatConversationIdAtNotifyTime(String? openConversationId) {
  if (router.state.matchedLocation != '/call') return null;
  return openConversationId;
}
