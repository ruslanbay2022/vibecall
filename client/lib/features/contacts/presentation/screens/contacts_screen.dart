import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/call/presentation/providers/call_controller.dart';
import 'package:vibecall/features/call/presentation/providers/outgoing_ringtone.dart';
import 'package:vibecall/features/call/presentation/providers/call_state.dart';
import 'package:vibecall/features/chat/data/chat_repository.dart';
import 'package:vibecall/features/chat/presentation/providers/total_unread_chat_count.dart';
import 'package:vibecall/features/chat/presentation/providers/unread_counts_by_peer_user_id.dart';
import 'package:vibecall/features/chat/presentation/widgets/chat_unread_badge.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';
import 'package:vibecall/features/contacts/domain/contact_lists.dart';
import 'package:vibecall/features/contacts/presentation/providers/contact_tab_badges_controller.dart';
import 'package:vibecall/features/contacts/presentation/providers/contacts_controller.dart';
import 'package:vibecall/features/presence/presentation/providers/presence_controller.dart';
import 'package:vibecall/features/presence/presentation/widgets/online_indicator.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _markCurrentTabSeen());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _markCurrentTabSeen();
  }

  void _markCurrentTabSeen() {
    final contacts = ref.read(contactsControllerProvider).value;
    final currentUserId = ref.read(contactsRepositoryProvider).currentUserId;
    if (contacts == null) return;
    ref.read(contactTabBadgesControllerProvider.notifier).markTabSeen(
          ContactTabKind.fromIndex(_tabController.index),
          contacts,
          currentUserId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(contactsControllerProvider);
    final repo = ref.watch(contactsRepositoryProvider);
    final currentUserId = repo.currentUserId;
    final onlineUserIds = ref.watch(presenceControllerProvider);
    final unreadTotal = ref.watch(totalUnreadChatCountProvider);
    final tabBadges = ref.watch(contactTabBadgesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactsTitle),
        actions: [
          ChatUnreadBadge(
            count: unreadTotal,
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: l10n.chatsTitle,
              onPressed: () => context.push('/chats'),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            _ContactTab(label: l10n.contactsTab, count: tabBadges.acceptedUnseen),
            _ContactTab(label: l10n.incomingTab, count: tabBadges.incomingUnseen),
            _ContactTab(label: l10n.outgoingTab, count: tabBadges.outgoingUnseen),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: FilledButton.tonalIcon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
              label: Text(l10n.searchTitle),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                final partitioned = partitionContacts(contacts, currentUserId);

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _ContactList(
                        contacts: partitioned.accepted,
                        repo: repo,
                        onlineUserIds: onlineUserIds,
                        showRemove: true,
                        showCall: true,
                      ),
                      _ContactList(
                        contacts: partitioned.incoming,
                        repo: repo,
                        onlineUserIds: onlineUserIds,
                        showAccept: true,
                        showReject: true,
                      ),
                      _ContactList(
                        contacts: partitioned.outgoing,
                        repo: repo,
                        onlineUserIds: onlineUserIds,
                        showCancel: true,
                      ),
                    ],
                  );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTab extends StatelessWidget {
  final String label;
  final int count;

  const _ContactTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: count > 0 ? 10 : 0),
            child: Text(label),
          ),
          if (count > 0)
            Positioned(
              top: 0,
              child: ChatUnreadCountLabel(count: count),
            ),
        ],
      ),
    );
  }
}

class _ContactList extends ConsumerWidget {
  final List<ContactDto> contacts;
  final ContactsRepository repo;
  final Set<String> onlineUserIds;
  final bool showAccept;
  final bool showReject;
  final bool showRemove;
  final bool showCancel;
  final bool showCall;

  const _ContactList({
    required this.contacts,
    required this.repo,
    required this.onlineUserIds,
    this.showAccept = false,
    this.showReject = false,
    this.showRemove = false,
    this.showCancel = false,
    this.showCall = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadByPeer = ref.watch(unreadCountsByPeerUserIdProvider);

    if (contacts.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noContacts),
      );
    }
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final otherUserId = contact.userId == repo.currentUserId
            ? contact.contactId
            : contact.userId;
        final isOnline = onlineUserIds.contains(otherUserId);
        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              contact.avatarUrl != null
                  ? CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(contact.avatarUrl!),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
              Positioned(
                bottom: -2,
                right: -2,
                child: OnlineIndicator(isOnline: isOnline),
              ),
            ],
          ),
          title: Text(contact.displayName ?? contact.username ?? ''),
          subtitle:
              contact.displayName != null && contact.username != null
                  ? Text('@${contact.username}')
                  : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCall) ...[
                ChatUnreadBadge(
                  count: unreadByPeer[otherUserId] ?? 0,
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    tooltip:
                        AppLocalizations.of(context).chatStartConversation,
                    onPressed: () async {
                      final chatRepo = ref.read(chatRepositoryProvider);
                      final conversationId =
                          await chatRepo.ensureConversation(otherUserId);
                      if (context.mounted) {
                        context.push(
                          '/chat/$conversationId',
                          extra: {
                            'peerName':
                                contact.displayName ?? contact.username,
                            'peerAvatarUrl': contact.avatarUrl,
                          },
                        );
                      }
                    },
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final callState = ref.watch(callControllerProvider);
                    final canCall = callState is! CallStateConnecting &&
                        callState is! CallStateOutgoing &&
                        callState is! CallStateActive;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: canCall
                              ? () {
                                  unawaited(ref
                                      .read(outgoingRingtoneProvider.notifier)
                                      .unlockForNextRing());
                                  ref
                                      .read(callControllerProvider.notifier)
                                      .startCall(
                                        receiverId: otherUserId,
                                        video: false,
                                      );
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.videocam),
                          onPressed: canCall
                              ? () {
                                  unawaited(ref
                                      .read(outgoingRingtoneProvider.notifier)
                                      .unlockForNextRing());
                                  ref
                                      .read(callControllerProvider.notifier)
                                      .startCall(
                                        receiverId: otherUserId,
                                        video: true,
                                      );
                                }
                              : null,
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (showAccept)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    await repo.acceptRequest(contact.id, contact.userId);
                    ref.invalidate(contactsControllerProvider);
                  },
                ),
              if (showReject)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await repo.rejectRequest(contact.id);
                    ref.invalidate(contactsControllerProvider);
                  },
                ),
              if (showRemove)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    await repo.remove(contact.id, contact.contactId);
                    ref.invalidate(contactsControllerProvider);
                  },
                ),
              if (showCancel)
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () async {
                    await repo.rejectRequest(contact.id);
                    ref.invalidate(contactsControllerProvider);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
