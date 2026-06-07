import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';

part 'total_unread_chat_count.g.dart';

@riverpod
int totalUnreadChatCount(Ref ref) {
  final counts = ref.watch(unreadCountsControllerProvider).value ?? {};
  return counts.values.fold<int>(0, (sum, count) => sum + count);
}
