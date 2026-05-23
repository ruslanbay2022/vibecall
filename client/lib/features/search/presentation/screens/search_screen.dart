import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';
import 'package:vibecall/features/contacts/presentation/providers/contacts_controller.dart';
import 'package:vibecall/features/search/data/search_repository.dart';
import 'package:vibecall/l10n/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<SearchUserDto> _results = [];
  bool _loading = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        _searchGeneration++;
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }
      if (query.length < 2) {
        _searchGeneration++;
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }
      _search(query);
    });
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    final generation = ++_searchGeneration;
    setState(() => _loading = true);
    try {
      final repo = ref.read(searchRepositoryProvider);
      final results = await repo.searchUsers(q);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  Future<void> _addUser(String userId) async {
    final l10n = AppLocalizations.of(context);
    try {
      final contactsRepo = ref.read(contactsRepositoryProvider);
      await contactsRepo.sendRequest(userId);
      ref.invalidate(contactsControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchRequestSent)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchAddError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(contactsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchGeneration++;
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _loading = false;
                              });
                            },
                          )
                        : null,
              ),
              autofocus: true,
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              data: (contacts) {
                final query = _searchController.text.trim();
                if (_results.isEmpty && !_loading) {
                  final message = query.length < 2
                      ? l10n.searchHint
                      : l10n.searchNoResults;
                  return Center(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results[index];
                    final relation = _getRelation(contacts, user.id);
                    final isSelf = user.id ==
                        ref.read(contactsRepositoryProvider).currentUserId;
                    if (isSelf) return const SizedBox.shrink();

                    return ListTile(
                      leading: user.avatarUrl != null
                          ? CircleAvatar(
                              backgroundImage:
                                  CachedNetworkImageProvider(user.avatarUrl!),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.displayName ?? user.username),
                      subtitle: user.displayName != null
                          ? Text('@${user.username}')
                          : null,
                      trailing: relation == _RelationStatus.none
                          ? TextButton(
                              onPressed: () => _addUser(user.id),
                              child: Text(l10n.searchAdd),
                            )
                          : TextButton(
                              onPressed: null,
                              child: Text(_relationLabel(relation, l10n)),
                            ),
                    );
                  },
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

  _RelationStatus _getRelation(
      List<ContactDto> contacts, String userId) {
    final currentUserId = ref.read(contactsRepositoryProvider).currentUserId;
    for (final c in contacts) {
      if (c.status == 'accepted') {
        if ((c.userId == currentUserId && c.contactId == userId) ||
            (c.userId == userId && c.contactId == currentUserId)) {
          return _RelationStatus.accepted;
        }
      } else if (c.status == 'pending') {
        if (c.userId == currentUserId && c.contactId == userId) {
          return _RelationStatus.outgoingPending;
        }
        if (c.userId == userId && c.contactId == currentUserId) {
          return _RelationStatus.incomingPending;
        }
      }
    }
    return _RelationStatus.none;
  }

  String _relationLabel(_RelationStatus status, AppLocalizations l10n) {
    switch (status) {
      case _RelationStatus.accepted:
        return l10n.searchInContacts;
      case _RelationStatus.outgoingPending:
        return l10n.searchPending;
      case _RelationStatus.incomingPending:
        return l10n.searchIncoming;
      case _RelationStatus.none:
        return l10n.searchAdd;
    }
  }
}

enum _RelationStatus { none, accepted, outgoingPending, incomingPending }
