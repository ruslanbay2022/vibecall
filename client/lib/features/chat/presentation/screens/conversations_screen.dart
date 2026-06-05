import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/chat/domain/conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/active_chat_conversation.dart';
import 'package:vibecall/features/chat/presentation/providers/chat_message_sound.dart';
import 'package:vibecall/features/chat/presentation/providers/conversations_controller.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_controller.dart';
import 'package:vibecall/features/presence/presentation/providers/presence_controller.dart';
import 'package:vibecall/features/presence/presentation/widgets/online_indicator.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncConversations = ref.watch(conversationsControllerProvider);
    final onlineUserIds = ref.watch(presenceControllerProvider);
    final asyncUnreadCounts = ref.watch(unreadCountsControllerProvider);
    final unreadCounts = asyncUnreadCounts.value ?? {};
    final activeConversationId = ref.watch(activeChatConversationProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatsTitle)),
      body: asyncConversations.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(child: Text(l10n.chatNoConversations));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(conversationsControllerProvider.notifier).refresh();
              await ref.read(unreadCountsControllerProvider.notifier).refresh();
            },
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, _) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final rawCount = unreadCounts[conv.id] ?? conv.unreadCount;
                final displayCount =
                    activeConversationId == conv.id ? 0 : rawCount;
                return _ConversationTile(
                  conversation: conv,
                  isOnline: onlineUserIds.contains(conv.peer.id),
                  unreadCount: displayCount,
                  l10n: l10n,
                  onOpen: () {
                    ref
                        .read(chatMessageSoundProvider.notifier)
                        .unlockForNextSound();
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isOnline;
  final int unreadCount;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  const _ConversationTile({
    required this.conversation,
    required this.isOnline,
    required this.unreadCount,
    required this.l10n,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final peer = conversation.peer;
    final name = peer.displayName ?? peer.username ?? peer.id;
    final timeText = _formatTime(context, conversation.lastMessageAt);
    final theme = Theme.of(context);

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          peer.avatarUrl != null
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(peer.avatarUrl!),
                )
              : const CircleAvatar(child: Icon(Icons.person)),
          Positioned(
            bottom: -2,
            right: -2,
            child: OnlineIndicator(isOnline: isOnline),
          ),
        ],
      ),
      title: Text(
        name,
        style: unreadCount > 0
            ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: conversation.lastMessageBody != null
          ? Text(
              conversation.lastMessageBody!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: unreadCount > 0
                  ? const TextStyle(fontWeight: FontWeight.w600)
                  : null,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeText,
            style: theme.textTheme.bodySmall,
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Semantics(
              label: l10n.chatUnreadBadge(unreadCount),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        onOpen();
        context.push(
          '/chat/${conversation.id}',
          extra: {'peerName': name, 'peerAvatarUrl': peer.avatarUrl},
        );
      },
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return '${two(local.hour)}:${two(local.minute)}';
    }
    return '${two(local.day)}.${two(local.month)}.${local.year}';
  }
}
