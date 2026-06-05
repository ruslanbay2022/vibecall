import 'package:vibecall/app/router.dart';

/// Current open chat from [GoRouter], without provider/microtask lag.
String? activeChatConversationIdFromRoute() {
  final location = router.state.matchedLocation;
  if (!location.startsWith('/chat/')) return null;
  return router.state.pathParameters['conversationId'];
}
