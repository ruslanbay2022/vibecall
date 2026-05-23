import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';
import 'package:vibecall/features/contacts/presentation/providers/contacts_controller.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(contactsControllerProvider);
    final repo = ref.watch(contactsRepositoryProvider);
    final currentUserId = repo.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.contactsTab),
            Tab(text: l10n.incomingTab),
            Tab(text: l10n.outgoingTab),
          ],
        ),
      ),
      body: contactsAsync.when(
        data: (contacts) {
          final accepted =
              contacts.where((c) => c.status == 'accepted').toList();
          final incoming = contacts
              .where((c) =>
                  c.status == 'pending' && c.contactId == currentUserId)
              .toList();
          final outgoing = contacts
              .where((c) => c.status == 'pending' && c.userId == currentUserId)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _ContactList(
                contacts: accepted,
                repo: repo,
                showRemove: true,
              ),
              _ContactList(
                contacts: incoming,
                repo: repo,
                showAccept: true,
                showReject: true,
              ),
              _ContactList(
                contacts: outgoing,
                repo: repo,
                showCancel: true,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _ContactList extends ConsumerWidget {
  final List<ContactDto> contacts;
  final ContactsRepository repo;
  final bool showAccept;
  final bool showReject;
  final bool showRemove;
  final bool showCancel;

  const _ContactList({
    required this.contacts,
    required this.repo,
    this.showAccept = false,
    this.showReject = false,
    this.showRemove = false,
    this.showCancel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contacts.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).noContacts),
      );
    }
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          leading: contact.avatarUrl != null
              ? CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(contact.avatarUrl!),
                )
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Text(contact.displayName ?? contact.username ?? ''),
          subtitle:
              contact.displayName != null && contact.username != null
                  ? Text('@${contact.username}')
                  : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
