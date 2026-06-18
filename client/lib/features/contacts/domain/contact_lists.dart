import 'package:vibecall/features/contacts/data/contacts_repository.dart';

enum ContactTabKind {
  accepted,
  incoming,
  outgoing;

  static ContactTabKind fromIndex(int index) {
    return switch (index) {
      0 => ContactTabKind.accepted,
      1 => ContactTabKind.incoming,
      2 => ContactTabKind.outgoing,
      _ => ContactTabKind.accepted,
    };
  }
}

class PartitionedContacts {
  final List<ContactDto> accepted;
  final List<ContactDto> incoming;
  final List<ContactDto> outgoing;

  const PartitionedContacts({
    required this.accepted,
    required this.incoming,
    required this.outgoing,
  });
}

PartitionedContacts partitionContacts(
  List<ContactDto> contacts,
  String currentUserId,
) {
  final accepted =
      contacts.where((c) => c.status == 'accepted').toList(growable: false);
  final incoming = contacts
      .where(
        (c) => c.status == 'pending' && c.contactId == currentUserId,
      )
      .toList(growable: false);
  final outgoing = contacts
      .where(
        (c) => c.status == 'pending' && c.userId == currentUserId,
      )
      .toList(growable: false);
  return PartitionedContacts(
    accepted: accepted,
    incoming: incoming,
    outgoing: outgoing,
  );
}

int unseenContactCount(List<ContactDto> contacts, Set<String> seenIds) {
  return contacts.where((c) => !seenIds.contains(c.id)).length;
}

List<ContactDto> contactsForTab(
  PartitionedContacts partitioned,
  ContactTabKind tab,
) {
  return switch (tab) {
    ContactTabKind.accepted => partitioned.accepted,
    ContactTabKind.incoming => partitioned.incoming,
    ContactTabKind.outgoing => partitioned.outgoing,
  };
}
