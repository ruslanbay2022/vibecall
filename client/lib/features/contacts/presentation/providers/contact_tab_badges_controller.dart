import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibecall/features/auth/data/auth_repository.dart';
import 'package:vibecall/features/contacts/data/contacts_repository.dart';
import 'package:vibecall/features/contacts/domain/contact_lists.dart';
import 'package:vibecall/features/contacts/presentation/providers/contacts_controller.dart';

part 'contact_tab_badges_controller.g.dart';

class ContactTabBadgeState {
  final int acceptedUnseen;
  final int incomingUnseen;
  final int outgoingUnseen;

  const ContactTabBadgeState({
    this.acceptedUnseen = 0,
    this.incomingUnseen = 0,
    this.outgoingUnseen = 0,
  });

  int get totalUnseen =>
      acceptedUnseen + incomingUnseen + outgoingUnseen;
}

@Riverpod(keepAlive: true)
class ContactTabBadgesController extends _$ContactTabBadgesController {
  bool _acceptedBaselineApplied = false;
  Set<String> _seenAccepted = {};
  Set<String> _seenIncoming = {};
  Set<String> _seenOutgoing = {};

  @override
  ContactTabBadgeState build() {
    ref.listen(authRepositoryProvider, (previous, next) {
      final prevId = previous?.currentUser?.id;
      final nextId = next.currentUser?.id;
      if (nextId == null || prevId != nextId) {
        _resetInternal();
      }
    });

    final userId = ref.watch(authRepositoryProvider).currentUser?.id;
    if (userId == null) {
      return const ContactTabBadgeState();
    }

    ref.listen(
      contactsControllerProvider,
      (previous, next) {
        next.whenData((contacts) => syncFromContacts(contacts, userId));
      },
      fireImmediately: true,
    );

    return const ContactTabBadgeState();
  }

  void syncFromContacts(List<ContactDto> all, String currentUserId) {
    final partitioned = partitionContacts(all, currentUserId);
    if (!_acceptedBaselineApplied) {
      _seenAccepted = partitioned.accepted.map((c) => c.id).toSet();
      _acceptedBaselineApplied = true;
    }
    state = ContactTabBadgeState(
      acceptedUnseen:
          unseenContactCount(partitioned.accepted, _seenAccepted),
      incomingUnseen:
          unseenContactCount(partitioned.incoming, _seenIncoming),
      outgoingUnseen:
          unseenContactCount(partitioned.outgoing, _seenOutgoing),
    );
  }

  void markTabSeen(
    ContactTabKind tab,
    List<ContactDto> all,
    String currentUserId,
  ) {
    final partitioned = partitionContacts(all, currentUserId);
    final contacts = contactsForTab(partitioned, tab);
    final ids = contacts.map((c) => c.id);
    switch (tab) {
      case ContactTabKind.accepted:
        _seenAccepted.addAll(ids);
      case ContactTabKind.incoming:
        _seenIncoming.addAll(ids);
      case ContactTabKind.outgoing:
        _seenOutgoing.addAll(ids);
    }
    syncFromContacts(all, currentUserId);
  }

  void _resetInternal() {
    _acceptedBaselineApplied = false;
    _seenAccepted = {};
    _seenIncoming = {};
    _seenOutgoing = {};
    state = const ContactTabBadgeState();
  }
}
